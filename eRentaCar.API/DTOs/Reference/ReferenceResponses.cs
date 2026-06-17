namespace eRentaCar.API.DTOs.Reference
{
    public class ReferenceItemResponse
    {
        public int Id { get; set; }
        public string Name { get; set; } = null!;
    }

    public class CategoryResponse
    {
        public int Id { get; set; }
        public string Name { get; set; } = null!;
        public string? Description { get; set; }
    }

    public class CityResponse
    {
        public int Id { get; set; }
        public string Name { get; set; } = null!;
        public string Country { get; set; } = null!;
    }

    public class CountryResponse
    {
        public int Id { get; set; }
        public string Name { get; set; } = null!;
        public string Code { get; set; } = null!;
    }

    public class ExtraServiceResponse
    {
        public int Id { get; set; }
        public string Name { get; set; } = null!;
        public string? Description { get; set; }
        public decimal PricePerDay { get; set; }
        public bool IsAvailable { get; set; }
    }
}
