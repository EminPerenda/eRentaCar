namespace eRentaCar.API.DTOs.Reports
{
    public class FinancialReportResponse
    {
        public decimal TotalRevenue { get; set; }
        public int TransactionCount { get; set; }
        public List<LocationRevenueItem> ByLocation { get; set; } = new();
        public List<TransactionItem> Transactions { get; set; } = new();
    }

    public class LocationRevenueItem
    {
        public string Name { get; set; } = null!;
        public decimal Revenue { get; set; }
        public int Count { get; set; }
    }

    public class TransactionItem
    {
        public int Id { get; set; }
        public string ClientName { get; set; } = null!;
        public string Vehicle { get; set; } = null!;
        public string PickupLocation { get; set; } = null!;
        public DateTime StartDate { get; set; }
        public DateTime EndDate { get; set; }
        public int TotalDays { get; set; }
        public decimal BasePrice { get; set; }
        public decimal ExtrasPrice { get; set; }
        public decimal TotalPrice { get; set; }
    }
}
