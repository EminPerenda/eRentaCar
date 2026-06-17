namespace eRentaCar.API.DTOs.User
{
    public class UpdateProfileRequest
    {
        public string FirstName { get; set; } = null!;
        public string LastName { get; set; } = null!;
        public string? PhoneNumber { get; set; }
        public int? CityId { get; set; }
        public string? DriverLicenseNo { get; set; }
        public string? ProfileImageUrl { get; set; }
    }
}