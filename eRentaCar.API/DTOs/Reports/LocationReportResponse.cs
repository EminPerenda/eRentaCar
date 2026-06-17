namespace eRentaCar.API.DTOs.Reports
{
    public class LocationReportResponse
    {
        public List<LocationActivityItem> ByLocation { get; set; } = new();
        public int TotalReservations { get; set; }
        public decimal TotalRevenue { get; set; }
    }

    public class LocationActivityItem
    {
        public string Name { get; set; } = null!;
        public string City { get; set; } = null!;
        public int PickupCount { get; set; }
        public int DropoffCount { get; set; }
        public decimal Revenue { get; set; }
        public string TopVehicle { get; set; } = null!;
    }
}
