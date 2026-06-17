namespace eRentaCar.API.Services.Interfaces
{
    public interface ITokenRevocationService
    {
        void Revoke(string jti, DateTime expiry);
        bool IsRevoked(string jti);
    }
}
