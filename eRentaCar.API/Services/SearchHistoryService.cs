using eRentaCar.API.Data;
using eRentaCar.API.DTOs.Recommendation;
using eRentaCar.API.Enums;
using eRentaCar.API.Models;
using eRentaCar.API.Services.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace eRentaCar.API.Services
{
    public class SearchHistoryService : ISearchHistoryService
    {
        private readonly ApplicationDbContext _context;

        public SearchHistoryService(ApplicationDbContext context)
        {
            _context = context;
        }

        public async Task LogAsync(int userId, SearchActionType actionType, int? vehicleId = null, int? categoryId = null)
        {
            var entry = new SearchHistory
            {
                UserId = userId,
                ActionType = actionType,
                VehicleId = vehicleId,
                CategoryId = categoryId,
                SearchedAt = DateTime.UtcNow
            };

            _context.SearchHistories.Add(entry);
            await _context.SaveChangesAsync();
        }

        public async Task<List<RecommendationResponse>> GetRecommendationsAsync(int userId)
        {
            // Content-based: kategorije koje je korisnik pregledao ili rezervisao
            var preferredCategoryIds = await _context.SearchHistories
                .Where(x => x.UserId == userId && x.CategoryId != null)
                .GroupBy(x => x.CategoryId)
                .OrderByDescending(x => x.Count())
                .Select(x => x.Key)
                .Take(2)
                .ToListAsync();

            // Vozila koja je korisnik već iznajmio
            var rentedVehicleIds = await _context.Reservations
                .Where(x => x.UserId == userId && x.Status == ReservationStatus.Completed)
                .Select(x => x.VehicleId)
                .ToListAsync();

            var contentBasedRaw = await _context.Vehicles
                .Include(x => x.Brand)
                .Include(x => x.Category)
                .Include(x => x.Images)
                .Include(x => x.Reviews)
                .Where(x =>
                    x.IsActive &&
                    x.Status == VehicleStatus.Available &&
                    preferredCategoryIds.Contains(x.CategoryId) &&
                    !rentedVehicleIds.Contains(x.Id))
                .ToListAsync();

            // Score: 60% category preference order + 40% average rating
            var contentBased = contentBasedRaw
                .Select(v =>
                {
                    var avgRating = v.Reviews.Any() ? v.Reviews.Average(r => r.Rating) : 0;
                    var catRank = preferredCategoryIds.IndexOf(v.CategoryId);
                    var catScore = catRank == 0 ? 1.0 : 0.5;
                    return (Vehicle: v, Score: catScore * 0.6 + (avgRating / 5.0) * 0.4, AvgRating: avgRating);
                })
                .OrderByDescending(x => x.Score)
                .Take(3)
                .ToList();

            // Popularity-based: najpopularnija vozila u zadnjih 30 dana s brojevima rezervacija
            var since = DateTime.UtcNow.AddDays(-30);
            var popularCounts = await _context.Reservations
                .Where(x => x.CreatedAt >= since)
                .GroupBy(x => x.VehicleId)
                .OrderByDescending(x => x.Count())
                .Select(x => new { VehicleId = x.Key, Count = x.Count() })
                .Take(10)
                .ToListAsync();

            var popularVehicleIds = popularCounts.Select(x => x.VehicleId).ToList();

            var popularVehicles = await _context.Vehicles
                .Include(x => x.Brand)
                .Include(x => x.Category)
                .Include(x => x.Images)
                .Include(x => x.Reviews)
                .Where(x =>
                    x.IsActive &&
                    x.Status == VehicleStatus.Available &&
                    popularVehicleIds.Contains(x.Id) &&
                    !rentedVehicleIds.Contains(x.Id))
                .ToListAsync();

            var maxCount = popularCounts.Any() ? popularCounts.Max(x => x.Count) : 1;

            // Score: 70% popularity (normalised reservation count) + 30% average rating
            var popularScored = popularVehicles
                .Select(v =>
                {
                    var avgRating = v.Reviews.Any() ? v.Reviews.Average(r => r.Rating) : 0;
                    var count = popularCounts.FirstOrDefault(x => x.VehicleId == v.Id)?.Count ?? 0;
                    var popularityScore = (double)count / maxCount;
                    return (Vehicle: v, Score: popularityScore * 0.7 + (avgRating / 5.0) * 0.3, AvgRating: avgRating);
                })
                .OrderByDescending(x => x.Score)
                .ToList();

            var recommendations = new List<RecommendationResponse>();

            foreach (var (v, _, avgRating) in contentBased)
            {
                recommendations.Add(new RecommendationResponse
                {
                    Id = v.Id,
                    Vehicle = $"{v.Brand.Name} {v.Model}",
                    Name = v.Category.Name,
                    PricePerDay = v.PricePerDay,
                    AverageRating = Math.Round(avgRating, 1),
                    PrimaryImageUrl = v.Images.FirstOrDefault(x => x.IsPrimary)?.ImageUrl ?? v.Images.FirstOrDefault()?.ImageUrl,
                    Reason = $"Jer ste pregledali {v.Category.Name} kategoriju",
                    Type = "content-based"
                });
            }

            var usedIds = contentBased.Select(x => x.Vehicle.Id).ToHashSet();
            foreach (var (v, _, avgRating) in popularScored.Where(x => !usedIds.Contains(x.Vehicle.Id)))
            {
                recommendations.Add(new RecommendationResponse
                {
                    Id = v.Id,
                    Vehicle = $"{v.Brand.Name} {v.Model}",
                    Name = v.Category.Name,
                    PricePerDay = v.PricePerDay,
                    AverageRating = Math.Round(avgRating, 1),
                    PrimaryImageUrl = v.Images.FirstOrDefault(x => x.IsPrimary)?.ImageUrl ?? v.Images.FirstOrDefault()?.ImageUrl,
                    Reason = "Top izbor ove sedmice",
                    Type = "popularity-based"
                });
            }

            return recommendations;
        }
    }
}
