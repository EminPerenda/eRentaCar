using eRentaCar.API.Exceptions;
using eRentaCar.API.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Stripe;
using System.Security.Claims;

namespace eRentaCar.API.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    public class PaymentsController : ControllerBase
    {
        private readonly IPaymentService _service;

        public PaymentsController(IPaymentService service)
        {
            _service = service;
        }

        [HttpPost("create-payment-intent/{reservationId}")]
        public async Task<IActionResult> CreatePaymentIntent(int reservationId)
        {
            var userId = GetUserId();
            var result = await _service.CreatePaymentIntentAsync(reservationId, userId);
            return Ok(result);
        }

        [HttpPost("confirm/{reservationId}")]
        public async Task<IActionResult> ConfirmPayment(int reservationId, [FromBody] ConfirmPaymentRequest request)
        {
            var userId = GetUserId();
            await _service.ConfirmPaymentAsync(reservationId, userId, request.PaymentIntentId);
            return Ok(new { message = "Plaćanje je uspješno potvrđeno." });
        }

        [HttpPost("refund/{reservationId}")]
        public async Task<IActionResult> Refund(int reservationId)
        {
            var userId = GetUserId();
            var result = await _service.RefundAsync(reservationId, userId);
            return Ok(result);
        }

        [HttpPost("webhook")]
        [AllowAnonymous]
        public async Task<IActionResult> Webhook()
        {
            var webhookSecret = Environment.GetEnvironmentVariable("STRIPE_WEBHOOK_SECRET")
                ?? Environment.GetEnvironmentVariable("Stripe__WebhookSecret");

            if (string.IsNullOrWhiteSpace(webhookSecret))
                return BadRequest("Webhook secret nije konfigurisan.");

            string json;
            using (var reader = new StreamReader(HttpContext.Request.Body))
                json = await reader.ReadToEndAsync();

            Event stripeEvent;
            try
            {
                stripeEvent = EventUtility.ConstructEvent(
                    json,
                    Request.Headers["Stripe-Signature"],
                    webhookSecret);
            }
            catch (StripeException)
            {
                return BadRequest("Neispravan webhook potpis.");
            }

            if (stripeEvent.Type == "payment_intent.succeeded"
                && stripeEvent.Data.Object is PaymentIntent intent)
            {
                if (intent.Metadata.TryGetValue("reservationId", out var reservationIdStr)
                    && intent.Metadata.TryGetValue("userId", out var userIdStr)
                    && int.TryParse(reservationIdStr, out var reservationId)
                    && int.TryParse(userIdStr, out var userId))
                {
                    await _service.ConfirmPaymentAsync(reservationId, userId, intent.Id);
                }
            }

            return Ok();
        }

        private int GetUserId()
        {
            var claim = User.FindFirstValue(ClaimTypes.NameIdentifier)
                ?? throw new UnauthorizedException();
            return int.Parse(claim);
        }
    }

    public class ConfirmPaymentRequest
    {
        public string PaymentIntentId { get; set; } = null!;
    }
}
