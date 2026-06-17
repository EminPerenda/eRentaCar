using eRentaCar.API.Data;
using eRentaCar.API.DTOs;
using eRentaCar.API.DTOs.Reservation;
using eRentaCar.API.Enums;
using eRentaCar.API.Exceptions;
using eRentaCar.API.Models;
using eRentaCar.API.Services.Interfaces;
using Microsoft.EntityFrameworkCore;
using NotificationType = eRentaCar.API.Enums.NotificationType;

namespace eRentaCar.API.Services
{
    public class ReservationService : IReservationService
    {
        private readonly ApplicationDbContext _context;
        private readonly INotificationService _notificationService;

        public ReservationService(ApplicationDbContext context, INotificationService notificationService)
        {
            _context = context;
            _notificationService = notificationService;
        }

        public async Task<PagedResponse<ReservationResponse>> GetAllAsync(ReservationFilterRequest filter)
        {
            if (filter.PageSize > 100) filter.PageSize = 100;

            var query = _context.Reservations
                .Include(x => x.User)
                .Include(x => x.Vehicle).ThenInclude(x => x.Brand)
                .Include(x => x.PickupLocation)
                .Include(x => x.DropoffLocation)
                .Include(x => x.ApprovedBy)
                .Include(x => x.Payment)
                .Include(x => x.Extras).ThenInclude(x => x.ExtraService)
                .AsQueryable();

            if (!string.IsNullOrEmpty(filter.Status) && Enum.TryParse<ReservationStatus>(filter.Status, out var status))
                query = query.Where(x => x.Status == status);

            if (filter.VehicleId.HasValue)
                query = query.Where(x => x.VehicleId == filter.VehicleId);

            if (filter.UserId.HasValue)
                query = query.Where(x => x.UserId == filter.UserId);

            if (filter.LocationId.HasValue)
                query = query.Where(x => x.PickupLocationId == filter.LocationId || x.DropoffLocationId == filter.LocationId);

            if (!string.IsNullOrEmpty(filter.ClientName))
                query = query.Where(x => (x.User.FirstName + " " + x.User.LastName).Contains(filter.ClientName));

            if (filter.From.HasValue)
                query = query.Where(x => x.StartDate >= filter.From);

            if (filter.To.HasValue)
                query = query.Where(x => x.EndDate <= filter.To);

            var totalCount = await query.CountAsync();

            var items = await query
                .OrderByDescending(x => x.CreatedAt)
                .Skip((filter.Page - 1) * filter.PageSize)
                .Take(filter.PageSize)
                .ToListAsync();

            return new PagedResponse<ReservationResponse>
            {
                Items = items.Select(MapToResponse).ToList(),
                TotalCount = totalCount,
                Page = filter.Page,
                PageSize = filter.PageSize
            };
        }

        public async Task<ReservationResponse> GetByIdAsync(int id)
        {
            var reservation = await GetReservationWithIncludes(id)
                ?? throw new NotFoundException("Rezervacija", id);

            return MapToResponse(reservation);
        }

        public async Task<ReservationResponse> CreateAsync(int userId, ReservationRequest request)
        {
            if (request.StartDate >= request.EndDate)
                throw new BusinessException("Datum završetka mora biti nakon datuma početka.");

            if (request.StartDate < DateTime.UtcNow.Date)
                throw new BusinessException("Datum početka ne može biti u prošlosti.");

            var user = await _context.Users.FindAsync(userId)
                ?? throw new NotFoundException("Korisnik", userId);

            if (string.IsNullOrEmpty(user.DriverLicenseNo))
                throw new BusinessException("Morate unijeti broj vozačke dozvole u profilu prije rezervacije.");

            var vehicle = await _context.Vehicles.FindAsync(request.VehicleId)
                ?? throw new NotFoundException("Vozilo", request.VehicleId);

            if (vehicle.Status != VehicleStatus.Available)
                throw new BusinessException("Odabrano vozilo trenutno nije dostupno.");

            var hasOverlap = await _context.Reservations.AnyAsync(x =>
                x.VehicleId == request.VehicleId &&
                x.Status != ReservationStatus.Cancelled &&
                x.StartDate < request.EndDate &&
                x.EndDate > request.StartDate);

            if (hasOverlap)
                throw new BusinessException("Vozilo nije dostupno u odabranom periodu.");

            var hasDuplicate = await _context.Reservations.AnyAsync(x =>
                x.UserId == userId &&
                x.VehicleId == request.VehicleId &&
                x.Status != ReservationStatus.Cancelled &&
                x.StartDate < request.EndDate &&
                x.EndDate > request.StartDate);

            if (hasDuplicate)
                throw new BusinessException("Već imate aktivnu rezervaciju za ovo vozilo u odabranom periodu.");

            var totalDays = (int)Math.Ceiling((request.EndDate - request.StartDate).TotalDays);
            var basePrice = vehicle.PricePerDay * totalDays;
            decimal extrasPrice = 0;

            var extras = new List<ReservationExtra>();
            foreach (var extraReq in request.Extras)
            {
                var service = await _context.ExtraServices.FindAsync(extraReq.ExtraServiceId)
                    ?? throw new NotFoundException("Dodatna usluga", extraReq.ExtraServiceId);

                if (!service.IsAvailable)
                    throw new BusinessException($"Usluga '{service.Name}' trenutno nije dostupna.");

                var priceAtTime = service.PricePerDay * totalDays * extraReq.Quantity;
                extrasPrice += priceAtTime;

                extras.Add(new ReservationExtra
                {
                    ExtraServiceId = extraReq.ExtraServiceId,
                    Quantity = extraReq.Quantity,
                    PriceAtTime = priceAtTime
                });
            }

            var reservation = new Reservation
            {
                UserId = userId,
                VehicleId = request.VehicleId,
                PickupLocationId = request.PickupLocationId,
                DropoffLocationId = request.DropoffLocationId,
                StartDate = request.StartDate,
                EndDate = request.EndDate,
                TotalDays = totalDays,
                BasePrice = basePrice,
                ExtrasPrice = extrasPrice,
                TotalPrice = basePrice + extrasPrice,
                Status = ReservationStatus.Pending,
                Extras = extras
            };

            _context.Reservations.Add(reservation);
            await _context.SaveChangesAsync();

            return await GetByIdAsync(reservation.Id);
        }

