using eRentaCar.API.Data;
using eRentaCar.API.DTOs.Reference;
using eRentaCar.API.Exceptions;
using eRentaCar.API.Models;
using eRentaCar.API.Services.Interfaces;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Caching.Memory;

namespace eRentaCar.API.Services
{
    public class ReferenceService : IReferenceService
    {
        private readonly ApplicationDbContext _context;
        private readonly IMemoryCache _cache;
        private static readonly TimeSpan CacheDuration = TimeSpan.FromMinutes(10);

        public ReferenceService(ApplicationDbContext context, IMemoryCache cache)
        {
            _context = context;
            _cache = cache;
        }

        // ---------- Categories ----------
        public async Task<List<CategoryResponse>> GetCategoriesAsync()
            => await _cache.GetOrCreateAsync("ref_categories", async entry =>
            {
                entry.SlidingExpiration = CacheDuration;
                return await _context.VehicleCategories
                    .Where(x => x.IsActive)
                    .Select(x => new CategoryResponse { Id = x.Id, Name = x.Name, Description = x.Description })
                    .ToListAsync();
            }) ?? [];

        public async Task<ReferenceItemResponse> CreateCategoryAsync(string name, string? description)
        {
            var item = new VehicleCategory { Name = name, Description = description };
            _context.VehicleCategories.Add(item);
            await _context.SaveChangesAsync();
            _cache.Remove("ref_categories");
            return new ReferenceItemResponse { Id = item.Id, Name = item.Name };
        }

        public async Task<ReferenceItemResponse> UpdateCategoryAsync(int id, string name, string? description)
        {
            var item = await _context.VehicleCategories.FindAsync(id)
                ?? throw new NotFoundException("Kategorija", id);
            item.Name = name;
            item.Description = description;
            await _context.SaveChangesAsync();
            _cache.Remove("ref_categories");
            return new ReferenceItemResponse { Id = item.Id, Name = item.Name };
        }

        public async Task DeleteCategoryAsync(int id)
        {
            var item = await _context.VehicleCategories.FindAsync(id)
                ?? throw new NotFoundException("Kategorija", id);
            if (await _context.Vehicles.AnyAsync(x => x.CategoryId == id))
                throw new BusinessException("Kategorija se koristi i ne može biti obrisana.");
            _context.VehicleCategories.Remove(item);
            await _context.SaveChangesAsync();
            _cache.Remove("ref_categories");
        }

        // ---------- Brands ----------
        public async Task<List<ReferenceItemResponse>> GetBrandsAsync()
            => await _cache.GetOrCreateAsync("ref_brands", async entry =>
            {
                entry.SlidingExpiration = CacheDuration;
                return await _context.VehicleBrands
                    .OrderBy(x => x.Name)
                    .Select(x => new ReferenceItemResponse { Id = x.Id, Name = x.Name })
                    .ToListAsync();
            }) ?? [];

        public async Task<ReferenceItemResponse> CreateBrandAsync(string name)
        {
            var item = new VehicleBrand { Name = name };
            _context.VehicleBrands.Add(item);
            await _context.SaveChangesAsync();
            _cache.Remove("ref_brands");
            return new ReferenceItemResponse { Id = item.Id, Name = item.Name };
        }

        public async Task<ReferenceItemResponse> UpdateBrandAsync(int id, string name)
        {
            var item = await _context.VehicleBrands.FindAsync(id)
                ?? throw new NotFoundException("Marka", id);
            item.Name = name;
            await _context.SaveChangesAsync();
            _cache.Remove("ref_brands");
            return new ReferenceItemResponse { Id = item.Id, Name = item.Name };
        }

        public async Task DeleteBrandAsync(int id)
        {
            var item = await _context.VehicleBrands.FindAsync(id)
                ?? throw new NotFoundException("Marka", id);
            if (await _context.Vehicles.AnyAsync(x => x.BrandId == id))
                throw new BusinessException("Marka se koristi i ne može biti obrisana.");
            _context.VehicleBrands.Remove(item);
            await _context.SaveChangesAsync();
            _cache.Remove("ref_brands");
        }

        // ---------- FuelTypes ----------
        public async Task<List<ReferenceItemResponse>> GetFuelTypesAsync()
            => await _cache.GetOrCreateAsync("ref_fueltypes", async entry =>
            {
                entry.SlidingExpiration = CacheDuration;
                return await _context.FuelTypes
                    .Select(x => new ReferenceItemResponse { Id = x.Id, Name = x.Name })
                    .ToListAsync();
            }) ?? [];

