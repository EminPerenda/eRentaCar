using eRentaCar.API.Constants;
using eRentaCar.API.DTOs.User;
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
    public class UsersController : ControllerBase
    {
        private readonly IUserService _userService;

        public UsersController(IUserService userService)
        {
            _userService = userService;
        }

        [HttpGet]
        [Authorize(Roles = AppRoles.Admin)]
        public async Task<IActionResult> GetAll(
            [FromQuery] string? search,
            [FromQuery] int page = 1,
            [FromQuery] int pageSize = 10)
        {
            var result = await _userService.GetAllAsync(search, page, pageSize);
            return Ok(result);
        }

        [HttpGet("{id}")]
        [Authorize(Roles = AppRoles.Admin)]
        public async Task<IActionResult> GetById(int id)
        {
            var result = await _userService.GetByIdAsync(id);
            return Ok(result);
        }

        [HttpGet("me")]
        public async Task<IActionResult> GetCurrent()
        {
            var userId = GetUserId();
            var result = await _userService.GetCurrentAsync(userId);
            return Ok(result);
        }

        [HttpPut("me")]
        public async Task<IActionResult> UpdateProfile([FromBody] UpdateProfileRequest request)
        {

            var userId = GetUserId();
            var result = await _userService.UpdateProfileAsync(userId, request);
            return Ok(result);
        }

        [HttpPut("{id}")]
        [Authorize(Roles = AppRoles.Admin)]
        public async Task<IActionResult> UpdateUser(int id, [FromBody] UpdateUserRequest request)
        {
            var result = await _userService.UpdateUserAsync(id, request);
            return Ok(result);
        }

        [HttpPost("me/change-password")]
        public async Task<IActionResult> ChangePassword([FromBody] ChangePasswordRequest request)
        {
            var userId = GetUserId();
            await _userService.ChangePasswordAsync(userId, request);
            return Ok(new { message = "Lozinka je uspješno promijenjena." });
        }

        [HttpPost("{id}/reset-password")]
        [Authorize(Roles = AppRoles.Admin)]
        public async Task<IActionResult> AdminResetPassword(int id, [FromBody] AdminResetPasswordRequest request)
        {
            await _userService.AdminResetPasswordAsync(id, request.NewPassword);
            return Ok(new { message = "Lozinka je uspješno resetovana." });
        }

        [HttpPatch("{id}/toggle-active")]
        [Authorize(Roles = AppRoles.Admin)]
        public async Task<IActionResult> ToggleActive(int id)
        {
            await _userService.ToggleActiveAsync(id);
            return NoContent();
        }

        private int GetUserId()
        {
            var claim = User.FindFirstValue(ClaimTypes.NameIdentifier)
                ?? throw new UnauthorizedException();
            return int.Parse(claim);
        }
    }
}