using eRentaCar.API.Data;
using eRentaCar.API.DTOs.Payment;
using eRentaCar.API.Enums;
using eRentaCar.API.Exceptions;
using eRentaCar.API.Models;
using eRentaCar.API.Services.Interfaces;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using Stripe;

namespace eRentaCar.API.Services
{
    public class PaymentService : IPaymentService
    {
        private const string StripeCurrencyCode = "bam";
        private static readonly HashSet<string> ZeroDecimalCurrencies = new(StringComparer.OrdinalIgnoreCase)
        {
            "bif", "clp", "djf", "gnf", "jpy", "kmf", "krw", "mga",
            "pyg", "rwf", "ugx", "vnd", "vuv", "xaf", "xcd", "xof", "xpf"
        };

        private readonly ApplicationDbContext _context;
        private readonly INotificationService _notificationService;
        private readonly ILogger<PaymentService> _logger;

        public PaymentService(ApplicationDbContext context, INotificationService notificationService, ILogger<PaymentService> logger)
        {
            _context = context;
            _notificationService = notificationService;
            _logger = logger;
        }

        public async Task<PaymentIntentResponse> CreatePaymentIntentAsync(int reservationId, int userId)
        {
            var reservation = await _context.Reservations
                .FirstOrDefaultAsync(x => x.Id == reservationId && x.UserId == userId)
                ?? throw new NotFoundException("Rezervacija", reservationId);

            if (reservation.Status == ReservationStatus.Cancelled)
                throw new BusinessException("Rezervacija je otkazana.");

            var payment = await _context.Payments
                .SingleOrDefaultAsync(x => x.ReservationId == reservationId);

            if (payment != null && payment.Status == PaymentStatus.Completed)
            {
                _logger.LogInformation("[PAYMENT_ACTIVE_CONFLICT] Reservation {ReservationId} already has a completed payment.", reservationId);
                throw new BusinessException("Rezervacija je već plaćena.");
            }

            if (payment != null && payment.Status == PaymentStatus.Pending)
            {
                var existingIntent = await TryGetStripePaymentIntentAsync(payment.PaymentIntentId);

                if (existingIntent != null && string.Equals(existingIntent.Status, "succeeded", StringComparison.OrdinalIgnoreCase))
                {
                    _logger.LogInformation("[PAYMENT_ACTIVE_CONFLICT] Reservation {ReservationId} already has a succeeded Stripe intent {PaymentIntentId}.", reservationId, payment.PaymentIntentId);
                    throw new BusinessException("Rezervacija je već plaćena.");
                }

                if (existingIntent != null && !string.Equals(existingIntent.Status, "canceled", StringComparison.OrdinalIgnoreCase))
                {
                    _logger.LogInformation("[PAYMENT_ACTIVE_CONFLICT] Reusing active pending payment intent {PaymentIntentId} for reservation {ReservationId}.", payment.PaymentIntentId, reservationId);
                    return new PaymentIntentResponse
                    {
                        ClientSecret = existingIntent.ClientSecret,
                        Amount = reservation.TotalPrice,
                        Currency = "BAM"
                    };
                }

                if (existingIntent == null || existingIntent.Status == "canceled")
                {
                    _logger.LogWarning("[PAYMENT_STALE_PENDING] Marking stale pending payment {PaymentIntentId} as failed for reservation {ReservationId}.", payment.PaymentIntentId, reservationId);
                    payment.Status = PaymentStatus.Failed;
                    payment.Description = "Stale pending payment intent expired or was canceled on Stripe.";
                    await _context.SaveChangesAsync();
                    payment = null;
                }
            }

            var expectedAmount = ToMinorUnits(reservation.TotalPrice, StripeCurrencyCode);
            var requestOptions = new RequestOptions();
            requestOptions.IdempotencyKey = payment == null
                ? $"payment-intent-reservation-{reservationId}"
                : $"payment-intent-reservation-{reservationId}-{payment.PaymentIntentId}";

            var options = new PaymentIntentCreateOptions
            {
                Amount = expectedAmount,
                Currency = StripeCurrencyCode,
                Metadata = new Dictionary<string, string>
                {
                    { "reservationId", reservationId.ToString() },
                    { "userId", userId.ToString() }
                }
            };

            var service = new PaymentIntentService();
            var intent = await service.CreateAsync(options, requestOptions);

            if (payment == null)
            {
                payment = new Payment
                {
                    ReservationId = reservationId,
                    UserId = userId,
                    PaymentIntentId = intent.Id,
                    Status = PaymentStatus.Pending,
                    PaymentDate = DateTime.UtcNow,
                    Amount = reservation.TotalPrice
                };

                _context.Payments.Add(payment);
            }
            else
            {
                payment.UserId = userId;
                payment.PaymentIntentId = intent.Id;
                payment.Status = PaymentStatus.Pending;
                payment.Amount = reservation.TotalPrice;
                payment.PaymentDate = DateTime.UtcNow;
                payment.RefundId = null;
                payment.RefundAmount = null;
                payment.ChargeId = null;
                payment.Description = null;
            }

            await _context.SaveChangesAsync();

            return new PaymentIntentResponse
            {
                ClientSecret = intent.ClientSecret,
                Amount = reservation.TotalPrice,
                Currency = "BAM"
            };
        }

