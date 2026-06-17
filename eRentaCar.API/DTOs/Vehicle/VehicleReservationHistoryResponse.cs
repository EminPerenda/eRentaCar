namespace eRentaCar.API.DTOs.Vehicle
{
    public class VehicleReservationHistoryResponse
    {
        public int Id { get; set; }
        public string ClientName { get; set; } = null!;
        public string ClientEmail { get; set; } = null!;
        public DateTime StartDate { get; set; }
        public DateTime EndDate { get; set; }
        public string Status { get; set; } = null!;
        public decimal TotalPrice { get; set; }
        public string? CancellationReason { get; set; }
        public DateTime CreatedAt { get; set; }
    }
}
