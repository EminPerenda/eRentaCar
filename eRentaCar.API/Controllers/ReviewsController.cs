using eRentaCar.API.Constants;
using eRentaCar.API.Enums;
using eRentaCar.API.DTOs.Review;
using eRentaCar.API.Exceptions;
using eRentaCar.API.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;

namespace eRentaCar.API.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class ReviewsController : ControllerBase
    {
        private readonly IReviewService _reviewService;
        private readonly ISearchHistoryService _searchHistoryService;

        public ReviewsController(IReviewService reviewService, ISearchHistoryService searchHistoryService)
        {
            _reviewService = reviewService;
            _searchHistoryService = searchHistoryService;
        }

        [HttpGet("vehicle/{vehicleId}")]
        [AllowAnonymous]
        public async Task<IActionResult> GetByVehicle(
            int vehicleId,
            [FromQuery] int page = 1,
            [FromQuery] int pageSize = 20)
        {
            var result = await _reviewService.GetByVehicleAsync(vehicleId, page, pageSize);
            return Ok(result);
        }

        [HttpPost]
        [Authorize(Roles = AppRoles.Client)]
        public async Task<IActionResult> Create([FromBody] ReviewRequest request)
        {
            var userId = GetUserId();
            var result = await _reviewService.CreateAsync(userId, request);

            await _searchHistoryService.LogAsync(userId, SearchActionType.Review, request.VehicleId);

            return CreatedAtAction(nameof(GetByVehicle), new { vehicleId = result.VehicleId }, result);
        }

        private int GetUserId()
        {
            var claim = User.FindFirstValue(ClaimTypes.NameIdentifier)
                ?? throw new UnauthorizedException();
            return int.Parse(claim);
        }
    }
}
