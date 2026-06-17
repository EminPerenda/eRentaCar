namespace eRentaCar.API.DTOs.Reservation
{
    public class ReservationFilterRequest
    {
        public string? Status { get; set; }
        public int? VehicleId { get; set; }
        public int? UserId { get; set; }
        public int? LocationId { get; set; }
        public string? ClientName { get; set; }
        public DateTime? From { get; set; }
        public DateTime? To { get; set; }
        public int Page { get; set; } = 1;
        public int PageSize { get; set; } = 10;
    }
}