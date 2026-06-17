namespace eRentaCar.API.DTOs.Recommendation
{
    public class RecommendationResponse
    {
        public int Id { get; set; }
        public string Vehicle { get; set; } = null!;
        public string Name { get; set; } = null!;
        public decimal PricePerDay { get; set; }
        public double AverageRating { get; set; }
        public string? PrimaryImageUrl { get; set; }
        public string Reason { get; set; } = null!;
        public string Type { get; set; } = null!;
    }
}
