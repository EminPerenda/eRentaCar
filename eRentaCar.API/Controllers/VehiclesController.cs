using eRentaCar.API.Constants;
using eRentaCar.API.DTOs.Vehicle;
using eRentaCar.API.Enums;
using eRentaCar.API.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;

namespace eRentaCar.API.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    public class VehiclesController : ControllerBase
    {
        private readonly IVehicleService _vehicleService;
        private readonly ISearchHistoryService _searchHistoryService;
        private readonly IReservationService _reservationService;

        public VehiclesController(IVehicleService vehicleService, ISearchHistoryService searchHistoryService, IReservationService reservationService)
        {
            _vehicleService = vehicleService;
            _searchHistoryService = searchHistoryService;
            _reservationService = reservationService;
        }

        [HttpGet]
        [AllowAnonymous]
        public async Task<IActionResult> GetAll([FromQuery] VehicleFilterRequest filter)
        {
            var result = await _vehicleService.GetAllAsync(filter);
            return Ok(result);
        }

        [HttpGet("{id}")]
        [AllowAnonymous]
        public async Task<IActionResult> GetById(int id)
        {
            var result = await _vehicleService.GetByIdAsync(id);

            var userIdClaim = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (userIdClaim != null)
            {
                var userId = int.Parse(userIdClaim);
                await _searchHistoryService.LogAsync(userId, SearchActionType.VehicleView,
                    vehicleId: id, categoryId: result.CategoryId);
            }

            return Ok(result);
        }

        [HttpPost]
        [Authorize(Roles = AppRoles.Admin)]
        public async Task<IActionResult> Create([FromBody] VehicleRequest request)
        {
            var result = await _vehicleService.CreateAsync(request);
            return CreatedAtAction(nameof(GetById), new { id = result.Id }, result);
        }

        [HttpPut("{id}")]
        [Authorize(Roles = AppRoles.Admin)]
        public async Task<IActionResult> Update(int id, [FromBody] VehicleRequest request)
        {
            var result = await _vehicleService.UpdateAsync(id, request);
            return Ok(result);
        }

        [HttpDelete("{id}")]
        [Authorize(Roles = AppRoles.Admin)]
        public async Task<IActionResult> Delete(int id)
        {
            await _vehicleService.DeleteAsync(id);
            return NoContent();
        }

        [HttpPatch("{id}/status")]
        [Authorize(Roles = AppRoles.Admin)]
        public async Task<IActionResult> UpdateStatus(int id, [FromQuery] int status)
        {
            await _vehicleService.UpdateStatusAsync(id, status);
            return NoContent();
        }

        [HttpGet("{id}/occupied-dates")]
        [Authorize]
        public async Task<IActionResult> GetOccupiedDates(int id)
        {
            var dates = await _reservationService.GetVehicleOccupiedDatesAsync(id);
            return Ok(dates);
        }
    }
}