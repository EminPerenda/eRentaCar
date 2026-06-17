using eRentaCar.API.Data;
using eRentaCar.API.DTOs.Reports;
using eRentaCar.API.Enums;
using eRentaCar.API.Services.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace eRentaCar.API.Services
{
    public class ReportsService : IReportsService
    {
        private readonly ApplicationDbContext _context;

        public ReportsService(ApplicationDbContext context)
        {
            _context = context;
        }

        public async Task<FinancialReportResponse> GetFinancialAsync(DateTime? from, DateTime? to)
        {
            var fromDate = (from ?? DateTime.UtcNow.AddMonths(-1)).Date;
            var toDate = (to ?? DateTime.UtcNow).Date.AddDays(1);

            var reservations = await _context.Reservations
                .Include(x => x.User)
                .Include(x => x.Vehicle).ThenInclude(x => x.Brand)
                .Include(x => x.PickupLocation)
                .Where(r => r.Status == ReservationStatus.Completed
                         && r.StartDate >= fromDate
                         && r.StartDate < toDate)
                .OrderByDescending(r => r.StartDate)
                .ToListAsync();

            var byLocation = reservations
                .GroupBy(r => r.PickupLocation.Name)
                .Select(g => new LocationRevenueItem
                {
                    Name = g.Key,
                    Revenue = g.Sum(r => r.TotalPrice),
                    Count = g.Count()
                })
                .OrderByDescending(x => x.Revenue)
                .ToList();

            var transactions = reservations.Select(r => new TransactionItem
            {
                Id = r.Id,
                ClientName = $"{r.User.FirstName} {r.User.LastName}",
                Vehicle = $"{r.Vehicle.Brand.Name} {r.Vehicle.Model}",
                PickupLocation = r.PickupLocation.Name,
                StartDate = r.StartDate,
                EndDate = r.EndDate,
                TotalDays = r.TotalDays,
                BasePrice = r.BasePrice,
                ExtrasPrice = r.ExtrasPrice,
                TotalPrice = r.TotalPrice
            }).ToList();

            return new FinancialReportResponse
            {
                TotalRevenue = reservations.Sum(r => r.TotalPrice),
                TransactionCount = reservations.Count,
                ByLocation = byLocation,
                Transactions = transactions
            };
        }

        public async Task<VehicleReportResponse> GetVehiclesAsync(DateTime? from, DateTime? to)
        {
            var fromDate = (from ?? DateTime.UtcNow.AddMonths(-1)).Date;
            var toDate = (to ?? DateTime.UtcNow).Date.AddDays(1);
            var periodDays = Math.Max(1, (int)(toDate - fromDate).TotalDays);

            var reservations = await _context.Reservations
                .Include(x => x.Vehicle).ThenInclude(x => x.Brand)
                .Include(x => x.Vehicle).ThenInclude(x => x.Category)
                .Where(r => r.Status != ReservationStatus.Cancelled
                         && r.EndDate >= fromDate
                         && r.StartDate < toDate)
                .ToListAsync();

            var vehicles = await _context.Vehicles
                .Include(x => x.Brand)
                .Include(x => x.Category)
                .ToListAsync();

            var byVehicle = vehicles.Select(v =>
            {
                var vRes = reservations.Where(r => r.VehicleId == v.Id).ToList();
                var daysRented = vRes.Sum(r => r.TotalDays);
                return new VehicleUtilizationItem
                {
                    Id = v.Id,
                    Vehicle = $"{v.Brand.Name} {v.Model}",
                    Category = v.Category.Name,
                    LicensePlate = v.LicensePlate,
                    DaysRented = daysRented,
                    UtilizationPct = Math.Round((double)daysRented / periodDays * 100, 1),
                    Revenue = vRes.Sum(r => r.TotalPrice),
                    ReservationCount = vRes.Count
                };
            })
            .OrderByDescending(x => x.Revenue)
            .ToList();

            var byCategory = vehicles
                .GroupBy(v => v.Category.Name)
                .Select(g =>
                {
                    var gRes = reservations.Where(r => g.Any(v => v.Id == r.VehicleId)).ToList();
                    return new CategoryRevenueItem
                    {
                        Name = g.Key,
                        VehicleCount = g.Count(),
                        ReservationCount = gRes.Count,
                        Revenue = gRes.Sum(r => r.TotalPrice),
                        AvgDays = gRes.Count > 0 ? Math.Round(gRes.Average(r => r.TotalDays), 1) : 0
                    };
                })
                .OrderByDescending(x => x.Revenue)
                .ToList();

            return new VehicleReportResponse
            {
                PeriodDays = periodDays,
                ByVehicle = byVehicle,
                ByCategory = byCategory
            };
        }

        public async Task<ClientReportResponse> GetClientsAsync(DateTime? from, DateTime? to)
        {
            var fromDate = from?.Date;
            var toDate = to?.Date.AddDays(1);

            var query = _context.Reservations
                .Include(x => x.User)
                .Include(x => x.Vehicle).ThenInclude(x => x.Category)
                .Where(r => r.Status == ReservationStatus.Completed);

            if (fromDate.HasValue) query = query.Where(r => r.StartDate >= fromDate);
            if (toDate.HasValue) query = query.Where(r => r.StartDate < toDate);

            var reservations = await query.ToListAsync();

            var byClient = reservations
                .GroupBy(r => r.UserId)
                .Select(g =>
                {
                    var topCat = g.GroupBy(r => r.Vehicle.Category.Name)
                        .OrderByDescending(x => x.Count())
                        .Select(x => x.Key)
                        .FirstOrDefault() ?? "-";
                    return new ClientActivityItem
                    {
                        Name = $"{g.First().User.FirstName} {g.First().User.LastName}",
                        Email = g.First().User.Email ?? "",
                        ReservationCount = g.Count(),
                        TotalSpent = g.Sum(r => r.TotalPrice),
                        TopCategory = topCat
                    };
                })
                .OrderByDescending(x => x.TotalSpent)
                .ToList();

            return new ClientReportResponse
            {
                TotalClients = byClient.Count,
                TotalRevenue = reservations.Sum(r => r.TotalPrice),
                ByClient = byClient
            };
        }

        public async Task<LocationReportResponse> GetLocationsAsync(DateTime? from, DateTime? to)
        {
            var fromDate = (from ?? DateTime.UtcNow.AddMonths(-1)).Date;
            var toDate = (to ?? DateTime.UtcNow).Date.AddDays(1);

            var reservations = await _context.Reservations
                .Include(x => x.PickupLocation)
                .Include(x => x.DropoffLocation)
                .Include(x => x.Vehicle).ThenInclude(x => x.Brand)
                .Where(r => r.Status != ReservationStatus.Cancelled
                         && r.StartDate >= fromDate
                         && r.StartDate < toDate)
                .ToListAsync();

            var locations = await _context.Locations
                .Include(x => x.City)
                .ToListAsync();

            var byLocation = locations.Select(l =>
            {
                var pickups = reservations.Where(r => r.PickupLocationId == l.Id).ToList();
                var dropoffs = reservations.Where(r => r.DropoffLocationId == l.Id).ToList();
                var topVehicle = pickups
                    .GroupBy(r => $"{r.Vehicle.Brand.Name} {r.Vehicle.Model}")
                    .OrderByDescending(g => g.Count())
                    .Select(g => g.Key)
                    .FirstOrDefault() ?? "-";
                return new LocationActivityItem
                {
                    Name = l.Name,
                    City = l.City?.Name ?? "-",
                    PickupCount = pickups.Count,
                    DropoffCount = dropoffs.Count,
                    Revenue = pickups.Sum(r => r.TotalPrice),
                    TopVehicle = topVehicle
                };
            })
            .OrderByDescending(x => x.PickupCount)
            .ToList();

            return new LocationReportResponse
            {
                ByLocation = byLocation,
                TotalReservations = reservations.Count,
                TotalRevenue = reservations.Sum(r => r.TotalPrice)
            };
        }
    }
}
