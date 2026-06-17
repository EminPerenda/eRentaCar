using eRentaCar.API.DTOs.Location;

namespace eRentaCar.API.Services.Interfaces
{
    public interface ILocationService
    {
        Task<List<LocationResponse>> GetAllAsync();
        Task<LocationResponse> GetByIdAsync(int id);
        Task<LocationResponse> CreateAsync(LocationRequest request);
        Task<LocationResponse> UpdateAsync(int id, LocationRequest request);
        Task DeleteAsync(int id);
    }
}