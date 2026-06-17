namespace eRentaCar.API.Models
{
    public class PasswordResetToken
    {
        public int Id { get; set; }
        public int UserId { get; set; }
        public string Token { get; set; } = null!;
        public DateTime ExpiresAt { get; set; }
        public bool IsUsed { get; set; }
        public ApplicationUser User { get; set; } = null!;
    }
}