        public async Task ConfirmPaymentAsync(int reservationId, int userId, string paymentIntentId)
        {
            var reservation = await _context.Reservations
                .FirstOrDefaultAsync(x => x.Id == reservationId && x.UserId == userId)
                ?? throw new NotFoundException("Rezervacija", reservationId);

            if (reservation.Status == ReservationStatus.Cancelled || reservation.Status == ReservationStatus.Completed)
                throw new BusinessException("Rezervacija više nije podobna za plaćanje.", "RESERVATION_NOT_PAYABLE");

            var payment = await _context.Payments
                .SingleOrDefaultAsync(x => x.ReservationId == reservationId)
                ?? throw new NotFoundException("Plaćanje", reservationId);

            if (!string.Equals(payment.PaymentIntentId, paymentIntentId, StringComparison.Ordinal))
            {
                _logger.LogWarning("[PAYMENT_SECURITY_MISMATCH] PaymentIntent {PaymentIntentId} does not match reservation {ReservationId} for user {UserId}.", paymentIntentId, reservationId, userId);
                throw new BusinessException("PaymentIntent ne odgovara rezervaciji.", "PAYMENT_INTENT_MISMATCH");
            }

            if (payment.Status == PaymentStatus.Completed)
                return;

            var service = new PaymentIntentService();
            var intent = await service.GetAsync(paymentIntentId);

            if (intent.Status != "succeeded")
            {
                if (intent.Status == "canceled")
                {
                    payment.Status = PaymentStatus.Failed;
                    payment.Description = "PaymentIntent canceled on Stripe before confirmation.";
                    await _context.SaveChangesAsync();
                }

                throw new BusinessException("Plaćanje nije uspješno.");
            }

            ValidateIntentMatchesReservation(intent, reservation, userId);

            // Use the amount Stripe actually charged, converted from minor units.
            var chargedAmount = ToMajorUnits(intent.Amount, intent.Currency);

            payment.Amount = chargedAmount;
            payment.Status = PaymentStatus.Completed;
            payment.UserId = userId;
            payment.PaymentIntentId = paymentIntentId;
            payment.PaymentDate = DateTime.UtcNow;

            reservation.Payment = payment;
            reservation.Status = ReservationStatus.Confirmed;
            await _context.SaveChangesAsync();

            await _notificationService.SendToUserAsync(
                userId,
                "Plaćanje potvrđeno",
                $"Vaše plaćanje od {chargedAmount:F2} BAM za rezervaciju #{reservationId} je uspješno obrađeno.",
                Enums.NotificationType.Payment);
        }

