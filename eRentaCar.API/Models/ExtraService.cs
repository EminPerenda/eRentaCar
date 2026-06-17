namespace eRentaCar.API.Models
{
    public class ExtraService
    {
        public int Id { get; set; }
        public string Name { get; set; } = null!;
        public string? Description { get; set; }
        public decimal PricePerDay { get; set; }
        public bool IsAvailable { get; set; } = true;
        public byte[] RowVersion { get; set; } = null!;

        public ICollection<ReservationExtra> ReservationExtras { get; set; } = new List<ReservationExtra>();
    }
}   