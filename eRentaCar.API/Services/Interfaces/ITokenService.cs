using eRentaCar.API.Models;

namespace eRentaCar.API.Services.Interfaces
{
    public interface ITokenService
    {
        string GenerateToken(ApplicationUser user, IList<string> roles);
    }
}