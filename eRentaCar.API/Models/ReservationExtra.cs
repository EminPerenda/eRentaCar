namespace eRentaCar.API.Models
{
    public class ReservationExtra
    {
        public int Id { get; set; }
        public int ReservationId { get; set; }
        public int ExtraServiceId { get; set; }
        public int Quantity { get; set; } = 1;
        public decimal PriceAtTime { get; set; }

        public Reservation Reservation { get; set; } = null!;
        public ExtraService ExtraService { get; set; } = null!;
    }
}