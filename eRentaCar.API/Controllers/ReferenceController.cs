using eRentaCar.API.Constants;
using eRentaCar.API.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace eRentaCar.API.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class ReferenceController : ControllerBase
    {
        private readonly IReferenceService _referenceService;

        public ReferenceController(IReferenceService referenceService)
        {
            _referenceService = referenceService;
        }

        [HttpGet("categories")]
        [AllowAnonymous]
        public async Task<IActionResult> GetCategories()
        {
            var data = await _referenceService.GetCategoriesAsync();
            return Ok(data);
        }

        [HttpGet("brands")]
        [AllowAnonymous]
        public async Task<IActionResult> GetBrands()
        {
            var data = await _referenceService.GetBrandsAsync();
            return Ok(data);
        }

        [HttpGet("fueltypes")]
        [AllowAnonymous]
        public async Task<IActionResult> GetFuelTypes()
        {
            var data = await _referenceService.GetFuelTypesAsync();
            return Ok(data);
        }

        [HttpGet("transmissions")]
        [AllowAnonymous]
        public async Task<IActionResult> GetTransmissions()
        {
            var data = await _referenceService.GetTransmissionsAsync();
            return Ok(data);
        }

        [HttpGet("cities")]
        [AllowAnonymous]
        public async Task<IActionResult> GetCities()
        {
            var data = await _referenceService.GetCitiesAsync();
            return Ok(data);
        }

        [HttpGet("countries")]
        [AllowAnonymous]
        public async Task<IActionResult> GetCountries()
        {
            var data = await _referenceService.GetCountriesAsync();
            return Ok(data);
        }

        [HttpGet("extraservices")]
        [AllowAnonymous]
        public async Task<IActionResult> GetExtraServices()
        {
            var data = await _referenceService.GetExtraServicesAsync(all: false);
            return Ok(data);
        }

        // ---------- Categories ----------
        [HttpPost("categories")]
        [Authorize(Roles = AppRoles.Admin)]
        public async Task<IActionResult> CreateCategory([FromBody] CategoryRequest request)
        {
            var result = await _referenceService.CreateCategoryAsync(request.Name, request.Description);
            return Ok(result);
        }

        [HttpPut("categories/{id}")]
        [Authorize(Roles = AppRoles.Admin)]
        public async Task<IActionResult> UpdateCategory(int id, [FromBody] CategoryRequest request)
        {
            var result = await _referenceService.UpdateCategoryAsync(id, request.Name, request.Description);
            return Ok(result);
        }

        [HttpDelete("categories/{id}")]
        [Authorize(Roles = AppRoles.Admin)]
        public async Task<IActionResult> DeleteCategory(int id)
        {
            await _referenceService.DeleteCategoryAsync(id);
            return NoContent();
        }

        // ---------- Brands ----------
        [HttpPost("brands")]
        [Authorize(Roles = AppRoles.Admin)]
        public async Task<IActionResult> CreateBrand([FromBody] NameRequest request)
        {
            var result = await _referenceService.CreateBrandAsync(request.Name);
            return Ok(result);
        }

        [HttpPut("brands/{id}")]
        [Authorize(Roles = AppRoles.Admin)]
        public async Task<IActionResult> UpdateBrand(int id, [FromBody] NameRequest request)
        {
            var result = await _referenceService.UpdateBrandAsync(id, request.Name);
            return Ok(result);
        }

        [HttpDelete("brands/{id}")]
        [Authorize(Roles = AppRoles.Admin)]
        public async Task<IActionResult> DeleteBrand(int id)
        {
            await _referenceService.DeleteBrandAsync(id);
            return NoContent();
        }

        // ---------- FuelTypes ----------
        [HttpPost("fueltypes")]
        [Authorize(Roles = AppRoles.Admin)]
        public async Task<IActionResult> CreateFuelType([FromBody] NameRequest request)
        {
            var result = await _referenceService.CreateFuelTypeAsync(request.Name);
            return Ok(result);
        }

        [HttpPut("fueltypes/{id}")]
        [Authorize(Roles = AppRoles.Admin)]
        public async Task<IActionResult> UpdateFuelType(int id, [FromBody] NameRequest request)
        {
            var result = await _referenceService.UpdateFuelTypeAsync(id, request.Name);
            return Ok(result);
        }

        [HttpDelete("fueltypes/{id}")]
        [Authorize(Roles = AppRoles.Admin)]
        public async Task<IActionResult> DeleteFuelType(int id)
        {
            await _referenceService.DeleteFuelTypeAsync(id);
            return NoContent();
        }

        // ---------- Transmissions ----------
        [HttpPost("transmissions")]
        [Authorize(Roles = AppRoles.Admin)]
        public async Task<IActionResult> CreateTransmission([FromBody] NameRequest request)
        {
            var result = await _referenceService.CreateTransmissionAsync(request.Name);
            return Ok(result);
        }

        [HttpPut("transmissions/{id}")]
        [Authorize(Roles = AppRoles.Admin)]
        public async Task<IActionResult> UpdateTransmission(int id, [FromBody] NameRequest request)
        {
            var result = await _referenceService.UpdateTransmissionAsync(id, request.Name);
            return Ok(result);
        }

        [HttpDelete("transmissions/{id}")]
        [Authorize(Roles = AppRoles.Admin)]
        public async Task<IActionResult> DeleteTransmission(int id)
        {
            await _referenceService.DeleteTransmissionAsync(id);
            return NoContent();
        }

        // ---------- Cities ----------
        [HttpPost("cities")]
        [Authorize(Roles = AppRoles.Admin)]
        public async Task<IActionResult> CreateCity([FromBody] CityRequest request)
        {
            var result = await _referenceService.CreateCityAsync(request.Name, request.CountryId);
            return Ok(result);
        }

        [HttpPut("cities/{id}")]
        [Authorize(Roles = AppRoles.Admin)]
        public async Task<IActionResult> UpdateCity(int id, [FromBody] CityRequest request)
        {
            var result = await _referenceService.UpdateCityAsync(id, request.Name, request.CountryId);
            return Ok(result);
        }

        [HttpDelete("cities/{id}")]
        [Authorize(Roles = AppRoles.Admin)]
        public async Task<IActionResult> DeleteCity(int id)
        {
            await _referenceService.DeleteCityAsync(id);
            return NoContent();
        }

        // ---------- Extra Services ----------
        [HttpGet("extraservices/all")]
        [Authorize(Roles = AppRoles.Admin)]
        public async Task<IActionResult> GetAllExtraServices()
        {
            var data = await _referenceService.GetExtraServicesAsync(all: true);
            return Ok(data);
        }

        [HttpPost("extraservices")]
        [Authorize(Roles = AppRoles.Admin)]
        public async Task<IActionResult> CreateExtraService([FromBody] ExtraServiceRequest request)
        {
            var result = await _referenceService.CreateExtraServiceAsync(request.Name, request.Description, request.PricePerDay, request.IsAvailable);
            return Ok(result);
        }

        [HttpPut("extraservices/{id}")]
        [Authorize(Roles = AppRoles.Admin)]
        public async Task<IActionResult> UpdateExtraService(int id, [FromBody] ExtraServiceRequest request)
        {
            var result = await _referenceService.UpdateExtraServiceAsync(id, request.Name, request.Description, request.PricePerDay, request.IsAvailable);
            return Ok(result);
        }

        [HttpDelete("extraservices/{id}")]
        [Authorize(Roles = AppRoles.Admin)]
        public async Task<IActionResult> DeleteExtraService(int id)
        {
            await _referenceService.DeleteExtraServiceAsync(id);
            return NoContent();
        }

        // ---------- Countries ----------
        [HttpPost("countries")]
        [Authorize(Roles = AppRoles.Admin)]
        public async Task<IActionResult> CreateCountry([FromBody] CountryRequest request)
        {
            var result = await _referenceService.CreateCountryAsync(request.Name, request.Code);
            return Ok(result);
        }

        [HttpPut("countries/{id}")]
        [Authorize(Roles = AppRoles.Admin)]
        public async Task<IActionResult> UpdateCountry(int id, [FromBody] CountryRequest request)
        {
            var result = await _referenceService.UpdateCountryAsync(id, request.Name, request.Code);
            return Ok(result);
        }

        [HttpDelete("countries/{id}")]
        [Authorize(Roles = AppRoles.Admin)]
        public async Task<IActionResult> DeleteCountry(int id)
        {
            await _referenceService.DeleteCountryAsync(id);
            return NoContent();
        }
    }
}

public class NameRequest
{
    public string Name { get; set; } = null!;
}

public class CategoryRequest
{
    public string Name { get; set; } = null!;
    public string? Description { get; set; }
}

public class CityRequest
{
    public string Name { get; set; } = null!;
    public int CountryId { get; set; }
}

public class CountryRequest
{
    public string Name { get; set; } = null!;
    public string Code { get; set; } = null!;
}

public class ExtraServiceRequest
{
    public string Name { get; set; } = null!;
    public string? Description { get; set; }
    public decimal PricePerDay { get; set; }
    public bool IsAvailable { get; set; } = true;
}