        public async Task<ReservationResponse> ConfirmAsync(int id, int adminId)
        {
            var reservation = await _context.Reservations
                .Include(x => x.Vehicle)
                .FirstOrDefaultAsync(x => x.Id == id)
                ?? throw new NotFoundException("Rezervacija", id);

            ReservationStateMachine.ValidateTransition(reservation.Status, ReservationStatus.Confirmed);

            var hasOverlap = await _context.Reservations.AnyAsync(x =>
                x.VehicleId == reservation.VehicleId &&
                x.Id != id &&
                x.Status != ReservationStatus.Cancelled &&
                x.StartDate < reservation.EndDate &&
                x.EndDate > reservation.StartDate);

            if (hasOverlap)
                throw new BusinessException("Vozilo nije dostupno u odabranom periodu — postoji preklapanje s drugom rezervacijom.");

            reservation.Status = ReservationStatus.Confirmed;
            reservation.ApprovedById = adminId;
            reservation.ApprovedAt = DateTime.UtcNow;

            await _context.SaveChangesAsync();

            await _notificationService.SendToUserAsync(
                reservation.UserId,
                "Rezervacija potvrđena",
                $"Vaša rezervacija #{reservation.Id} je potvrđena. Preuzimanje vozila je {reservation.StartDate:dd.MM.yyyy}.",
                NotificationType.Reservation);

            return await GetByIdAsync(id);
        }

        public async Task<ReservationResponse> RejectAsync(int id, int adminId, string reason)
        {
            var reservation = await _context.Reservations
                .Include(x => x.User)
                .FirstOrDefaultAsync(x => x.Id == id)
                ?? throw new NotFoundException("Rezervacija", id);

            ReservationStateMachine.ValidateTransition(reservation.Status, ReservationStatus.Cancelled);

            if (reservation.Status != ReservationStatus.Pending)
                throw new BusinessException("Samo rezervacije na čekanju mogu biti odbijene.");

            if (string.IsNullOrWhiteSpace(reason))
                throw new BusinessException("Razlog odbijanja je obavezan.");

            reservation.Status = ReservationStatus.Cancelled;
            reservation.CancellationReason = $"[ODBIJENO] {reason}";
            reservation.CancelledById = adminId;
            reservation.CancelledAt = DateTime.UtcNow;

            await _context.SaveChangesAsync();

            await _notificationService.SendToUserAsync(
                reservation.UserId,
                "Rezervacija odbijena",
                $"Vaša rezervacija #{reservation.Id} je odbijena. Razlog: {reason}",
                NotificationType.Cancellation);

            return await GetByIdAsync(id);
        }

        public async Task<ReservationResponse> ActivateAsync(int id, int adminId)
        {
            var reservation = await _context.Reservations.FindAsync(id)
                ?? throw new NotFoundException("Rezervacija", id);

            ReservationStateMachine.ValidateTransition(reservation.Status, ReservationStatus.Active);

            reservation.Status = ReservationStatus.Active;
            reservation.ActivatedById = adminId;
            reservation.ActivatedAt = DateTime.UtcNow;

            await _context.SaveChangesAsync();

            await _notificationService.SendToUserAsync(
                reservation.UserId,
                "Vozilo preuzeto",
                $"Vaša rezervacija #{reservation.Id} je aktivirana. Sretnu vožnju!",
                NotificationType.Reservation);

            return await GetByIdAsync(id);
        }

