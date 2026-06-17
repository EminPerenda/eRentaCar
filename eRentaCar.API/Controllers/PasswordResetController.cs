using eRentaCar.API.Services.Interfaces;
using Microsoft.AspNetCore.Mvc;

namespace eRentaCar.API.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class PasswordResetController : ControllerBase
    {
        private readonly IPasswordResetService _passwordResetService;

        public PasswordResetController(IPasswordResetService passwordResetService)
        {
            _passwordResetService = passwordResetService;
        }

        [HttpPost("request")]
        public async Task<IActionResult> RequestReset([FromBody] RequestResetDto request)
        {
            await _passwordResetService.RequestResetAsync(request.Email);
            return Ok(new { message = "Ako e-mail postoji, poslan je kod za reset." });
        }

        [HttpPost("confirm")]
        public async Task<IActionResult> ConfirmReset([FromBody] ConfirmResetDto request)
        {
            await _passwordResetService.ConfirmResetAsync(request.Code, request.NewPassword);
            return Ok(new { message = "Lozinka je uspješno promijenjena." });
        }
    }

    public class RequestResetDto
    {
        public string Email { get; set; } = null!;
    }

    public class ConfirmResetDto
    {
        public string Code { get; set; } = null!;
        public string NewPassword { get; set; } = null!;
    }
}
