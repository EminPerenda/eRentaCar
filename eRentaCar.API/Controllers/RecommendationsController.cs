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
    public class RecommendationsController : ControllerBase
    {
        private readonly ISearchHistoryService _searchHistoryService;

        public RecommendationsController(ISearchHistoryService searchHistoryService)
        {
            _searchHistoryService = searchHistoryService;
        }

        [HttpGet]
        public async Task<IActionResult> GetRecommendations()
        {
            var userId = GetUserId();
            var result = await _searchHistoryService.GetRecommendationsAsync(userId);
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