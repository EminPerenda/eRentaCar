namespace eRentaCar.API.Models
{
    public class VehicleReview
    {
        public int Id { get; set; }
        public int UserId { get; set; }
        public int VehicleId { get; set; }
        public int ReservationId { get; set; }
        public int Rating { get; set; }
        public string? Comment { get; set; }
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        public ApplicationUser User { get; set; } = null!;
        public Vehicle Vehicle { get; set; } = null!;
        public Reservation Reservation { get; set; } = null!;
    }
}