using eRentaCar.API.Data;
using eRentaCar.API.DTOs;
using eRentaCar.API.DTOs.Vehicle;
using eRentaCar.API.Enums;
using eRentaCar.API.Exceptions;
using eRentaCar.API.Models;
using eRentaCar.API.Services.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace eRentaCar.API.Services
{
    public class VehicleService : IVehicleService
    {
        private readonly ApplicationDbContext _context;

        public VehicleService(ApplicationDbContext context)
        {
            _context = context;
        }

        public async Task<PagedResponse<VehicleResponse>> GetAllAsync(VehicleFilterRequest filter)
        {
            if (filter.PageSize > 100) filter.PageSize = 100;

            var query = _context.Vehicles
                .Include(x => x.Brand)
                .Include(x => x.Category)
                .Include(x => x.FuelType)
                .Include(x => x.Transmission)
                .Include(x => x.CurrentLocation)
                .ThenInclude(x => x.City)
                .Include(x => x.Images)
                .Include(x => x.Reviews)
                .Where(x => x.IsActive)
                .AsQueryable();

            if (!filter.IncludeUnavailable)
                query = query.Where(x => x.Status == VehicleStatus.Available);

            if (!string.IsNullOrEmpty(filter.Search))
                query = query.Where(x =>
                    x.LicensePlate.Contains(filter.Search) ||
                    x.Model.Contains(filter.Search) ||
                    x.Brand.Name.Contains(filter.Search));

            if (filter.CategoryId.HasValue)
                query = query.Where(x => x.CategoryId == filter.CategoryId);

            if (filter.BrandId.HasValue)
                query = query.Where(x => x.BrandId == filter.BrandId);

            if (filter.FuelTypeId.HasValue)
                query = query.Where(x => x.FuelTypeId == filter.FuelTypeId);

            if (filter.TransmissionId.HasValue)
                query = query.Where(x => x.TransmissionId == filter.TransmissionId);

            if (filter.Seats.HasValue)
                query = query.Where(x => x.Seats == filter.Seats);

            if (filter.MinPrice.HasValue)
                query = query.Where(x => x.PricePerDay >= filter.MinPrice);

            if (filter.MaxPrice.HasValue)
                query = query.Where(x => x.PricePerDay <= filter.MaxPrice);

            if (filter.LocationId.HasValue)
                query = query.Where(x => x.CurrentLocationId == filter.LocationId);

            if (filter.CityId.HasValue)
                query = query.Where(x => x.CurrentLocation.CityId == filter.CityId);

            if (filter.StartDate.HasValue && filter.EndDate.HasValue)
                query = query.Where(x => !x.Reservations.Any(r =>
                    r.Status != ReservationStatus.Cancelled &&
                    r.StartDate < filter.EndDate &&
                    r.EndDate > filter.StartDate));

            query = filter.SortBy switch
            {
                "price_asc" => query.OrderBy(x => x.PricePerDay),
                "price_desc" => query.OrderByDescending(x => x.PricePerDay),
                "rating" => query.OrderByDescending(x => x.Reviews.Average(r => (double?)r.Rating) ?? 0),
                _ => query.OrderByDescending(x => x.Id)
            };

            var totalCount = await query.CountAsync();

            var items = await query
                .Skip((filter.Page - 1) * filter.PageSize)
                .Take(filter.PageSize)
                .ToListAsync();

            return new PagedResponse<VehicleResponse>
            {
                Items = items.Select(MapToResponse).ToList(),
                TotalCount = totalCount,
                Page = filter.Page,
                PageSize = filter.PageSize
            };
        }

        public async Task<VehicleResponse> GetByIdAsync(int id)
        {
            var vehicle = await _context.Vehicles
                .Include(x => x.Brand)
                .Include(x => x.Category)
                .Include(x => x.FuelType)
                .Include(x => x.Transmission)
                .Include(x => x.CurrentLocation)
                .Include(x => x.Images)
                .Include(x => x.Reviews)
                .FirstOrDefaultAsync(x => x.Id == id && x.IsActive)
                ?? throw new NotFoundException("Vozilo", id);

            return MapToResponse(vehicle);
        }

        public async Task<VehicleResponse> CreateAsync(VehicleRequest request)
        {
            await ValidateVehicleRequestAsync(request);

            if (await _context.Vehicles.AnyAsync(x => x.LicensePlate == request.LicensePlate))
                throw new BusinessException($"Vozilo s registarskom oznakom {request.LicensePlate} već postoji.");

            var vehicle = new Vehicle
            {
                LicensePlate = request.LicensePlate,
                BrandId = request.BrandId,
                Model = request.Model,
                Year = request.Year,
                CategoryId = request.CategoryId,
                FuelTypeId = request.FuelTypeId,
                TransmissionId = request.TransmissionId,
                Seats = request.Seats,
                PricePerDay = request.PricePerDay,
                Mileage = request.Mileage,
                Description = request.Description,
                CurrentLocationId = request.CurrentLocationId
            };

            _context.Vehicles.Add(vehicle);
            await _context.SaveChangesAsync();

            return await GetByIdAsync(vehicle.Id);
        }

        public async Task<VehicleResponse> UpdateAsync(int id, VehicleRequest request)
        {
            var vehicle = await _context.Vehicles.FindAsync(id)
                ?? throw new NotFoundException("Vozilo", id);

            await ValidateVehicleRequestAsync(request);

            if (await _context.Vehicles.AnyAsync(x => x.LicensePlate == request.LicensePlate && x.Id != id))
                throw new BusinessException($"Vozilo s registarskom oznakom {request.LicensePlate} već postoji.");

            vehicle.LicensePlate = request.LicensePlate;
            vehicle.BrandId = request.BrandId;
            vehicle.Model = request.Model;
            vehicle.Year = request.Year;
            vehicle.CategoryId = request.CategoryId;
            vehicle.FuelTypeId = request.FuelTypeId;
            vehicle.TransmissionId = request.TransmissionId;
            vehicle.Seats = request.Seats;
            vehicle.PricePerDay = request.PricePerDay;
            vehicle.Mileage = request.Mileage;
            vehicle.Description = request.Description;
            vehicle.CurrentLocationId = request.CurrentLocationId;

            await _context.SaveChangesAsync();

            return await GetByIdAsync(vehicle.Id);
        }

        private async Task ValidateVehicleRequestAsync(VehicleRequest request)
        {
            if (string.IsNullOrWhiteSpace(request.LicensePlate))
                throw new BusinessException("Registarska oznaka je obavezna.");

            if (string.IsNullOrWhiteSpace(request.Model))
                throw new BusinessException("Model vozila je obavezan.");

            if (request.PricePerDay <= 0)
                throw new BusinessException("Cijena po danu mora biti veća od nule.");

            if (request.Seats <= 0)
                throw new BusinessException("Broj sjedišta mora biti veći od nule.");

            if (request.Mileage < 0)
                throw new BusinessException("Kilometraža ne može biti negativna.");

            var currentYear = DateTime.UtcNow.Year;
            if (request.Year < 1950 || request.Year > currentYear + 1)
                throw new BusinessException("Godina vozila nije u realnom rasponu.");

            await EnsureExistsAsync(_context.VehicleBrands, request.BrandId, "Proizvođač vozila ne postoji.");
            await EnsureActiveCategoryAsync(request.CategoryId);
            await EnsureExistsAsync(_context.FuelTypes, request.FuelTypeId, "Vrsta goriva ne postoji.");
            await EnsureExistsAsync(_context.Transmissions, request.TransmissionId, "Mjenjač ne postoji.");
            await EnsureActiveLocationAsync(request.CurrentLocationId);
        }

        private async Task EnsureExistsAsync<TEntity>(DbSet<TEntity> set, int id, string message)
            where TEntity : class
        {
            var exists = await set.AnyAsync(x => EF.Property<int>(x, "Id") == id);
            if (!exists)
                throw new BusinessException(message);
        }

        private async Task EnsureActiveCategoryAsync(int categoryId)
        {
            var category = await _context.VehicleCategories.FindAsync(categoryId)
                ?? throw new BusinessException("Kategorija vozila ne postoji.");

            if (!category.IsActive)
                throw new BusinessException("Kategorija vozila nije aktivna.");
        }

        private async Task EnsureActiveLocationAsync(int locationId)
        {
            var location = await _context.Locations.FindAsync(locationId)
                ?? throw new BusinessException("Lokacija ne postoji.");

            if (!location.IsActive)
                throw new BusinessException("Lokacija nije aktivna.");
        }

        public async Task DeleteAsync(int id)
        {
            var vehicle = await _context.Vehicles.FindAsync(id)
                ?? throw new NotFoundException("Vozilo", id);

            var hasActiveReservations = await _context.Reservations.AnyAsync(x =>
                x.VehicleId == id &&
                (x.Status == ReservationStatus.Pending ||
                 x.Status == ReservationStatus.Confirmed ||
                 x.Status == ReservationStatus.Active));

            if (hasActiveReservations)
                throw new BusinessException("Vozilo se ne može obrisati jer ima aktivnih ili budućih rezervacija.");

            vehicle.IsActive = false;
            await _context.SaveChangesAsync();
        }

        public async Task UpdateStatusAsync(int id, int status)
        {
            var vehicle = await _context.Vehicles.FindAsync(id)
                ?? throw new NotFoundException("Vozilo", id);

            if (!Enum.IsDefined(typeof(VehicleStatus), status))
                throw new BusinessException("Nevažeći status vozila.");

            vehicle.Status = (VehicleStatus)status;
            await _context.SaveChangesAsync();
        }

        public async Task<List<VehicleReservationHistoryResponse>> GetReservationHistoryAsync(int vehicleId)
        {
            var exists = await _context.Vehicles.AnyAsync(x => x.Id == vehicleId);
            if (!exists)
                throw new NotFoundException("Vozilo", vehicleId);

            return await _context.Reservations
                .Include(x => x.User)
                .Where(x => x.VehicleId == vehicleId)
                .OrderByDescending(x => x.CreatedAt)
                .Select(x => new VehicleReservationHistoryResponse
                {
                    Id = x.Id,
                    ClientName = $"{x.User.FirstName} {x.User.LastName}",
                    ClientEmail = x.User.Email!,
                    StartDate = x.StartDate,
                    EndDate = x.EndDate,
                    Status = x.Status.ToString(),
                    TotalPrice = x.TotalPrice,
                    CancellationReason = x.CancellationReason,
                    CreatedAt = x.CreatedAt
                })
                .ToListAsync();
        }

        private static VehicleResponse MapToResponse(Vehicle v) => new()
        {
            Id = v.Id,
            LicensePlate = v.LicensePlate,
            Brand = v.Brand.Name,
            Model = v.Model,
            Year = v.Year,
            Category = v.Category.Name,
            CategoryId = v.CategoryId,
            FuelType = v.FuelType.Name,
            Transmission = v.Transmission.Name,
            Seats = v.Seats,
            PricePerDay = v.PricePerDay,
            Mileage = v.Mileage,
            Description = v.Description,
            Status = v.Status.ToString(),
            CurrentLocation = v.CurrentLocation.Name,
            AverageRating = v.Reviews.Any() ? Math.Round(v.Reviews.Average(r => r.Rating), 1) : 0,
            ReviewCount = v.Reviews.Count,
            PrimaryImageUrl = v.Images.FirstOrDefault(x => x.IsPrimary)?.ImageUrl
                              ?? v.Images.FirstOrDefault()?.ImageUrl
        };
    }
}