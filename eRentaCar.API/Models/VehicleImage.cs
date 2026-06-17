namespace eRentaCar.API.Models
{
    public class VehicleImage
    {
        public int Id { get; set; }
        public int VehicleId { get; set; }
        public string ImageUrl { get; set; } = null!;
        public bool IsPrimary { get; set; } = false;
        public DateTime UploadedAt { get; set; } = DateTime.UtcNow;

        public Vehicle Vehicle { get; set; } = null!;
    }
}