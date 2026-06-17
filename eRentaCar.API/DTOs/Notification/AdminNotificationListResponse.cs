namespace eRentaCar.API.DTOs.Notification
{
    public class AdminNotificationResponse
    {
        public int Id { get; set; }
        public string Title { get; set; } = null!;
        public string Message { get; set; } = null!;
        public bool IsRead { get; set; }
        public DateTime CreatedAt { get; set; }
        public string UserName { get; set; } = null!;
        public string? UserEmail { get; set; }
    }

    public class AdminNotificationListResponse
    {
        public List<AdminNotificationResponse> Items { get; set; } = new();
        public int TotalCount { get; set; }
        public int Page { get; set; }
        public int PageSize { get; set; }
    }
}
