namespace eRentaCar.API.DTOs.Notification
{
    public class NotificationResponse
    {
        public int Id { get; set; }
        public string Title { get; set; } = null!;
        public string Message { get; set; } = null!;
        public bool IsRead { get; set; }
        public DateTime? ReadAt { get; set; }
        public string Type { get; set; } = null!;
        public DateTime CreatedAt { get; set; }
    }
}