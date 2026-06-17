namespace eRentaCar.API.DTOs.Notification
{
    public class CreateNotificationRequest
    {
        public int? UserId { get; set; }
        public string Title { get; set; } = null!;
        public string Message { get; set; } = null!;
    }
}