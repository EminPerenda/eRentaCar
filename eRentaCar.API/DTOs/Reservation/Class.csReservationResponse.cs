namespace eRentaCar.API.DTOs.Reservation
{
    public class ReservationResponse
    {
        public int Id { get; set; }
        public int VehicleId { get; set; }
        public string ClientName { get; set; } = null!;
        public string ClientEmail { get; set; } = null!;
        public string Vehicle { get; set; } = null!;
        public string LicensePlate { get; set; } = null!;
        public string PickupLocation { get; set; } = null!;
        public string DropoffLocation { get; set; } = null!;
        public DateTime StartDate { get; set; }
        public DateTime EndDate { get; set; }
        public int TotalDays { get; set; }
        public decimal BasePrice { get; set; }
        public decimal ExtrasPrice { get; set; }
        public decimal TotalPrice { get; set; }
        public string Status { get; set; } = null!;
        public string? CancellationReason { get; set; }
        public string? CancelledBy { get; set; }
        public DateTime? CancelledAt { get; set; }
        public string? ApprovedBy { get; set; }
        public DateTime? ApprovedAt { get; set; }
        public string? CompletedBy { get; set; }
        public DateTime? CompletedAt { get; set; }
        public DateTime CreatedAt { get; set; }
        public bool IsPaid { get; set; }
        public string? VehiclePrimaryImageUrl { get; set; }
        public string? ActivatedBy { get; set; }
        public DateTime? ActivatedAt { get; set; }
        public List<ReservationExtraResponse> Extras { get; set; } = new();
    }

    public class ReservationExtraResponse
    {
        public string ServiceName { get; set; } = null!;
        public int Quantity { get; set; }
        public decimal PriceAtTime { get; set; }
    }
}