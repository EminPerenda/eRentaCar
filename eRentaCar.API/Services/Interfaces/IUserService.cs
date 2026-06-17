using eRentaCar.API.DTOs;
using eRentaCar.API.DTOs.User;

namespace eRentaCar.API.Services.Interfaces
{
    public interface IUserService
    {
        Task<PagedResponse<UserResponse>> GetAllAsync(string? search, int page, int pageSize);
        Task<UserResponse> GetByIdAsync(int id);
        Task<UserResponse> GetCurrentAsync(int userId);
        Task<UserResponse> UpdateProfileAsync(int userId, UpdateProfileRequest request);
        Task<UserResponse> UpdateUserAsync(int id, UpdateUserRequest request);
        Task ChangePasswordAsync(int userId, ChangePasswordRequest request);
        Task AdminResetPasswordAsync(int userId, string newPassword);
        Task ToggleActiveAsync(int id);
    }
}