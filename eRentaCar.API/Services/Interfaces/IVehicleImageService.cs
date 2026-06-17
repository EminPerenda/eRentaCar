using eRentaCar.API.DTOs.Vehicle;

namespace eRentaCar.API.Services.Interfaces
{
    public interface IVehicleImageService
    {
        Task<List<VehicleImageResponse>> GetAllAsync(int vehicleId);
        Task<VehicleImageResponse> UploadAsync(int vehicleId, string imageUrl, bool isPrimary);
        Task SetPrimaryAsync(int vehicleId, int imageId);
        Task<string> DeleteAsync(int vehicleId, int imageId);
    }
}
