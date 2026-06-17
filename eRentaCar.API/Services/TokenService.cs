using eRentaCar.API.Models;
using eRentaCar.API.Services.Interfaces;
using Microsoft.IdentityModel.Tokens;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;

namespace eRentaCar.API.Services
{
    public class TokenService : ITokenService
    {
        private readonly string _key;
        private readonly string _issuer;
        private readonly string _audience;

        private static string GetRequiredEnv(string errorMessage, params string[] names)
        {
            foreach (var name in names)
            {
                var value = Environment.GetEnvironmentVariable(name);
                if (!string.IsNullOrWhiteSpace(value))
                    return value;
            }

            throw new InvalidOperationException(errorMessage);
        }

        public TokenService()
        {
            _key = GetRequiredEnv("JWT_KEY nije postavljen.", "JWT_KEY", "JWT__Secret");
            _issuer = GetRequiredEnv("JWT_ISSUER nije postavljen.", "JWT_ISSUER", "JWT__Issuer");
            _audience = GetRequiredEnv("JWT_AUDIENCE nije postavljen.", "JWT_AUDIENCE", "JWT__Audience");
        }

        public string GenerateToken(ApplicationUser user, IList<string> roles)
        {
            var claims = new List<Claim>
            {
                new Claim(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString()),
                new Claim(ClaimTypes.NameIdentifier, user.Id.ToString()),
                new Claim(ClaimTypes.Email, user.Email!),
                new Claim(ClaimTypes.GivenName, user.FirstName),
                new Claim(ClaimTypes.Surname, user.LastName),
            };

            foreach (var role in roles)
                claims.Add(new Claim(ClaimTypes.Role, role));

            var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(_key));
            var creds = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);

            var token = new JwtSecurityToken(
                issuer: _issuer,
                audience: _audience,
                claims: claims,
                expires: DateTime.UtcNow.AddDays(1),
                signingCredentials: creds
            );

            return new JwtSecurityTokenHandler().WriteToken(token);
        }
    }
}