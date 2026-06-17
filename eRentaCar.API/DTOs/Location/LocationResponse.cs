namespace eRentaCar.API.DTOs.Location
{
    public class LocationResponse
    {
        public int Id { get; set; }
        public string Name { get; set; } = null!;
        public string Address { get; set; } = null!;
        public string City { get; set; } = null!;
        public string Country { get; set; } = null!;
        public string? Phone { get; set; }
        public string? WorkingHours { get; set; }
        public bool IsActive { get; set; }
        public decimal? Latitude { get; set; }
        public decimal? Longitude { get; set; }
        public int AvailableVehicles { get; set; }
        public int RentedVehicles { get; set; }
    }
}