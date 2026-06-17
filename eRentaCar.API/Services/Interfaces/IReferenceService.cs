using eRentaCar.API.DTOs.Reference;

namespace eRentaCar.API.Services.Interfaces
{
    public interface IReferenceService
    {
        // Categories
        Task<List<CategoryResponse>> GetCategoriesAsync();
        Task<ReferenceItemResponse> CreateCategoryAsync(string name, string? description);
        Task<ReferenceItemResponse> UpdateCategoryAsync(int id, string name, string? description);
        Task DeleteCategoryAsync(int id);

        // Brands
        Task<List<ReferenceItemResponse>> GetBrandsAsync();
        Task<ReferenceItemResponse> CreateBrandAsync(string name);
        Task<ReferenceItemResponse> UpdateBrandAsync(int id, string name);
        Task DeleteBrandAsync(int id);

        // FuelTypes
        Task<List<ReferenceItemResponse>> GetFuelTypesAsync();
        Task<ReferenceItemResponse> CreateFuelTypeAsync(string name);
        Task<ReferenceItemResponse> UpdateFuelTypeAsync(int id, string name);
        Task DeleteFuelTypeAsync(int id);

        // Transmissions
        Task<List<ReferenceItemResponse>> GetTransmissionsAsync();
        Task<ReferenceItemResponse> CreateTransmissionAsync(string name);
        Task<ReferenceItemResponse> UpdateTransmissionAsync(int id, string name);
        Task DeleteTransmissionAsync(int id);

        // Cities
        Task<List<CityResponse>> GetCitiesAsync();
        Task<ReferenceItemResponse> CreateCityAsync(string name, int countryId);
        Task<ReferenceItemResponse> UpdateCityAsync(int id, string name, int countryId);
        Task DeleteCityAsync(int id);

        // Countries
        Task<List<CountryResponse>> GetCountriesAsync();
        Task<CountryResponse> CreateCountryAsync(string name, string code);
        Task<CountryResponse> UpdateCountryAsync(int id, string name, string code);
        Task DeleteCountryAsync(int id);

        // ExtraServices
        Task<List<ExtraServiceResponse>> GetExtraServicesAsync(bool all);
        Task<ExtraServiceResponse> CreateExtraServiceAsync(string name, string? description, decimal pricePerDay, bool isAvailable);
        Task<ExtraServiceResponse> UpdateExtraServiceAsync(int id, string name, string? description, decimal pricePerDay, bool isAvailable);
        Task DeleteExtraServiceAsync(int id);
    }
}
