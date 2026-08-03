using System.ComponentModel.DataAnnotations;

namespace eRentaCar.API.DTOs.Reservation
{
    public class ReservationRequest
    {
        [Range(1, int.MaxValue)]
        public int VehicleId { get; set; }

        [Range(1, int.MaxValue)]
        public int PickupLocationId { get; set; }

        [Range(1, int.MaxValue)]
        public int DropoffLocationId { get; set; }

        [Required]
        public DateTime StartDate { get; set; }

        [Required]
        public DateTime EndDate { get; set; }

        [Required]
        public List<ReservationExtraRequest> Extras { get; set; } = new();
    }

    public class ReservationExtraRequest
    {
        [Range(1, int.MaxValue)]
        public int ExtraServiceId { get; set; }

        [Range(1, int.MaxValue)]
        public int Quantity { get; set; } = 1;
    }
}