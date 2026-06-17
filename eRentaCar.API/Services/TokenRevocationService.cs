using eRentaCar.API.Services.Interfaces;
using System.Collections.Concurrent;

namespace eRentaCar.API.Services
{
    public class TokenRevocationService : ITokenRevocationService
    {
        private readonly ConcurrentDictionary<string, DateTime> _revoked = new();

        public void Revoke(string jti, DateTime expiry)
        {
            _revoked[jti] = expiry;
            PurgeExpired();
        }

        public bool IsRevoked(string jti)
            => _revoked.ContainsKey(jti);

        private void PurgeExpired()
        {
            var now = DateTime.UtcNow;
            foreach (var key in _revoked.Keys.ToList())
            {
                if (_revoked.TryGetValue(key, out var expiry) && expiry < now)
                    _revoked.TryRemove(key, out _);
            }
        }
    }
}
