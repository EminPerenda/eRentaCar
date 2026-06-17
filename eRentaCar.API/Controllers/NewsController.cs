using eRentaCar.API.Constants;
using eRentaCar.API.DTOs.News;
using eRentaCar.API.Exceptions;
using eRentaCar.API.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;

namespace eRentaCar.API.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class NewsController : ControllerBase
    {
        private readonly INewsService _newsService;

        public NewsController(INewsService newsService)
        {
            _newsService = newsService;
        }

        [HttpGet]
        [AllowAnonymous]
        public async Task<IActionResult> GetAll(
            [FromQuery] int page = 1,
            [FromQuery] int pageSize = 20)
        {
            var result = await _newsService.GetAllAsync(onlyVisible: true, page, pageSize);
            return Ok(result);
        }

        [HttpGet("all")]
        [Authorize(Roles = AppRoles.Admin)]
        public async Task<IActionResult> GetAllAdmin(
            [FromQuery] int page = 1,
            [FromQuery] int pageSize = 20)
        {
            var result = await _newsService.GetAllAsync(onlyVisible: false, page, pageSize);
            return Ok(result);
        }

        [HttpGet("{id}")]
        [AllowAnonymous]
        public async Task<IActionResult> GetById(int id)
        {
            var result = await _newsService.GetByIdAsync(id);
            return Ok(result);
        }

        [HttpPost]
        [Authorize(Roles = AppRoles.Admin)]
        public async Task<IActionResult> Create([FromBody] NewsRequest request)
        {
            var authorId = GetUserId();
            var result = await _newsService.CreateAsync(authorId, request);
            return CreatedAtAction(nameof(GetById), new { id = result.Id }, result);
        }

        [HttpPut("{id}")]
        [Authorize(Roles = AppRoles.Admin)]
        public async Task<IActionResult> Update(int id, [FromBody] NewsRequest request)
        {
            var result = await _newsService.UpdateAsync(id, request);
            return Ok(result);
        }

        [HttpDelete("{id}")]
        [Authorize(Roles = AppRoles.Admin)]
        public async Task<IActionResult> Delete(int id)
        {
            await _newsService.DeleteAsync(id);
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
