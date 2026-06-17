namespace eRentaCar.API.DTOs.Reservation
{
    public class ReservationRequest
    {
        public int VehicleId { get; set; }
        public int PickupLocationId { get; set; }
        public int DropoffLocationId { get; set; }
        public DateTime StartDate { get; set; }
        public DateTime EndDate { get; set; }
        public List<ReservationExtraRequest> Extras { get; set; } = new();
    }

    public class ReservationExtraRequest
    {
        public int ExtraServiceId { get; set; }
        public int Quantity { get; set; } = 1;
    }
}