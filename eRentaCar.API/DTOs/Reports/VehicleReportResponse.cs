namespace eRentaCar.API.DTOs.Reports
{
    public class VehicleReportResponse
    {
        public int PeriodDays { get; set; }
        public List<VehicleUtilizationItem> ByVehicle { get; set; } = new();
        public List<CategoryRevenueItem> ByCategory { get; set; } = new();
    }

    public class VehicleUtilizationItem
    {
        public int Id { get; set; }
        public string Vehicle { get; set; } = null!;
        public string Category { get; set; } = null!;
        public string LicensePlate { get; set; } = null!;
        public int DaysRented { get; set; }
        public double UtilizationPct { get; set; }
        public decimal Revenue { get; set; }
        public int ReservationCount { get; set; }
    }

    public class CategoryRevenueItem
    {
        public string Name { get; set; } = null!;
        public int VehicleCount { get; set; }
        public int ReservationCount { get; set; }
        public decimal Revenue { get; set; }
        public double AvgDays { get; set; }
    }
}
