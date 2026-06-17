namespace eRentaCar.API.DTOs.Vehicle
{
    public class VehicleRequest
    {
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
        public int CurrentLocationId { get; set; }
    }
}