namespace eRentaCar.API.Models
{
    public class Location
    {
        public int Id { get; set; }
        public string Name { get; set; } = null!;
        public string Address { get; set; } = null!;
        public int CityId { get; set; }
        public string? Phone { get; set; }
        public string? WorkingHours { get; set; }
        public bool IsActive { get; set; } = true;
        public decimal? Latitude { get; set; }
        public decimal? Longitude { get; set; }
        public byte[] RowVersion { get; set; } = null!;

        public City City { get; set; } = null!;
        public ICollection<Vehicle> Vehicles { get; set; } = new List<Vehicle>();
    }
}