namespace eRentaCar.API.DTOs.Location
{
    public class LocationRequest
    {
        public string Name { get; set; } = null!;
        public string Address { get; set; } = null!;
        public int CityId { get; set; }
        public string? Phone { get; set; }
        public string? WorkingHours { get; set; }
        public decimal? Latitude { get; set; }
        public decimal? Longitude { get; set; }
    }
}