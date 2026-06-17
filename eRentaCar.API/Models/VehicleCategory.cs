namespace eRentaCar.API.Models
{
    public class VehicleCategory
    {
        public int Id { get; set; }
        public string Name { get; set; } = null!;
        public string? Description { get; set; }
        public bool IsActive { get; set; } = true;

        public ICollection<Vehicle> Vehicles { get; set; } = new List<Vehicle>();
    }
}