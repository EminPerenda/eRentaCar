using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace eRentaCar.API.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    public class UploadController : ControllerBase
    {
        private readonly IWebHostEnvironment _env;

        public UploadController(IWebHostEnvironment env)
        {
            _env = env;
        }

        [HttpPost("profile-image")]
        public async Task<IActionResult> UploadProfileImage(IFormFile file)
        {
            if (file == null || file.Length == 0)
                return BadRequest(new { message = "Fajl nije odabran." });

            var allowed = new[] { ".jpg", ".jpeg", ".png", ".webp" };
            var ext = Path.GetExtension(file.FileName).ToLowerInvariant();
            if (!allowed.Contains(ext))
                return BadRequest(new { message = "Dozvoljeni formati: jpg, jpeg, png, webp." });

            if (file.Length > 5 * 1024 * 1024)
                return BadRequest(new { message = "Maksimalna veličina fajla je 5MB." });

            using var ms = new MemoryStream();
            await file.CopyToAsync(ms);
            var bytes = ms.ToArray();

            if (!IsAllowedImageMagicBytes(bytes, file.ContentType))
                return BadRequest(new { message = "Sadržaj fajla ne odgovara odabranom formatu slike." });

            var fileName = $"{Guid.NewGuid()}{ext}";
            var folder = Path.Combine(_env.WebRootPath, "images", "profiles");
            Directory.CreateDirectory(folder);
            var filePath = Path.Combine(folder, fileName);

            await System.IO.File.WriteAllBytesAsync(filePath, bytes);

            var url = $"/images/profiles/{fileName}";
            return Ok(new { url });
        }

        private static bool IsAllowedImageMagicBytes(byte[] bytes, string contentType)
        {
            if (bytes.Length < 12) return false;

            // JPEG: FF D8 FF
            if (bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF)
                return contentType is "image/jpeg";

            // PNG: 89 50 4E 47 0D 0A 1A 0A
            if (bytes[0] == 0x89 && bytes[1] == 0x50 && bytes[2] == 0x4E && bytes[3] == 0x47)
                return contentType is "image/png";

            // WebP: RIFF????WEBP
            if (bytes[0] == 0x52 && bytes[1] == 0x49 && bytes[2] == 0x46 && bytes[3] == 0x46 &&
                bytes[8] == 0x57 && bytes[9] == 0x45 && bytes[10] == 0x42 && bytes[11] == 0x50)
                return contentType is "image/webp";

            return false;
        }
    }
}