using eRentaCar.API.DTOs;
using eRentaCar.API.DTOs.Notification;
using eRentaCar.API.Enums;

namespace eRentaCar.API.Services.Interfaces
{
    public interface INotificationService
    {
        Task<PagedResponse<NotificationResponse>> GetForUserAsync(int userId, int page = 1, int pageSize = 30);
        Task MarkAsReadAsync(int id, int userId);
        Task MarkAllAsReadAsync(int userId);
        Task SendToUserAsync(int userId, string title, string message, NotificationType type = NotificationType.System);
        Task SendToAllAsync(string title, string message);
        Task<int> GetUnreadCountAsync(int userId);
        Task<AdminNotificationListResponse> GetAllAdminAsync(int page, int pageSize);
    }
}
