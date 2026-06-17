namespace eRentaCar.API.DTOs.Vehicle
{
    public class VehicleFilterRequest
    {
        public string? Search { get; set; }
        public int? CategoryId { get; set; }
        public int? BrandId { get; set; }
        public int? FuelTypeId { get; set; }
        public int? TransmissionId { get; set; }
        public int? Seats { get; set; }
        public decimal? MinPrice { get; set; }
        public decimal? MaxPrice { get; set; }
        public int? LocationId { get; set; }
        public DateTime? StartDate { get; set; }
        public DateTime? EndDate { get; set; }
        public string? SortBy { get; set; }
        public int Page { get; set; } = 1;
        public int PageSize { get; set; } = 10;
        public int? CityId { get; set; }
    }
}