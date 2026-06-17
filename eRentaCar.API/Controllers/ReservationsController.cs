using eRentaCar.API.Constants;
using eRentaCar.API.DTOs.Reservation;
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
    public class ReservationsController : ControllerBase
    {
        private readonly IReservationService _reservationService;

        public ReservationsController(IReservationService reservationService)
        {
            _reservationService = reservationService;
        }

        [HttpGet]
        [Authorize(Roles = AppRoles.Admin)]
        public async Task<IActionResult> GetAll([FromQuery] ReservationFilterRequest filter)
        {
            var result = await _reservationService.GetAllAsync(filter);
            return Ok(result);
        }

        [HttpGet("{id}")]
        public async Task<IActionResult> GetById(int id)
        {
            var userId = GetUserId();
            var isAdmin = User.IsInRole(AppRoles.Admin);
            var result = await _reservationService.GetByIdAsync(id);

            if (!isAdmin && result.ClientEmail != User.FindFirstValue(ClaimTypes.Email))
                throw new UnauthorizedException();

            return Ok(result);
        }

        [HttpGet("my")]
        [Authorize(Roles = AppRoles.Client)]
        public async Task<IActionResult> GetMy([FromQuery] ReservationFilterRequest filter)
        {
            filter.UserId = GetUserId();
            var result = await _reservationService.GetAllAsync(filter);
            return Ok(result);
        }

        [HttpPost]
        [Authorize(Roles = AppRoles.Client)]
        public async Task<IActionResult> Create([FromBody] ReservationRequest request)
        {
            var userId = GetUserId();
            var result = await _reservationService.CreateAsync(userId, request);
            return CreatedAtAction(nameof(GetById), new { id = result.Id }, result);
        }

        [HttpPatch("{id}/confirm")]
        [Authorize(Roles = AppRoles.Admin)]
        public async Task<IActionResult> Confirm(int id)
        {
            var adminId = GetUserId();
            var result = await _reservationService.ConfirmAsync(id, adminId);
            return Ok(result);
        }

        [HttpPatch("{id}/reject")]
        [Authorize(Roles = AppRoles.Admin)]
        public async Task<IActionResult> Reject(int id, [FromBody] RejectReservationRequest request)
        {
            var adminId = GetUserId();
            var result = await _reservationService.RejectAsync(id, adminId, request.Reason);
            return Ok(result);
        }

        [HttpPatch("{id}/activate")]
        [Authorize(Roles = AppRoles.Admin)]
        public async Task<IActionResult> Activate(int id)
        {
            var adminId = GetUserId();
            var result = await _reservationService.ActivateAsync(id, adminId);
            return Ok(result);
        }

        [HttpPatch("{id}/cancel")]
        public async Task<IActionResult> Cancel(int id, [FromBody] CancelReservationRequest request)
        {
            var userId = GetUserId();
            var isAdmin = User.IsInRole(AppRoles.Admin);
            var result = await _reservationService.CancelAsync(id, userId, request.Reason, isAdmin);
            return Ok(result);
        }

        [HttpPatch("{id}/complete")]
        [Authorize(Roles = AppRoles.Admin)]
        public async Task<IActionResult> Complete(int id)
        {
            var adminId = GetUserId();
            var result = await _reservationService.CompleteAsync(id, adminId);
            return Ok(result);
        }

        private int GetUserId()
        {
            var claim = User.FindFirstValue(ClaimTypes.NameIdentifier)
                ?? throw new UnauthorizedException();
            return int.Parse(claim);
        }
    }
}