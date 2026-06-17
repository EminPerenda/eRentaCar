using eRentaCar.API.Enums;

namespace eRentaCar.API.Models
{
    public class Vehicle
    {
        public int Id { get; set; }
        public string LicensePlate { get; set; } = null!;
        public int BrandId { get; set; }
        public string Model { get; set; } = null!;
        public int Year { get; set; }
        public int CategoryId { get; set; }
        public int FuelTypeId { get; set; }
        public int TransmissionId { get; set; }
        public int Seats { get; set; }
        public decimal PricePerDay { get; set; }
        public int Mileage { get; set; }
        public string? Description { get; set; }
        public bool IsActive { get; set; } = true;
        public VehicleStatus Status { get; set; } = VehicleStatus.Available;
        public int CurrentLocationId { get; set; }
        public byte[] RowVersion { get; set; } = null!;

        public VehicleBrand Brand { get; set; } = null!;
        public VehicleCategory Category { get; set; } = null!;
        public FuelType FuelType { get; set; } = null!;
        public Transmission Transmission { get; set; } = null!;
        public Location CurrentLocation { get; set; } = null!;
        public ICollection<VehicleImage> Images { get; set; } = new List<VehicleImage>();
        public ICollection<Reservation> Reservations { get; set; } = new List<Reservation>();
        public ICollection<VehicleReview> Reviews { get; set; } = new List<VehicleReview>();
        public ICollection<SearchHistory> SearchHistories { get; set; } = new List<SearchHistory>();
    }
}