        public async Task<ReservationResponse> CancelAsync(int id, int userId, string reason, bool isAdmin)
        {
            var reservation = await _context.Reservations
                .Include(x => x.User)
                .FirstOrDefaultAsync(x => x.Id == id)
                ?? throw new NotFoundException("Rezervacija", id);

            if (!isAdmin && reservation.UserId != userId)
                throw new UnauthorizedException("Nemate pravo otkazati ovu rezervaciju.");

            ReservationStateMachine.ValidateTransition(reservation.Status, ReservationStatus.Cancelled);

            if (string.IsNullOrWhiteSpace(reason))
                throw new BusinessException("Razlog otkazivanja je obavezan.");

            reservation.Status = ReservationStatus.Cancelled;
            reservation.CancellationReason = reason;
            reservation.CancelledById = userId;
            reservation.CancelledAt = DateTime.UtcNow;

            await _context.SaveChangesAsync();

            await _notificationService.SendToUserAsync(
                reservation.UserId,
                "Rezervacija otkazana",
                $"Vaša rezervacija #{reservation.Id} je otkazana. Razlog: {reason}",
                NotificationType.Cancellation);

            return await GetByIdAsync(id);
        }

        public async Task<ReservationResponse> CompleteAsync(int id, int adminId)
        {
            var reservation = await _context.Reservations.FindAsync(id)
                ?? throw new NotFoundException("Rezervacija", id);

            ReservationStateMachine.ValidateTransition(reservation.Status, ReservationStatus.Completed);

            reservation.Status = ReservationStatus.Completed;
            reservation.CompletedById = adminId;
            reservation.CompletedAt = DateTime.UtcNow;

            await _context.SaveChangesAsync();

            await _notificationService.SendToUserAsync(
                reservation.UserId,
                "Rezervacija završena",
                $"Vaša rezervacija #{reservation.Id} je uspješno završena. Hvala što koristite eRentaCar!",
                NotificationType.Reservation);

            return await GetByIdAsync(id);
        }

        public async Task<List<OccupiedDateRange>> GetVehicleOccupiedDatesAsync(int vehicleId)
        {
            return await _context.Reservations
                .Where(r => r.VehicleId == vehicleId &&
                            r.Status != ReservationStatus.Cancelled &&
                            r.EndDate >= DateTime.UtcNow.Date)
                .Select(r => new OccupiedDateRange(r.StartDate, r.EndDate))
                .ToListAsync();
        }

        private async Task<Reservation?> GetReservationWithIncludes(int id)
        {
            return await _context.Reservations
                .Include(x => x.User)
                .Include(x => x.Vehicle).ThenInclude(x => x.Brand)
                .Include(x => x.Vehicle).ThenInclude(x => x.Images)
                .Include(x => x.PickupLocation)
                .Include(x => x.DropoffLocation)
                .Include(x => x.ApprovedBy)
                .Include(x => x.CancelledBy)
                .Include(x => x.CompletedBy)
                .Include(x => x.ActivatedBy)
                .Include(x => x.Payment)
                .Include(x => x.Extras).ThenInclude(x => x.ExtraService)
                .FirstOrDefaultAsync(x => x.Id == id);
        }

        private static ReservationResponse MapToResponse(Reservation r) => new()
        {
            Id = r.Id,
            VehicleId = r.VehicleId,
            ClientName = $"{r.User.FirstName} {r.User.LastName}",
            ClientEmail = r.User.Email!,
            Vehicle = $"{r.Vehicle.Brand.Name} {r.Vehicle.Model}",
            LicensePlate = r.Vehicle.LicensePlate,
            PickupLocation = r.PickupLocation.Name,
            DropoffLocation = r.DropoffLocation.Name,
            StartDate = r.StartDate,
            EndDate = r.EndDate,
            TotalDays = r.TotalDays,
            BasePrice = r.BasePrice,
            ExtrasPrice = r.ExtrasPrice,
            TotalPrice = r.TotalPrice,
            Status = r.Status.ToString(),
            CancellationReason = r.CancellationReason,
            CancelledBy = r.CancelledBy != null ? $"{r.CancelledBy.FirstName} {r.CancelledBy.LastName}" : null,
            CancelledAt = r.CancelledAt,
            ApprovedBy = r.ApprovedBy != null ? $"{r.ApprovedBy.FirstName} {r.ApprovedBy.LastName}" : null,
            ApprovedAt = r.ApprovedAt,
            CompletedBy = r.CompletedBy != null ? $"{r.CompletedBy.FirstName} {r.CompletedBy.LastName}" : null,
            CompletedAt = r.CompletedAt,
            CreatedAt = r.CreatedAt,
            IsPaid = r.Payment?.Status == PaymentStatus.Completed,
            VehiclePrimaryImageUrl = r.Vehicle.Images?.FirstOrDefault(i => i.IsPrimary)?.ImageUrl
                ?? r.Vehicle.Images?.FirstOrDefault()?.ImageUrl,
            ActivatedBy = r.ActivatedBy != null ? $"{r.ActivatedBy.FirstName} {r.ActivatedBy.LastName}" : null,
            ActivatedAt = r.ActivatedAt,
            Extras = r.Extras.Select(e => new ReservationExtraResponse
            {
                ServiceName = e.ExtraService.Name,
                Quantity = e.Quantity,
                PriceAtTime = e.PriceAtTime
            }).ToList()
        };
    }
}