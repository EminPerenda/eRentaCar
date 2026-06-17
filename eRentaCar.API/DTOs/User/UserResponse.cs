namespace eRentaCar.API.DTOs.User
{
    public class UserResponse
    {
        public int Id { get; set; }
        public string FirstName { get; set; } = null!;
        public string LastName { get; set; } = null!;
        public string FullName => $"{FirstName} {LastName}";
        public string Email { get; set; } = null!;
        public string? PhoneNumber { get; set; }
        public string? City { get; set; }
        public string? DriverLicenseNo { get; set; }
        public string? ProfileImageUrl { get; set; }
        public bool IsActive { get; set; }
        public DateTime CreatedAt { get; set; }
        public string Role { get; set; } = null!;
        public int ReservationCount { get; set; }
        public decimal TotalSpent { get; set; }
        public int? CityId { get; set; }
    }
}