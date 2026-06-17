using eRentaCar.API.DTOs;
using eRentaCar.API.DTOs.Review;

namespace eRentaCar.API.Services.Interfaces
{
    public interface IReviewService
    {
        Task<PagedResponse<ReviewResponse>> GetByVehicleAsync(int vehicleId, int page = 1, int pageSize = 20);
        Task<ReviewResponse> CreateAsync(int userId, ReviewRequest request);
    }
}