        public async Task<ReferenceItemResponse> CreateFuelTypeAsync(string name)
        {
            var item = new FuelType { Name = name };
            _context.FuelTypes.Add(item);
            await _context.SaveChangesAsync();
            _cache.Remove("ref_fueltypes");
            return new ReferenceItemResponse { Id = item.Id, Name = item.Name };
        }

        public async Task<ReferenceItemResponse> UpdateFuelTypeAsync(int id, string name)
        {
            var item = await _context.FuelTypes.FindAsync(id)
                ?? throw new NotFoundException("Tip goriva", id);
            item.Name = name;
            await _context.SaveChangesAsync();
            _cache.Remove("ref_fueltypes");
            return new ReferenceItemResponse { Id = item.Id, Name = item.Name };
        }

        public async Task DeleteFuelTypeAsync(int id)
        {
            var item = await _context.FuelTypes.FindAsync(id)
                ?? throw new NotFoundException("Tip goriva", id);
            if (await _context.Vehicles.AnyAsync(x => x.FuelTypeId == id))
                throw new BusinessException("Tip goriva se koristi i ne može biti obrisan.");
            _context.FuelTypes.Remove(item);
            await _context.SaveChangesAsync();
            _cache.Remove("ref_fueltypes");
        }

        // ---------- Transmissions ----------
        public async Task<List<ReferenceItemResponse>> GetTransmissionsAsync()
            => await _cache.GetOrCreateAsync("ref_transmissions", async entry =>
            {
                entry.SlidingExpiration = CacheDuration;
                return await _context.Transmissions
                    .Select(x => new ReferenceItemResponse { Id = x.Id, Name = x.Name })
                    .ToListAsync();
            }) ?? [];

        public async Task<ReferenceItemResponse> CreateTransmissionAsync(string name)
        {
            var item = new Transmission { Name = name };
            _context.Transmissions.Add(item);
            await _context.SaveChangesAsync();
            _cache.Remove("ref_transmissions");
            return new ReferenceItemResponse { Id = item.Id, Name = item.Name };
        }

        public async Task<ReferenceItemResponse> UpdateTransmissionAsync(int id, string name)
        {
            var item = await _context.Transmissions.FindAsync(id)
                ?? throw new NotFoundException("Tip mjenjača", id);
            item.Name = name;
            await _context.SaveChangesAsync();
            _cache.Remove("ref_transmissions");
            return new ReferenceItemResponse { Id = item.Id, Name = item.Name };
        }

        public async Task DeleteTransmissionAsync(int id)
        {
            var item = await _context.Transmissions.FindAsync(id)
                ?? throw new NotFoundException("Tip mjenjača", id);
            if (await _context.Vehicles.AnyAsync(x => x.TransmissionId == id))
                throw new BusinessException("Tip mjenjača se koristi i ne može biti obrisan.");
            _context.Transmissions.Remove(item);
            await _context.SaveChangesAsync();
            _cache.Remove("ref_transmissions");
        }

        // ---------- Cities ----------
        public async Task<List<CityResponse>> GetCitiesAsync()
            => await _cache.GetOrCreateAsync("ref_cities", async entry =>
            {
                entry.SlidingExpiration = CacheDuration;
                return await _context.Cities
                    .Include(x => x.Country)
                    .OrderBy(x => x.Name)
                    .Select(x => new CityResponse { Id = x.Id, Name = x.Name, Country = x.Country.Name })
                    .ToListAsync();
            }) ?? [];

        public async Task<ReferenceItemResponse> CreateCityAsync(string name, int countryId)
        {
            var item = new City { Name = name, CountryId = countryId };
            _context.Cities.Add(item);
            await _context.SaveChangesAsync();
            _cache.Remove("ref_cities");
            return new ReferenceItemResponse { Id = item.Id, Name = item.Name };
        }

        public async Task<ReferenceItemResponse> UpdateCityAsync(int id, string name, int countryId)
        {
            var item = await _context.Cities.FindAsync(id)
                ?? throw new NotFoundException("Grad", id);
            item.Name = name;
            item.CountryId = countryId;
            await _context.SaveChangesAsync();
            _cache.Remove("ref_cities");
            return new ReferenceItemResponse { Id = item.Id, Name = item.Name };
        }

        public async Task DeleteCityAsync(int id)
        {
            var item = await _context.Cities.FindAsync(id)
                ?? throw new NotFoundException("Grad", id);
            var inUse = await _context.Users.AnyAsync(x => x.CityId == id)
                     || await _context.Locations.AnyAsync(x => x.CityId == id);
            if (inUse)
                throw new BusinessException("Grad se koristi i ne može biti obrisan.");
            _context.Cities.Remove(item);
            await _context.SaveChangesAsync();
            _cache.Remove("ref_cities");
        }

