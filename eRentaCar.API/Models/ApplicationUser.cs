using Microsoft.AspNetCore.Identity;

namespace eRentaCar.API.Models
{
    public class ApplicationUser : IdentityUser<int>
    {
        public string FirstName { get; set; } = null!;
        public string LastName { get; set; } = null!;
        public DateTime? DateOfBirth { get; set; }
        public string? ProfileImageUrl { get; set; }
        public int? CityId { get; set; }
        public string? DriverLicenseNo { get; set; }
        public bool IsActive { get; set; } = true;
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public byte[] RowVersion { get; set; } = null!;

        public City? City { get; set; }
        public ICollection<Reservation> Reservations { get; set; } = new List<Reservation>();
        public ICollection<VehicleReview> Reviews { get; set; } = new List<VehicleReview>();
        public ICollection<Notification> Notifications { get; set; } = new List<Notification>();
        public ICollection<SearchHistory> SearchHistories { get; set; } = new List<SearchHistory>();
    }
}