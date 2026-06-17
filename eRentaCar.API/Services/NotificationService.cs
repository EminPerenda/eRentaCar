using eRentaCar.API.Data;
using eRentaCar.API.DTOs;
using eRentaCar.API.DTOs.Notification;
using eRentaCar.API.Enums;
using eRentaCar.API.Exceptions;
using eRentaCar.API.Hubs;
using eRentaCar.API.Models;
using eRentaCar.API.Services.Interfaces;
using Microsoft.AspNetCore.SignalR;
using Microsoft.EntityFrameworkCore;

namespace eRentaCar.API.Services
{
    public class NotificationService : INotificationService
    {
        private readonly ApplicationDbContext _context;
        private readonly IHubContext<NotificationHub> _hubContext;
        private readonly RabbitMQPublisher _publisher;

        public NotificationService(
            ApplicationDbContext context,
            IHubContext<NotificationHub> hubContext,
            RabbitMQPublisher publisher)
        {
            _context = context;
            _hubContext = hubContext;
            _publisher = publisher;
        }

        public async Task<PagedResponse<NotificationResponse>> GetForUserAsync(int userId, int page = 1, int pageSize = 30)
        {
            if (pageSize > 100) pageSize = 100;

            var query = _context.Notifications
                .Where(x => x.UserId == userId)
                .OrderByDescending(x => x.CreatedAt);

            var totalCount = await query.CountAsync();

            var notifications = await query
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .ToListAsync();

            return new PagedResponse<NotificationResponse>
            {
                Items = notifications.Select(MapToResponse).ToList(),
                TotalCount = totalCount,
                Page = page,
                PageSize = pageSize
            };
        }

        public async Task MarkAsReadAsync(int id, int userId)
        {
            var notification = await _context.Notifications
                .FirstOrDefaultAsync(x => x.Id == id && x.UserId == userId)
                ?? throw new NotFoundException("Notifikacija", id);

            notification.IsRead = true;
            notification.ReadAt = DateTime.UtcNow;
            await _context.SaveChangesAsync();
        }

        public async Task MarkAllAsReadAsync(int userId)
        {
            var notifications = await _context.Notifications
                .Where(x => x.UserId == userId && !x.IsRead)
                .ToListAsync();

            var now = DateTime.UtcNow;
            foreach (var n in notifications)
            {
                n.IsRead = true;
                n.ReadAt = now;
            }

            await _context.SaveChangesAsync();
        }

        public async Task SendToUserAsync(int userId, string title, string message, NotificationType type = NotificationType.System)
        {
            var user = await _context.Users.FindAsync(userId);

            var notification = new Notification
            {
                UserId = userId,
                Title = title,
                Message = message,
                Type = type
            };

            _context.Notifications.Add(notification);
            await _context.SaveChangesAsync();

            await _hubContext.Clients
                .Group($"user_{userId}")
                .SendAsync("ReceiveNotification", new
                {
                    id = notification.Id,
                    title = notification.Title,
                    message = notification.Message,
                    type = notification.Type.ToString(),
                    isRead = notification.IsRead,
                    createdAt = notification.CreatedAt
                });

            await _publisher.PublishAsync(new NotificationMessage
            {
                UserId = userId,
                Title = title,
                Message = message,
                Type = type.ToString(),
                Email = user?.Email
            });
        }

        public async Task SendToAllAsync(string title, string message)
        {
            var users = await _context.Users
                .Where(x => x.IsActive)
                .Select(x => new { x.Id, x.Email })
                .ToListAsync();

            var notifications = users.Select(u => new Notification
            {
                UserId = u.Id,
                Title = title,
                Message = message,
                Type = NotificationType.System
            }).ToList();

            _context.Notifications.AddRange(notifications);
            await _context.SaveChangesAsync();

            await _hubContext.Clients.All.SendAsync("ReceiveNotification", new
            {
                title,
                message,
                type = NotificationType.System.ToString(),
                isRead = false,
                createdAt = DateTime.UtcNow
            });

            var publishTasks = users.Select(u => _publisher.PublishAsync(new NotificationMessage
            {
                UserId = u.Id,
                Title = title,
                Message = message,
                Type = NotificationType.System.ToString(),
                Email = u.Email
            }));
            await Task.WhenAll(publishTasks);
        }

        public async Task<int> GetUnreadCountAsync(int userId)
        {
            return await _context.Notifications
                .CountAsync(x => x.UserId == userId && !x.IsRead);
        }

        public async Task<AdminNotificationListResponse> GetAllAdminAsync(int page, int pageSize)
        {
            if (pageSize > 100) pageSize = 100;
            var query = _context.Notifications
                .Include(x => x.User)
                .OrderByDescending(x => x.CreatedAt);
            var total = await query.CountAsync();
            var items = await query
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .Select(n => new AdminNotificationResponse
                {
                    Id = n.Id,
                    Title = n.Title,
                    Message = n.Message,
                    IsRead = n.IsRead,
                    CreatedAt = n.CreatedAt,
                    UserName = n.User.FirstName + " " + n.User.LastName,
                    UserEmail = n.User.Email
                })
                .ToListAsync();
            return new AdminNotificationListResponse { Items = items, TotalCount = total, Page = page, PageSize = pageSize };
        }

        private static NotificationResponse MapToResponse(Notification n) => new()
        {
            Id = n.Id,
            Title = n.Title,
            Message = n.Message,
            IsRead = n.IsRead,
            ReadAt = n.ReadAt,
            Type = n.Type.ToString(),
            CreatedAt = n.CreatedAt
        };
    }
}