        public async Task<RefundResponse> RefundAsync(int reservationId, int userId)
        {
            var reservation = await _context.Reservations
                .Include(x => x.Payment)
                .FirstOrDefaultAsync(x => x.Id == reservationId && x.UserId == userId)
                ?? throw new NotFoundException("Rezervacija", reservationId);

            if (reservation.Payment == null || reservation.Payment.Status != PaymentStatus.Completed)
                throw new BusinessException("Rezervacija nije plaćena.");

            if (reservation.Payment.RefundAmount.HasValue)
                throw new BusinessException("Povrat je već izvršen.");

            var hoursUntilPickup = (reservation.StartDate.ToUniversalTime() - DateTime.UtcNow).TotalHours;

            decimal refundPercent;
            string refundMessage;
            if (hoursUntilPickup >= 48)
            {
                refundPercent = 1.0m;
                refundMessage = "Povrat 100% je uspješno izvršen.";
            }
            else if (hoursUntilPickup >= 24)
            {
                refundPercent = 0.5m;
                refundMessage = "Povrat 50% je uspješno izvršen (otkazivanje između 24-48h).";
            }
            else
            {
                throw new BusinessException("Povrat nije moguć manje od 24 sata prije preuzimanja.");
            }

            // Refund based on actually charged amount, not the reservation's calculated price
            var refundAmount = Math.Round(reservation.Payment.Amount * refundPercent, 2);

            var refundService = new RefundService();
            var refundOptions = new RefundCreateOptions
            {
                PaymentIntent = reservation.Payment.PaymentIntentId,
                Amount = ToMinorUnits(refundAmount, StripeCurrencyCode),
            };

            var stripeRefund = await refundService.CreateAsync(refundOptions);

            if (stripeRefund.Status == "failed")
                throw new BusinessException($"Povrat nije uspio: {stripeRefund.FailureReason}");

            await using var transaction = await _context.Database.BeginTransactionAsync();
            reservation.Payment.RefundId = stripeRefund.Id;
            reservation.Payment.RefundAmount = refundAmount;
            reservation.Payment.Status = PaymentStatus.Refunded;
            reservation.Status = ReservationStatus.Cancelled;
            await _context.SaveChangesAsync();
            await transaction.CommitAsync();

            await _notificationService.SendToUserAsync(
                userId,
                "Povrat plaćanja",
                $"Povrat od {refundAmount:F2} BAM za rezervaciju #{reservationId} je uspješno obrađen.",
                Enums.NotificationType.Payment);

            return new RefundResponse
            {
                Message = refundMessage,
                RefundAmount = refundAmount
            };
        }

        private static void ValidateIntentMatchesReservation(PaymentIntent intent, Reservation reservation, int currentUserId)
        {
            if (!intent.Metadata.TryGetValue("reservationId", out var intentReservationIdValue)
                || !int.TryParse(intentReservationIdValue, out var intentReservationId)
                || intentReservationId != reservation.Id)
            {
                throw new BusinessException("PaymentIntent ne odgovara rezervaciji.", "PAYMENT_INTENT_MISMATCH");
            }

            if (!intent.Metadata.TryGetValue("userId", out var intentUserIdValue)
                || !int.TryParse(intentUserIdValue, out var intentUserId)
                || intentUserId != currentUserId)
            {
                throw new BusinessException("PaymentIntent ne odgovara rezervaciji.", "PAYMENT_INTENT_MISMATCH");
            }

            var expectedAmount = ToMinorUnits(reservation.TotalPrice, intent.Currency);
            if (intent.Amount != expectedAmount)
            {
                throw new BusinessException("PaymentIntent ne odgovara rezervaciji.", "PAYMENT_INTENT_MISMATCH");
            }

            if (!string.Equals(intent.Currency, StripeCurrencyCode, StringComparison.OrdinalIgnoreCase))
            {
                throw new BusinessException("PaymentIntent ne odgovara rezervaciji.", "PAYMENT_INTENT_MISMATCH");
            }

            if (reservation.UserId != currentUserId)
            {
                throw new BusinessException("PaymentIntent ne odgovara rezervaciji.", "PAYMENT_INTENT_MISMATCH");
            }
        }

        private static long ToMinorUnits(decimal amount, string currencyCode)
        {
            var multiplier = ZeroDecimalCurrencies.Contains(currencyCode) ? 1m : 100m;
            return (long)Math.Round(amount * multiplier, MidpointRounding.AwayFromZero);
        }

        private static bool IsTerminalStripeStatus(string? status)
        {
            return string.Equals(status, "canceled", StringComparison.OrdinalIgnoreCase);
        }

        private static async Task<PaymentIntent?> TryGetStripePaymentIntentAsync(string paymentIntentId)
        {
            try
            {
                var service = new PaymentIntentService();
                return await service.GetAsync(paymentIntentId);
            }
            catch (StripeException)
            {
                return null;
            }
        }

        private static decimal ToMajorUnits(long minorUnits, string currencyCode)
        {
            var divisor = ZeroDecimalCurrencies.Contains(currencyCode) ? 1m : 100m;
            return minorUnits / divisor;
        }
    }
}
