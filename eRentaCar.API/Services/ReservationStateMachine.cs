using eRentaCar.API.Enums;
using eRentaCar.API.Exceptions;

namespace eRentaCar.API.Services
{
    public static class ReservationStateMachine
    {
        private static readonly Dictionary<ReservationStatus, HashSet<ReservationStatus>> _allowed = new()
        {
            [ReservationStatus.Pending]   = new() { ReservationStatus.Confirmed, ReservationStatus.Cancelled },
            [ReservationStatus.Confirmed] = new() { ReservationStatus.Active, ReservationStatus.Completed, ReservationStatus.Cancelled },
            [ReservationStatus.Active]    = new() { ReservationStatus.Completed, ReservationStatus.Cancelled },
            [ReservationStatus.Completed] = new(),
            [ReservationStatus.Cancelled] = new(),
        };

        private static readonly Dictionary<ReservationStatus, string> _bosnianNames = new()
        {
            [ReservationStatus.Pending]   = "Na čekanju",
            [ReservationStatus.Confirmed] = "Potvrđena",
            [ReservationStatus.Active]    = "Aktivna",
            [ReservationStatus.Completed] = "Završena",
            [ReservationStatus.Cancelled] = "Otkazana",
        };

        public static void ValidateTransition(ReservationStatus from, ReservationStatus to)
        {
            if (!_allowed.TryGetValue(from, out var allowed) || !allowed.Contains(to))
            {
                var fromName = _bosnianNames.GetValueOrDefault(from, from.ToString());
                var toName = _bosnianNames.GetValueOrDefault(to, to.ToString());
                throw new BusinessException($"Prijelaz iz statusa '{fromName}' u '{toName}' nije dozvoljen.");
            }
        }

        public static bool CanTransition(ReservationStatus from, ReservationStatus to)
            => _allowed.TryGetValue(from, out var allowed) && allowed.Contains(to);
    }
}
