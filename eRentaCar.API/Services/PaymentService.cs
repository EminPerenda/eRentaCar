using eRentaCar.API.Data;
using eRentaCar.API.DTOs.Payment;
using eRentaCar.API.Enums;
using eRentaCar.API.Exceptions;
using eRentaCar.API.Models;
using eRentaCar.API.Services.Interfaces;
using Microsoft.EntityFrameworkCore;
using Stripe;

namespace eRentaCar.API.Services
{
    public class PaymentService : IPaymentService
    {
        private readonly ApplicationDbContext _context;
        private readonly INotificationService _notificationService;

        public PaymentService(ApplicationDbContext context, INotificationService notificationService)
        {
            _context = context;
            _notificationService = notificationService;
        }

        public async Task<PaymentIntentResponse> CreatePaymentIntentAsync(int reservationId, int userId)
        {
            var reservation = await _context.Reservations
                .FirstOrDefaultAsync(x => x.Id == reservationId && x.UserId == userId)
                ?? throw new NotFoundException("Rezervacija", reservationId);

            if (reservation.Status == ReservationStatus.Cancelled)
                throw new BusinessException("Rezervacija je otkazana.");

            var existingPayment = await _context.Payments
                .FirstOrDefaultAsync(x => x.ReservationId == reservationId
                    && x.Status == PaymentStatus.Completed);

            if (existingPayment != null)
                throw new BusinessException("Rezervacija je već plaćena.");

            var options = new PaymentIntentCreateOptions
            {
                Amount = (long)(reservation.TotalPrice * 100),
                Currency = "bam",
                Metadata = new Dictionary<string, string>
                {
                    { "reservationId", reservationId.ToString() },
                    { "userId", userId.ToString() }
                }
            };

            var service = new PaymentIntentService();
            var intent = await service.CreateAsync(options);

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

            // Idempotency: if this PaymentIntent was already recorded as completed, skip
            var existing = await _context.Payments
                .FirstOrDefaultAsync(x => x.PaymentIntentId == paymentIntentId
                    && x.Status == PaymentStatus.Completed);

            if (existing != null)
                return;

            var service = new PaymentIntentService();
            var intent = await service.GetAsync(paymentIntentId);

            if (intent.Status != "succeeded")
                throw new BusinessException("Plaćanje nije uspješno.");

            // Use the amount Stripe actually charged (in smallest currency unit / 100)
            var chargedAmount = intent.Amount / 100m;

            var payment = new Payment
            {
                ReservationId = reservationId,
                UserId = userId,
                Amount = chargedAmount,
                Status = PaymentStatus.Completed,
                PaymentIntentId = paymentIntentId,
                PaymentDate = DateTime.UtcNow
            };

            _context.Payments.Add(payment);
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
                Amount = (long)(refundAmount * 100),
            };

            var stripeRefund = await refundService.CreateAsync(refundOptions);

            if (stripeRefund.Status == "failed")
                throw new BusinessException($"Povrat nije uspio: {stripeRefund.FailureReason}");

            reservation.Payment.RefundId = stripeRefund.Id;
            reservation.Payment.RefundAmount = refundAmount;
            reservation.Payment.Status = PaymentStatus.Refunded;
            reservation.Status = ReservationStatus.Cancelled;
            await _context.SaveChangesAsync();

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
    }
}
