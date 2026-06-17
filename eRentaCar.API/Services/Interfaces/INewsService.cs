using eRentaCar.API.DTOs;
using eRentaCar.API.DTOs.News;

namespace eRentaCar.API.Services.Interfaces
{
    public interface INewsService
    {
        Task<PagedResponse<NewsResponse>> GetAllAsync(bool onlyVisible = true, int page = 1, int pageSize = 20);
        Task<NewsResponse> GetByIdAsync(int id);
        Task<NewsResponse> CreateAsync(int authorId, NewsRequest request);
        Task<NewsResponse> UpdateAsync(int id, NewsRequest request);
        Task DeleteAsync(int id);
    }
}
