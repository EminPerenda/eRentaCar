namespace eRentaCar.API.Models
{
    public class PasswordResetToken
    {
        public int Id { get; set; }
        public int UserId { get; set; }
        public string Token { get; set; } = null!;
        public string TokenSalt { get; set; } = null!;
        public DateTime ExpiresAt { get; set; }
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public DateTime? UsedAt { get; set; }
        public bool IsUsed { get; set; }
        public int AttemptCount { get; set; }
        public ApplicationUser User { get; set; } = null!;
    }
}