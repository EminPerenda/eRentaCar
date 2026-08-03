using System.ComponentModel.DataAnnotations;

namespace eRentaCar.API.DTOs.Auth
{
    public class RegisterRequest
    {
        [Required]
        [StringLength(50, MinimumLength = 1)]
        public string FirstName { get; set; } = null!;

        [Required]
        [StringLength(50, MinimumLength = 1)]
        public string LastName { get; set; } = null!;

        [Required]
        [EmailAddress]
        public string Email { get; set; } = null!;

        [Required]
        [MinLength(8)]
        public string Password { get; set; } = null!;

        [Phone]
        [StringLength(20)]
        public string? PhoneNumber { get; set; }

        [Range(1, int.MaxValue)]
        public int? CityId { get; set; }

        [StringLength(20)]
        public string? DriverLicenseNo { get; set; }
    }
}