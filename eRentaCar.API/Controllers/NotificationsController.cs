using eRentaCar.API.Constants;
using eRentaCar.API.DTOs.Notification;
using eRentaCar.API.Exceptions;
using eRentaCar.API.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;

namespace eRentaCar.API.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    public class NotificationsController : ControllerBase
    {
        private readonly INotificationService _notificationService;

        public NotificationsController(INotificationService notificationService)
        {
            _notificationService = notificationService;
        }

        [HttpGet("admin")]
        [Authorize(Roles = AppRoles.Admin)]
        public async Task<IActionResult> GetAllAdmin(
            [FromQuery] int page = 1,
            [FromQuery] int pageSize = 30)
        {
            var result = await _notificationService.GetAllAdminAsync(page, pageSize);
            return Ok(result);
        }

        [HttpGet]
        public async Task<IActionResult> GetMy(
            [FromQuery] int page = 1,
            [FromQuery] int pageSize = 30)
        {
            var userId = GetUserId();
            var result = await _notificationService.GetForUserAsync(userId, page, pageSize);
            return Ok(result);
        }

        [HttpGet("unread-count")]
        public async Task<IActionResult> GetUnreadCount()
        {
            var userId = GetUserId();
            var count = await _notificationService.GetUnreadCountAsync(userId);
            return Ok(new { count });
        }

        [HttpPatch("{id}/read")]
        public async Task<IActionResult> MarkAsRead(int id)
        {
            var userId = GetUserId();
            await _notificationService.MarkAsReadAsync(id, userId);
            return NoContent();
        }

        [HttpPatch("read-all")]
        public async Task<IActionResult> MarkAllAsRead()
        {
            var userId = GetUserId();
            await _notificationService.MarkAllAsReadAsync(userId);
            return NoContent();
        }

        [HttpPost("send")]
        [Authorize(Roles = AppRoles.Admin)]
        public async Task<IActionResult> Send([FromBody] CreateNotificationRequest request)
        {
            if (request.UserId.HasValue)
                await _notificationService.SendToUserAsync(request.UserId.Value, request.Title, request.Message);
            else
                await _notificationService.SendToAllAsync(request.Title, request.Message);

            return Ok(new { message = "Obavijest je uspješno poslana." });
        }

        private int GetUserId()
        {
            var claim = User.FindFirstValue(ClaimTypes.NameIdentifier)
                ?? throw new UnauthorizedException();
            return int.Parse(claim);
        }
    }
}
