namespace eRentaCar.API.DTOs.Review
{
    public class ReviewRequest
    {
        public int VehicleId { get; set; }
        public int ReservationId { get; set; }
        public int Rating { get; set; }
        public string? Comment { get; set; }
    }
}