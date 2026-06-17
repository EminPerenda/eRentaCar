namespace eRentaCar.API.DTOs.Auth
{
    public class RegisterRequest
    {
        public string FirstName { get; set; } = null!;
        public string LastName { get; set; } = null!;
        public string Email { get; set; } = null!;
        public string Password { get; set; } = null!;
        public string? PhoneNumber { get; set; }
        public int? CityId { get; set; }
        public string? DriverLicenseNo { get; set; }
    }
}