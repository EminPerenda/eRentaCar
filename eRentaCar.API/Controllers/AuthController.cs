using eRentaCar.API.Constants;
using eRentaCar.API.DTOs.Auth;
using eRentaCar.API.Exceptions;
using eRentaCar.API.Models;
using eRentaCar.API.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;

namespace eRentaCar.API.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class AuthController : ControllerBase
    {
        private readonly UserManager<ApplicationUser> _userManager;
        private readonly ITokenService _tokenService;
        private readonly ITokenRevocationService _tokenRevocation;

        public AuthController(
            UserManager<ApplicationUser> userManager,
            ITokenService tokenService,
            ITokenRevocationService tokenRevocation)
        {
            _userManager = userManager;
            _tokenService = tokenService;
            _tokenRevocation = tokenRevocation;
        }

        [HttpPost("register")]
        [AllowAnonymous]
        public async Task<IActionResult> Register([FromBody] RegisterRequest request)
        {
           
            if (await _userManager.FindByEmailAsync(request.Email) != null)
                throw new BusinessException("Korisnik s ovom email adresom već postoji.");

            var user = new ApplicationUser
            {
                UserName = request.Email,
                Email = request.Email,
                FirstName = request.FirstName,
                LastName = request.LastName,
                PhoneNumber = request.PhoneNumber,
                CityId = request.CityId,
                DriverLicenseNo = request.DriverLicenseNo,
                EmailConfirmed = true
            };
            if (request.CityId.HasValue)
                user.CityId = request.CityId.Value;
            var result = await _userManager.CreateAsync(user, request.Password);
            if (!result.Succeeded)
            {
                var errors = string.Join(", ", result.Errors.Select(x => x.Description));
                throw new BusinessException(errors);
            }

            await _userManager.AddToRoleAsync(user, AppRoles.Client);

            var roles = await _userManager.GetRolesAsync(user);
            var token = _tokenService.GenerateToken(user, roles);

            return Ok(new AuthResponse
            {
                Token = token,
                Email = user.Email!,
                FullName = $"{user.FirstName} {user.LastName}",
                Role = roles.First()
            });
        }

        [HttpPost("login")]
        [AllowAnonymous]
        public async Task<IActionResult> Login([FromBody] LoginRequest request)
        {
            var user = await _userManager.FindByEmailAsync(request.Email)
                ?? throw new NotFoundException("Korisnik s ovom email adresom nije pronađen.");

            if (!user.IsActive)
                throw new BusinessException("Vaš nalog je deaktiviran. Kontaktirajte podršku.");

            if (!await _userManager.CheckPasswordAsync(user, request.Password))
                throw new BusinessException("Pogrešna lozinka.");

            var roles = await _userManager.GetRolesAsync(user);
            var token = _tokenService.GenerateToken(user, roles);

            return Ok(new AuthResponse
            {
                Token = token,
                Email = user.Email!,
                FullName = $"{user.FirstName} {user.LastName}",
                Role = roles.First()
            });
        }

        [HttpPost("logout")]
        [Authorize]
        public IActionResult Logout()
        {
            var jti = User.FindFirstValue(JwtRegisteredClaimNames.Jti);
            var expClaim = User.FindFirstValue(JwtRegisteredClaimNames.Exp);
            if (jti != null && expClaim != null && long.TryParse(expClaim, out var expUnix))
            {
                var expiry = DateTimeOffset.FromUnixTimeSeconds(expUnix).UtcDateTime;
                _tokenRevocation.Revoke(jti, expiry);
            }
            return Ok(new { message = "Odjava uspješna." });
        }
    }
}