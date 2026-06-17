using eRentaCar.API.Constants;
using eRentaCar.API.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace eRentaCar.API.Controllers
{
    [ApiController]
    [Route("api/vehicles/{vehicleId:int}/reservations")]
    [Authorize(Roles = AppRoles.Admin)]
    public class VehicleReservationsController : ControllerBase
    {
        private readonly IVehicleService _vehicleService;

        public VehicleReservationsController(IVehicleService vehicleService)
        {
            _vehicleService = vehicleService;
        }

        [HttpGet("history")]
        public async Task<IActionResult> GetHistory(int vehicleId)
        {
            var history = await _vehicleService.GetReservationHistoryAsync(vehicleId);
            return Ok(history);
        }
    }
}
