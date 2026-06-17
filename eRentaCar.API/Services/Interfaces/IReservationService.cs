using eRentaCar.API.DTOs;
using eRentaCar.API.DTOs.Reservation;

namespace eRentaCar.API.Services.Interfaces
{
    public interface IReservationService
    {
        Task<PagedResponse<ReservationResponse>> GetAllAsync(ReservationFilterRequest filter);
        Task<ReservationResponse> GetByIdAsync(int id);
        Task<ReservationResponse> CreateAsync(int userId, ReservationRequest request);
        Task<ReservationResponse> ConfirmAsync(int id, int adminId);
        Task<ReservationResponse> RejectAsync(int id, int adminId, string reason);
        Task<ReservationResponse> ActivateAsync(int id, int adminId);
        Task<ReservationResponse> CancelAsync(int id, int userId, string reason, bool isAdmin);
        Task<ReservationResponse> CompleteAsync(int id, int adminId);
        Task<List<OccupiedDateRange>> GetVehicleOccupiedDatesAsync(int vehicleId);
    }
}