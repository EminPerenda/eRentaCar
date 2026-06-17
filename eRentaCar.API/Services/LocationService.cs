using eRentaCar.API.Data;
using eRentaCar.API.DTOs.Location;
using eRentaCar.API.Enums;
using eRentaCar.API.Exceptions;
using eRentaCar.API.Models;
using eRentaCar.API.Services.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace eRentaCar.API.Services
{
    public class LocationService : ILocationService
    {
        private readonly ApplicationDbContext _context;

        public LocationService(ApplicationDbContext context)
        {
            _context = context;
        }

        public async Task<List<LocationResponse>> GetAllAsync()
        {
            var locations = await _context.Locations
                .Include(x => x.City).ThenInclude(x => x.Country)
                .Include(x => x.Vehicles)
                .Where(x => x.IsActive)
                .ToListAsync();

            return locations.Select(MapToResponse).ToList();
        }

        public async Task<LocationResponse> GetByIdAsync(int id)
        {
            var location = await _context.Locations
                .Include(x => x.City).ThenInclude(x => x.Country)
                .Include(x => x.Vehicles)
                .FirstOrDefaultAsync(x => x.Id == id && x.IsActive)
                ?? throw new NotFoundException("Lokacija", id);

            return MapToResponse(location);
        }

        public async Task<LocationResponse> CreateAsync(LocationRequest request)
        {
            var location = new Location
            {
                Name = request.Name,
                Address = request.Address,
                CityId = request.CityId,
                Phone = request.Phone,
                WorkingHours = request.WorkingHours,
                Latitude = request.Latitude,
                Longitude = request.Longitude
            };

            _context.Locations.Add(location);
            await _context.SaveChangesAsync();

            return await GetByIdAsync(location.Id);
        }

        public async Task<LocationResponse> UpdateAsync(int id, LocationRequest request)
        {
            var location = await _context.Locations.FindAsync(id)
                ?? throw new NotFoundException("Lokacija", id);

            location.Name = request.Name;
            location.Address = request.Address;
            location.CityId = request.CityId;
            location.Phone = request.Phone;
            location.WorkingHours = request.WorkingHours;
            location.Latitude = request.Latitude;
            location.Longitude = request.Longitude;

            await _context.SaveChangesAsync();

            return await GetByIdAsync(location.Id);
        }

        public async Task DeleteAsync(int id)
        {
            var location = await _context.Locations.FindAsync(id)
                ?? throw new NotFoundException("Lokacija", id);

            var hasVehicles = await _context.Vehicles
                .AnyAsync(x => x.CurrentLocationId == id && x.IsActive);

            if (hasVehicles)
                throw new BusinessException("Lokacija se ne može obrisati jer ima aktivnih vozila.");

            location.IsActive = false;
            await _context.SaveChangesAsync();
        }

        private static LocationResponse MapToResponse(Location l) => new()
        {
            Id = l.Id,
            Name = l.Name,
            Address = l.Address,
            City = l.City.Name,
            Country = l.City.Country.Name,
            Phone = l.Phone,
            WorkingHours = l.WorkingHours,
            IsActive = l.IsActive,
            Latitude = l.Latitude,
            Longitude = l.Longitude,
            AvailableVehicles = l.Vehicles.Count(x => x.Status == VehicleStatus.Available && x.IsActive),
            RentedVehicles = l.Vehicles.Count(x => x.Status == VehicleStatus.Rented && x.IsActive)
        };
    }
}