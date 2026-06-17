using eRentaCar.API.DTOs.Reports;

namespace eRentaCar.API.Services.Interfaces
{
    public interface IReportsService
    {
        Task<FinancialReportResponse> GetFinancialAsync(DateTime? from, DateTime? to);
        Task<VehicleReportResponse> GetVehiclesAsync(DateTime? from, DateTime? to);
        Task<ClientReportResponse> GetClientsAsync(DateTime? from, DateTime? to);
        Task<LocationReportResponse> GetLocationsAsync(DateTime? from, DateTime? to);
    }
}
