using eRentaCar.API.Enums;

namespace eRentaCar.API.Models
{
    public class SearchHistory
    {
        public int Id { get; set; }
        public int UserId { get; set; }
        public int? VehicleId { get; set; }
        public int? CategoryId { get; set; }
        public SearchActionType ActionType { get; set; }
        public DateTime SearchedAt { get; set; } = DateTime.UtcNow;

        public ApplicationUser User { get; set; } = null!;
        public Vehicle? Vehicle { get; set; }
        public VehicleCategory? Category { get; set; }
    }
}