using eRentaCar.API.DTOs;
using eRentaCar.API.DTOs.Vehicle;

namespace eRentaCar.API.Services.Interfaces
{
    public interface IVehicleService
    {
        Task<PagedResponse<VehicleResponse>> GetAllAsync(VehicleFilterRequest filter);
        Task<VehicleResponse> GetByIdAsync(int id);
        Task<VehicleResponse> CreateAsync(VehicleRequest request);
        Task<VehicleResponse> UpdateAsync(int id, VehicleRequest request);
        Task DeleteAsync(int id);
        Task UpdateStatusAsync(int id, int status);
        Task<List<VehicleReservationHistoryResponse>> GetReservationHistoryAsync(int vehicleId);
    }
}