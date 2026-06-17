namespace eRentaCar.API.DTOs.Reports
{
    public class ClientReportResponse
    {
        public int TotalClients { get; set; }
        public decimal TotalRevenue { get; set; }
        public List<ClientActivityItem> ByClient { get; set; } = new();
    }

    public class ClientActivityItem
    {
        public string Name { get; set; } = null!;
        public string Email { get; set; } = null!;
        public int ReservationCount { get; set; }
        public decimal TotalSpent { get; set; }
        public string TopCategory { get; set; } = null!;
    }
}
