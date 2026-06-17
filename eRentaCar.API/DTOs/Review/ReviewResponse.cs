namespace eRentaCar.API.DTOs.Review
{
    public class ReviewResponse
    {
        public int Id { get; set; }
        public string ClientName { get; set; } = null!;
        public int VehicleId { get; set; }
        public string Vehicle { get; set; } = null!;
        public int ReservationId { get; set; }
        public int Rating { get; set; }
        public string? Comment { get; set; }
        public DateTime CreatedAt { get; set; }
    }
}