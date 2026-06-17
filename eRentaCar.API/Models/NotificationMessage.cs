namespace eRentaCar.API.Models
{
    public class NotificationMessage
    {
        public int UserId { get; set; }
        public string Title { get; set; } = null!;
        public string Message { get; set; } = null!;
        public string Type { get; set; } = null!;
        public string? Email { get; set; }
    }
}