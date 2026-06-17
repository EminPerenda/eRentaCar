using eRentaCar.API.Data;
using eRentaCar.API.DTOs.Vehicle;
using eRentaCar.API.Exceptions;
using eRentaCar.API.Models;
using eRentaCar.API.Services.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace eRentaCar.API.Services
{
    public class VehicleImageService : IVehicleImageService
    {
        private readonly ApplicationDbContext _context;
        private readonly IWebHostEnvironment _env;

        public VehicleImageService(ApplicationDbContext context, IWebHostEnvironment env)
        {
            _context = context;
            _env = env;
        }

        public async Task<List<VehicleImageResponse>> GetAllAsync(int vehicleId)
        {
            await EnsureVehicleExists(vehicleId);

            return await _context.VehicleImages
                .Where(x => x.VehicleId == vehicleId)
                .OrderByDescending(x => x.IsPrimary)
                .ThenBy(x => x.UploadedAt)
                .Select(x => new VehicleImageResponse
                {
                    Id = x.Id,
                    VehicleId = x.VehicleId,
                    ImageUrl = x.ImageUrl,
                    IsPrimary = x.IsPrimary,
                    UploadedAt = x.UploadedAt
                })
                .ToListAsync();
        }

        public async Task<VehicleImageResponse> UploadAsync(int vehicleId, string imageUrl, bool isPrimary)
        {
            await EnsureVehicleExists(vehicleId);

            if (isPrimary)
            {
                await ClearPrimary(vehicleId);
            }

            var hasPrimary = await _context.VehicleImages.AnyAsync(x => x.VehicleId == vehicleId && x.IsPrimary);
            var image = new VehicleImage
            {
                VehicleId = vehicleId,
                ImageUrl = imageUrl,
                IsPrimary = isPrimary || !hasPrimary
            };

            if (image.IsPrimary)
                await ClearPrimary(vehicleId);

            _context.VehicleImages.Add(image);
            await _context.SaveChangesAsync();

            return new VehicleImageResponse
            {
                Id = image.Id,
                VehicleId = image.VehicleId,
                ImageUrl = image.ImageUrl,
                IsPrimary = image.IsPrimary,
                UploadedAt = image.UploadedAt
            };
        }

        public async Task SetPrimaryAsync(int vehicleId, int imageId)
        {
            var image = await GetVehicleImage(vehicleId, imageId);
            await ClearPrimary(vehicleId);
            image.IsPrimary = true;
            await _context.SaveChangesAsync();
        }

        public async Task<string> DeleteAsync(int vehicleId, int imageId)
        {
            var image = await GetVehicleImage(vehicleId, imageId);
            var imageUrl = image.ImageUrl;

            _context.VehicleImages.Remove(image);
            await _context.SaveChangesAsync();

            // Delete physical file
            var relative = imageUrl.TrimStart('/').Replace('/', Path.DirectorySeparatorChar);
            var physicalPath = Path.Combine(_env.WebRootPath, relative);
            if (File.Exists(physicalPath))
                File.Delete(physicalPath);

            var remaining = await _context.VehicleImages
                .Where(x => x.VehicleId == vehicleId)
                .OrderByDescending(x => x.UploadedAt)
                .FirstOrDefaultAsync();

            if (remaining != null && !await _context.VehicleImages.AnyAsync(x => x.VehicleId == vehicleId && x.IsPrimary))
            {
                remaining.IsPrimary = true;
                await _context.SaveChangesAsync();
            }

            return imageUrl;
        }

        private async Task EnsureVehicleExists(int vehicleId)
        {
            var exists = await _context.Vehicles.AnyAsync(x => x.Id == vehicleId && x.IsActive);
            if (!exists)
                throw new NotFoundException("Vozilo", vehicleId);
        }

        private async Task<VehicleImage> GetVehicleImage(int vehicleId, int imageId)
        {
            return await _context.VehicleImages
                .FirstOrDefaultAsync(x => x.VehicleId == vehicleId && x.Id == imageId)
                ?? throw new NotFoundException("Slika vozila", imageId);
        }

        private async Task ClearPrimary(int vehicleId)
        {
            var primaryImages = await _context.VehicleImages
                .Where(x => x.VehicleId == vehicleId && x.IsPrimary)
                .ToListAsync();

            foreach (var img in primaryImages)
                img.IsPrimary = false;

            if (primaryImages.Count > 0)
                await _context.SaveChangesAsync();
        }
    }
}
