namespace eRentaCar.API.DTOs.Vehicle
{
    public class VehicleResponse
    {
        public int Id { get; set; }
        public string LicensePlate { get; set; } = null!;
        public string Brand { get; set; } = null!;
        public string Model { get; set; } = null!;
        public int Year { get; set; }
        public string Category { get; set; } = null!;
        public string FuelType { get; set; } = null!;
        public string Transmission { get; set; } = null!;
        public int Seats { get; set; }
        public decimal PricePerDay { get; set; }
        public int Mileage { get; set; }
        public string? Description { get; set; }
        public string Status { get; set; } = null!;
        public string CurrentLocation { get; set; } = null!;
        public double AverageRating { get; set; }
        public int ReviewCount { get; set; }
        public string? PrimaryImageUrl { get; set; }

        public int CategoryId { get; set; }
    }
}