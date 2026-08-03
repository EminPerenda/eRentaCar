using System.ComponentModel.DataAnnotations;

namespace eRentaCar.API.DTOs.Location
{
    public class LocationRequest
    {
        [Required]
        [StringLength(100, MinimumLength = 1)]
        public string Name { get; set; } = null!;

        [Required]
        [StringLength(200, MinimumLength = 1)]
        public string Address { get; set; } = null!;

        [Range(1, int.MaxValue)]
        public int CityId { get; set; }

        [Phone]
        [StringLength(20)]
        public string? Phone { get; set; }

        [StringLength(80)]
        public string? WorkingHours { get; set; }

        [Range(-90, 90)]
        public decimal? Latitude { get; set; }

        [Range(-180, 180)]
        public decimal? Longitude { get; set; }
    }
}