using eRentaCar.API.Enums;

namespace eRentaCar.API.Models
{
    public class Reservation
    {
        public int Id { get; set; }
        public int UserId { get; set; }
        public int VehicleId { get; set; }
        public int PickupLocationId { get; set; }
        public int DropoffLocationId { get; set; }
        public DateTime StartDate { get; set; }
        public DateTime EndDate { get; set; }
        public int TotalDays { get; set; }
        public decimal BasePrice { get; set; }
        public decimal ExtrasPrice { get; set; } = 0;
        public decimal TotalPrice { get; set; }
        public ReservationStatus Status { get; set; } = ReservationStatus.Pending;
        public int? PaymentId { get; set; }
        public string? CancellationReason { get; set; }
        public int? CancelledById { get; set; }
        public DateTime? CancelledAt { get; set; }
        public int? ApprovedById { get; set; }
        public DateTime? ApprovedAt { get; set; }
        public int? CompletedById { get; set; }
        public DateTime? CompletedAt { get; set; }
        public int? ActivatedById { get; set; }
        public DateTime? ActivatedAt { get; set; }
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public byte[] RowVersion { get; set; } = null!;

        public ApplicationUser User { get; set; } = null!;
        public Vehicle Vehicle { get; set; } = null!;
        public Location PickupLocation { get; set; } = null!;
        public Location DropoffLocation { get; set; } = null!;
        public Payment? Payment { get; set; }
        public ApplicationUser? ApprovedBy { get; set; }
        public ApplicationUser? CancelledBy { get; set; }
        public ApplicationUser? CompletedBy { get; set; }
        public ApplicationUser? ActivatedBy { get; set; }
        public ICollection<ReservationExtra> Extras { get; set; } = new List<ReservationExtra>();
        public VehicleReview? Review { get; set; }
    }
}