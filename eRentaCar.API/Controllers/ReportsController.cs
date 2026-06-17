using eRentaCar.API.Constants;
using eRentaCar.API.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace eRentaCar.API.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize(Roles = AppRoles.Admin)]
    public class ReportsController : ControllerBase
    {
        private readonly IReportsService _reportsService;

        public ReportsController(IReportsService reportsService)
        {
            _reportsService = reportsService;
        }

        [HttpGet("financial")]
        public async Task<IActionResult> GetFinancial(
            [FromQuery] DateTime? from,
            [FromQuery] DateTime? to)
        {
            var result = await _reportsService.GetFinancialAsync(from, to);
            return Ok(result);
        }

        [HttpGet("vehicles")]
        public async Task<IActionResult> GetVehicles(
            [FromQuery] DateTime? from,
            [FromQuery] DateTime? to)
        {
            var result = await _reportsService.GetVehiclesAsync(from, to);
            return Ok(result);
        }

        [HttpGet("clients")]
        public async Task<IActionResult> GetClients(
            [FromQuery] DateTime? from,
            [FromQuery] DateTime? to)
        {
            var result = await _reportsService.GetClientsAsync(from, to);
            return Ok(result);
        }

        [HttpGet("locations")]
        public async Task<IActionResult> GetLocations(
            [FromQuery] DateTime? from,
            [FromQuery] DateTime? to)
        {
            var result = await _reportsService.GetLocationsAsync(from, to);
            return Ok(result);
        }
    }
}
