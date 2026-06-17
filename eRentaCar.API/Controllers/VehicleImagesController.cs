using eRentaCar.API.Constants;
using eRentaCar.API.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace eRentaCar.API.Controllers
{
    [ApiController]
    [Route("api/vehicles/{vehicleId:int}/images")]
    [Authorize(Roles = AppRoles.Admin)]
    public class VehicleImagesController : ControllerBase
    {
        private readonly IVehicleImageService _vehicleImageService;
        private readonly IWebHostEnvironment _env;

        public VehicleImagesController(IVehicleImageService vehicleImageService, IWebHostEnvironment env)
        {
            _vehicleImageService = vehicleImageService;
            _env = env;
        }

        [HttpGet]
        [AllowAnonymous]
        public async Task<IActionResult> GetAll(int vehicleId)
        {
            var images = await _vehicleImageService.GetAllAsync(vehicleId);
            return Ok(images);
        }

        [HttpPost]
        [RequestSizeLimit(10 * 1024 * 1024)]
        public async Task<IActionResult> Upload(int vehicleId, [FromForm] IFormFile file, [FromForm] bool isPrimary = false)
        {
            if (file == null || file.Length == 0)
                return BadRequest(new { message = "Fajl nije odabran." });

            var allowed = new[] { ".jpg", ".jpeg", ".png", ".webp" };
            var ext = Path.GetExtension(file.FileName).ToLowerInvariant();
            if (!allowed.Contains(ext))
                return BadRequest(new { message = "Dozvoljeni formati: jpg, jpeg, png, webp." });

            if (file.Length > 10 * 1024 * 1024)
                return BadRequest(new { message = "Maksimalna veličina fajla je 10MB." });

            using var ms = new MemoryStream();
            await file.CopyToAsync(ms);
            var bytes = ms.ToArray();

            if (!IsAllowedImageMagicBytes(bytes, file.ContentType))
                return BadRequest(new { message = "Sadržaj fajla ne odgovara odabranom formatu slike." });

            var folder = Path.Combine(_env.WebRootPath, "images", "vehicles", vehicleId.ToString());
            Directory.CreateDirectory(folder);

            var fileName = $"{Guid.NewGuid()}{ext}";
            var filePath = Path.Combine(folder, fileName);

            await System.IO.File.WriteAllBytesAsync(filePath, bytes);

            var imageUrl = $"/images/vehicles/{vehicleId}/{fileName}";
            var result = await _vehicleImageService.UploadAsync(vehicleId, imageUrl, isPrimary);
            return Ok(result);
        }

        private static bool IsAllowedImageMagicBytes(byte[] bytes, string contentType)
        {
            if (bytes.Length < 12) return false;

            // JPEG: FF D8 FF
            if (bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF)
                return contentType is "image/jpeg";

            // PNG: 89 50 4E 47
            if (bytes[0] == 0x89 && bytes[1] == 0x50 && bytes[2] == 0x4E && bytes[3] == 0x47)
                return contentType is "image/png";

            // WebP: RIFF????WEBP
            if (bytes[0] == 0x52 && bytes[1] == 0x49 && bytes[2] == 0x46 && bytes[3] == 0x46 &&
                bytes[8] == 0x57 && bytes[9] == 0x45 && bytes[10] == 0x42 && bytes[11] == 0x50)
                return contentType is "image/webp";

            return false;
        }

        [HttpPatch("{imageId:int}/primary")]
        public async Task<IActionResult> SetPrimary(int vehicleId, int imageId)
        {
            await _vehicleImageService.SetPrimaryAsync(vehicleId, imageId);
            return NoContent();
        }

        [HttpDelete("{imageId:int}")]
        public async Task<IActionResult> Delete(int vehicleId, int imageId)
        {
            await _vehicleImageService.DeleteAsync(vehicleId, imageId);
            return NoContent();
        }
    }
}
