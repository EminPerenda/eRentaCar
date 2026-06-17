using eRentaCar.API.Enums;
namespace eRentaCar.API.Models
{
    public class Payment
    {
        public int Id { get; set; }
        public int UserId { get; set; }
        public int? ReservationId { get; set; }
        public decimal Amount { get; set; }
        public DateTime PaymentDate { get; set; } = DateTime.UtcNow;
        public string PaymentIntentId { get; set; } = null!;
        public string? ChargeId { get; set; }
        public PaymentStatus Status { get; set; } = PaymentStatus.Pending;
        public string? RefundId { get; set; }
        public decimal? RefundAmount { get; set; }
        public string? Description { get; set; }
        public ApplicationUser User { get; set; } = null!;
        public Reservation? Reservation { get; set; }
    }
}