using eRentaCar.API.DTOs.Payment;

namespace eRentaCar.API.Services.Interfaces
{
    public interface IPaymentService
    {
        Task<PaymentIntentResponse> CreatePaymentIntentAsync(int reservationId, int userId);
        Task ConfirmPaymentAsync(int reservationId, int userId, string paymentIntentId);
        Task<RefundResponse> RefundAsync(int reservationId, int userId);
    }
}
