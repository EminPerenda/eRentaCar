using eRentaCar.API.Data;
using eRentaCar.API.DTOs;
using eRentaCar.API.DTOs.Review;
using eRentaCar.API.Enums;
using eRentaCar.API.Exceptions;
using eRentaCar.API.Models;
using eRentaCar.API.Services.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace eRentaCar.API.Services
{
    public class ReviewService : IReviewService
    {
        private readonly ApplicationDbContext _context;

        public ReviewService(ApplicationDbContext context)
        {
            _context = context;
        }

        public async Task<PagedResponse<ReviewResponse>> GetByVehicleAsync(int vehicleId, int page = 1, int pageSize = 20)
        {
            if (pageSize > 100) pageSize = 100;

            var query = _context.VehicleReviews
                .Include(x => x.User)
                .Include(x => x.Vehicle).ThenInclude(x => x.Brand)
                .Where(x => x.VehicleId == vehicleId);

            var totalCount = await query.CountAsync();

            var reviews = await query
                .OrderByDescending(x => x.CreatedAt)
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .ToListAsync();

            return new PagedResponse<ReviewResponse>
            {
                Items = reviews.Select(MapToResponse).ToList(),
                TotalCount = totalCount,
                Page = page,
                PageSize = pageSize
            };
        }

        public async Task<ReviewResponse> CreateAsync(int userId, ReviewRequest request)
        {
            if (request.Rating < 1 || request.Rating > 5)
                throw new BusinessException("Ocjena mora biti između 1 i 5.");

            var reservation = await _context.Reservations
                .FirstOrDefaultAsync(x =>
                    x.Id == request.ReservationId &&
                    x.UserId == userId &&
                    x.VehicleId == request.VehicleId)
                ?? throw new NotFoundException("Rezervacija nije pronađena ili ne pripada vašem nalogu.");

            if (reservation.Status != ReservationStatus.Completed)
                throw new BusinessException("Recenziju možete ostaviti samo za završene rezervacije.");

            var alreadyReviewed = await _context.VehicleReviews
                .AnyAsync(x => x.ReservationId == request.ReservationId);

            if (alreadyReviewed)
                throw new BusinessException("Za ovu rezervaciju već ste ostavili recenziju.");

            var review = new VehicleReview
            {
                UserId = userId,
                VehicleId = request.VehicleId,
                ReservationId = request.ReservationId,
                Rating = request.Rating,
                Comment = request.Comment
            };

            _context.VehicleReviews.Add(review);
            await _context.SaveChangesAsync();

            return await _context.VehicleReviews
                .Include(x => x.User)
                .Include(x => x.Vehicle).ThenInclude(x => x.Brand)
                .Where(x => x.Id == review.Id)
                .Select(x => MapToResponse(x))
                .FirstAsync();
        }

        private static ReviewResponse MapToResponse(VehicleReview r) => new()
        {
            Id = r.Id,
            ClientName = $"{r.User.FirstName} {r.User.LastName}",
            VehicleId = r.VehicleId,
            Vehicle = $"{r.Vehicle.Brand.Name} {r.Vehicle.Model}",
            ReservationId = r.ReservationId,
            Rating = r.Rating,
            Comment = r.Comment,
            CreatedAt = r.CreatedAt
        };
    }
}
