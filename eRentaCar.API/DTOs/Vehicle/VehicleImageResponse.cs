namespace eRentaCar.API.DTOs.Vehicle
{
    public class VehicleImageResponse
    {
        public int Id { get; set; }
        public int VehicleId { get; set; }
        public string ImageUrl { get; set; } = null!;
        public bool IsPrimary { get; set; }
        public DateTime UploadedAt { get; set; }
    }
}
