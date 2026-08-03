using System.ComponentModel.DataAnnotations;

namespace eRentaCar.API.DTOs.Review
{
    public class ReviewRequest
    {
        [Range(1, int.MaxValue)]
        public int VehicleId { get; set; }

        [Range(1, int.MaxValue)]
        public int ReservationId { get; set; }

        [Range(1, 5)]
        public int Rating { get; set; }

        [StringLength(1000)]
        public string? Comment { get; set; }
    }
}