namespace eRentaCar.API.Models
{
    public class VehicleBrand
    {
        public int Id { get; set; }
        public string Name { get; set; } = null!;

        public ICollection<Vehicle> Vehicles { get; set; } = new List<Vehicle>();
    }
}