using eRentaCar.API.DTOs.Recommendation;
using eRentaCar.API.Enums;

namespace eRentaCar.API.Services.Interfaces
{
    public interface ISearchHistoryService
    {
        Task LogAsync(int userId, SearchActionType actionType, int? vehicleId = null, int? categoryId = null);
        Task<List<RecommendationResponse>> GetRecommendationsAsync(int userId);
    }
}
