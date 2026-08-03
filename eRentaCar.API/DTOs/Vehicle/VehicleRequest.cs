using System.ComponentModel.DataAnnotations;

namespace eRentaCar.API.DTOs.Vehicle
{
    public class VehicleRequest
    {
        [Required]
        [StringLength(15, MinimumLength = 1)]
        public string LicensePlate { get; set; } = null!;

        [Range(1, int.MaxValue)]
        public int BrandId { get; set; }

        [Required]
        [StringLength(80, MinimumLength = 1)]
        public string Model { get; set; } = null!;

        [Range(1900, 2100)]
        public int Year { get; set; }

        [Range(1, int.MaxValue)]
        public int CategoryId { get; set; }

        [Range(1, int.MaxValue)]
        public int FuelTypeId { get; set; }

        [Range(1, int.MaxValue)]
        public int TransmissionId { get; set; }

        [Range(1, int.MaxValue)]
        public int Seats { get; set; }

        [Range(typeof(decimal), "0.01", "79228162514264337593543950335")]
        public decimal PricePerDay { get; set; }

        [Range(0, int.MaxValue)]
        public int Mileage { get; set; }

        [StringLength(1000)]
        public string? Description { get; set; }

        [Range(1, int.MaxValue)]
        public int CurrentLocationId { get; set; }
    }
}