        // ---------- Countries ----------
        public async Task<List<CountryResponse>> GetCountriesAsync()
            => await _cache.GetOrCreateAsync("ref_countries", async entry =>
            {
                entry.SlidingExpiration = CacheDuration;
                return await _context.Countries
                    .OrderBy(x => x.Name)
                    .Select(x => new CountryResponse { Id = x.Id, Name = x.Name, Code = x.Code })
                    .ToListAsync();
            }) ?? [];

        public async Task<CountryResponse> CreateCountryAsync(string name, string code)
        {
            var item = new Country { Name = name, Code = code };
            _context.Countries.Add(item);
            await _context.SaveChangesAsync();
            _cache.Remove("ref_countries");
            return new CountryResponse { Id = item.Id, Name = item.Name, Code = item.Code };
        }

        public async Task<CountryResponse> UpdateCountryAsync(int id, string name, string code)
        {
            var item = await _context.Countries.FindAsync(id)
                ?? throw new NotFoundException("Država", id);
            item.Name = name;
            item.Code = code;
            await _context.SaveChangesAsync();
            _cache.Remove("ref_countries");
            return new CountryResponse { Id = item.Id, Name = item.Name, Code = item.Code };
        }

        public async Task DeleteCountryAsync(int id)
        {
            var item = await _context.Countries.FindAsync(id)
                ?? throw new NotFoundException("Država", id);
            if (await _context.Cities.AnyAsync(x => x.CountryId == id))
                throw new BusinessException("Država se koristi i ne može biti obrisana.");
            _context.Countries.Remove(item);
            await _context.SaveChangesAsync();
            _cache.Remove("ref_countries");
        }

        // ---------- ExtraServices ----------
        public async Task<List<ExtraServiceResponse>> GetExtraServicesAsync(bool all)
        {
            var key = all ? "ref_extraservices_all" : "ref_extraservices";
            return await _cache.GetOrCreateAsync(key, async entry =>
            {
                entry.SlidingExpiration = CacheDuration;
                var query = _context.ExtraServices.OrderBy(x => x.Name);
                return await (all ? query : query.Where(x => x.IsAvailable))
                    .Select(x => new ExtraServiceResponse
                    {
                        Id = x.Id,
                        Name = x.Name,
                        Description = x.Description,
                        PricePerDay = x.PricePerDay,
                        IsAvailable = x.IsAvailable
                    })
                    .ToListAsync();
            }) ?? [];
        }

        public async Task<ExtraServiceResponse> CreateExtraServiceAsync(string name, string? description, decimal pricePerDay, bool isAvailable)
        {
            var item = new ExtraService { Name = name, Description = description, PricePerDay = pricePerDay, IsAvailable = isAvailable };
            _context.ExtraServices.Add(item);
            await _context.SaveChangesAsync();
            _cache.Remove("ref_extraservices");
            _cache.Remove("ref_extraservices_all");
            return new ExtraServiceResponse { Id = item.Id, Name = item.Name, Description = item.Description, PricePerDay = item.PricePerDay, IsAvailable = item.IsAvailable };
        }

        public async Task<ExtraServiceResponse> UpdateExtraServiceAsync(int id, string name, string? description, decimal pricePerDay, bool isAvailable)
        {
            var item = await _context.ExtraServices.FindAsync(id)
                ?? throw new NotFoundException("Usluga", id);
            item.Name = name;
            item.Description = description;
            item.PricePerDay = pricePerDay;
            item.IsAvailable = isAvailable;
            await _context.SaveChangesAsync();
            _cache.Remove("ref_extraservices");
            _cache.Remove("ref_extraservices_all");
            return new ExtraServiceResponse { Id = item.Id, Name = item.Name, Description = item.Description, PricePerDay = item.PricePerDay, IsAvailable = item.IsAvailable };
        }

        public async Task DeleteExtraServiceAsync(int id)
        {
            var item = await _context.ExtraServices.FindAsync(id)
                ?? throw new NotFoundException("Usluga", id);
            if (await _context.ReservationExtras.AnyAsync(x => x.ExtraServiceId == id))
                throw new BusinessException("Usluga se koristi u rezervacijama i ne može biti obrisana.");
            _context.ExtraServices.Remove(item);
            await _context.SaveChangesAsync();
            _cache.Remove("ref_extraservices");
            _cache.Remove("ref_extraservices_all");
        }
    }
}
