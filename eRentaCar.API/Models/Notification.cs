using eRentaCar.API.Enums;

namespace eRentaCar.API.Models
{
    public class Notification
    {
        public int Id { get; set; }
        public int UserId { get; set; }
        public string Title { get; set; } = null!;
        public string Message { get; set; } = null!;
        public bool IsRead { get; set; } = false;
        public DateTime? ReadAt { get; set; }
        public NotificationType Type { get; set; }
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        public ApplicationUser User { get; set; } = null!;
    }
}