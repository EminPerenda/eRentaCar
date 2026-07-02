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
        private const double Alpha = 0.7;
        private const double Beta = 0.3;
        private const int RecommendationLimit = 5;
        private const int PopularityWindowDays = 90;

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
            var now = DateTime.UtcNow;

            var interactionSignals = await LoadInteractionSignalsAsync(userId);
            var historicalVehicleIds = interactionSignals
                .Select(x => x.VehicleId)
                .Distinct()
                .ToList();

            var historicalVehicles = historicalVehicleIds.Count == 0
                ? new List<Vehicle>()
                : await _context.Vehicles
                    .AsNoTracking()
                    .Include(x => x.Brand)
                    .Include(x => x.Category)
                    .Include(x => x.FuelType)
                    .Include(x => x.Transmission)
                    .Include(x => x.Images)
                    .Include(x => x.Reviews)
                    .Where(x => historicalVehicleIds.Contains(x.Id))
                    .ToListAsync();

            var availableVehicles = await _context.Vehicles
                .AsNoTracking()
                .Include(x => x.Brand)
                .Include(x => x.Category)
                .Include(x => x.FuelType)
                .Include(x => x.Transmission)
                .Include(x => x.Images)
                .Include(x => x.Reviews)
                .Where(x => x.IsActive && x.Status == VehicleStatus.Available)
                .ToListAsync();

            if (!availableVehicles.Any())
                return new List<RecommendationResponse>();

            var featureVehicles = availableVehicles
                .Concat(historicalVehicles)
                .GroupBy(x => x.Id)
                .Select(x => x.First())
                .ToList();

            var featureSpace = BuildFeatureSpace(featureVehicles);
            var minPrice = featureVehicles.Min(x => x.PricePerDay);
            var maxPrice = featureVehicles.Max(x => x.PricePerDay);

            var historicalVehiclesById = historicalVehicles.ToDictionary(x => x.Id, x => x);
            var profileVector = BuildUserProfileVector(interactionSignals, historicalVehiclesById, featureSpace, minPrice, maxPrice, now);

            var recentReservationCounts = await _context.Reservations
                .AsNoTracking()
                .Where(x => x.CreatedAt >= now.AddDays(-PopularityWindowDays) && x.Status != ReservationStatus.Cancelled)
                .GroupBy(x => x.VehicleId)
                .Select(x => new { VehicleId = x.Key, Count = x.Count() })
                .ToDictionaryAsync(x => x.VehicleId, x => x.Count);

            var averageRatings = await _context.VehicleReviews
                .AsNoTracking()
                .GroupBy(x => x.VehicleId)
                .Select(x => new { VehicleId = x.Key, AverageRating = x.Average(r => r.Rating) })
                .ToDictionaryAsync(x => x.VehicleId, x => x.AverageRating);

            var maxReservationCount = recentReservationCounts.Values.DefaultIfEmpty(0).Max();

            var recommendations = availableVehicles
                .Select(vehicle =>
                {
                    var vehicleVector = BuildFeatureVector(vehicle, featureSpace, minPrice, maxPrice);
                    var similarity = CalculateCosineSimilarity(profileVector, vehicleVector);
                    var popularity = CalculatePopularityScore(vehicle.Id, recentReservationCounts, averageRatings, maxReservationCount);
                    var score = (Alpha * similarity) + (Beta * popularity);
                    var reason = BuildReason(vehicle, profileVector, vehicleVector, similarity, popularity, featureSpace);

                    return new RecommendationCandidate(
                        vehicle,
                        vehicleVector,
                        similarity,
                        popularity,
                        score,
                        reason);
                })
                .OrderByDescending(x => x.Score)
                .ThenByDescending(x => x.Similarity)
                .ThenByDescending(x => x.Popularity)
                .Take(RecommendationLimit)
                .Select(x => new RecommendationResponse
                {
                    Id = x.Vehicle.Id,
                    Vehicle = $"{x.Vehicle.Brand.Name} {x.Vehicle.Model}",
                    Name = x.Vehicle.Category.Name,
                    PricePerDay = x.Vehicle.PricePerDay,
                    AverageRating = Math.Round(x.Vehicle.Reviews.Any() ? x.Vehicle.Reviews.Average(r => r.Rating) : 0, 1),
                    PrimaryImageUrl = x.Vehicle.Images.FirstOrDefault(i => i.IsPrimary)?.ImageUrl ?? x.Vehicle.Images.FirstOrDefault()?.ImageUrl,
                    Reason = x.Reason,
                    Type = "hybrid"
                })
                .ToList();

            return recommendations;
        }

        private async Task<List<InteractionSignal>> LoadInteractionSignalsAsync(int userId)
        {
            var viewSignals = await _context.SearchHistories
                .AsNoTracking()
                .Where(x => x.UserId == userId && x.ActionType == SearchActionType.VehicleView && x.VehicleId != null)
                .Select(x => new InteractionSignal(x.VehicleId!.Value, x.SearchedAt, InteractionSignalType.View, null))
                .ToListAsync();

            var reservationSignals = await _context.Reservations
                .AsNoTracking()
                .Where(x => x.UserId == userId && x.Status == ReservationStatus.Completed)
                .Select(x => new InteractionSignal(x.VehicleId, x.CompletedAt ?? x.CreatedAt, InteractionSignalType.Reservation, null))
                .ToListAsync();

            var reviewSignals = await _context.VehicleReviews
                .AsNoTracking()
                .Where(x => x.UserId == userId && x.Rating >= 4)
                .Select(x => new InteractionSignal(x.VehicleId, x.CreatedAt, InteractionSignalType.Review, x.Rating))
                .ToListAsync();

            return viewSignals
                .Concat(reservationSignals)
                .Concat(reviewSignals)
                .ToList();
        }

        private static FeatureSpace BuildFeatureSpace(IReadOnlyCollection<Vehicle> vehicles)
        {
            var categoryIndexes = vehicles
                .Select(x => x.CategoryId)
                .Distinct()
                .OrderBy(x => x)
                .Select((categoryId, index) => new { categoryId, index })
                .ToDictionary(x => x.categoryId, x => x.index);

            var fuelTypeIndexes = vehicles
                .Select(x => x.FuelTypeId)
                .Distinct()
                .OrderBy(x => x)
                .Select((fuelTypeId, index) => new { fuelTypeId, index })
                .ToDictionary(x => x.fuelTypeId, x => x.index);

            var transmissionIndexes = vehicles
                .Select(x => x.TransmissionId)
                .Distinct()
                .OrderBy(x => x)
                .Select((transmissionId, index) => new { transmissionId, index })
                .ToDictionary(x => x.transmissionId, x => x.index);

            var priceIndex = categoryIndexes.Count + fuelTypeIndexes.Count + transmissionIndexes.Count;

            return new FeatureSpace(categoryIndexes, fuelTypeIndexes, transmissionIndexes, priceIndex);
        }

        private static double[] BuildUserProfileVector(
            IReadOnlyCollection<InteractionSignal> interactionSignals,
            IReadOnlyDictionary<int, Vehicle> vehiclesById,
            FeatureSpace featureSpace,
            decimal minPrice,
            decimal maxPrice,
            DateTime now)
        {
            var profile = new double[featureSpace.Dimension];
            var totalWeight = 0.0;

            foreach (var signal in interactionSignals)
            {
                if (!vehiclesById.TryGetValue(signal.VehicleId, out var vehicle))
                    continue;

                var weight = GetInteractionWeight(signal, now);
                if (weight <= 0)
                    continue;

                var vector = BuildFeatureVector(vehicle, featureSpace, minPrice, maxPrice);
                for (var index = 0; index < profile.Length; index++)
                    profile[index] += vector[index] * weight;

                totalWeight += weight;
            }

            if (totalWeight <= 0)
                return profile;

            for (var index = 0; index < profile.Length; index++)
                profile[index] /= totalWeight;

            return profile;
        }

        private static double[] BuildFeatureVector(Vehicle vehicle, FeatureSpace featureSpace, decimal minPrice, decimal maxPrice)
        {
            var vector = new double[featureSpace.Dimension];
            vector[featureSpace.CategoryIndexes[vehicle.CategoryId]] = 1;
            vector[featureSpace.FuelTypeIndexes[vehicle.FuelTypeId]] = 1;
            vector[featureSpace.TransmissionIndexes[vehicle.TransmissionId]] = 1;
            vector[featureSpace.PriceIndex] = NormalizePrice(vehicle.PricePerDay, minPrice, maxPrice);
            return vector;
        }

        private static double CalculatePopularityScore(
            int vehicleId,
            IReadOnlyDictionary<int, int> reservationCounts,
            IReadOnlyDictionary<int, double> averageRatings,
            int maxReservationCount)
        {
            var reservationCount = reservationCounts.TryGetValue(vehicleId, out var count) ? count : 0;
            var reservationScore = maxReservationCount > 0 ? (double)reservationCount / maxReservationCount : 0;
            var ratingScore = averageRatings.TryGetValue(vehicleId, out var averageRating) ? averageRating / 5.0 : 0;

            return (reservationScore + ratingScore) / 2.0;
        }

        private static double CalculateCosineSimilarity(IReadOnlyList<double> left, IReadOnlyList<double> right)
        {
            var dotProduct = 0.0;
            var leftNorm = 0.0;
            var rightNorm = 0.0;

            for (var index = 0; index < left.Count; index++)
            {
                dotProduct += left[index] * right[index];
                leftNorm += left[index] * left[index];
                rightNorm += right[index] * right[index];
            }

            if (leftNorm <= 0 || rightNorm <= 0)
                return 0;

            var similarity = dotProduct / (Math.Sqrt(leftNorm) * Math.Sqrt(rightNorm));
            return Math.Clamp(similarity, 0, 1);
        }

        private static string BuildReason(
            Vehicle vehicle,
            IReadOnlyList<double> profileVector,
            IReadOnlyList<double> vehicleVector,
            double similarity,
            double popularity,
            FeatureSpace featureSpace)
        {
            var contentContribution = Alpha * similarity;
            var popularityContribution = Beta * popularity;

            if (popularityContribution >= contentContribution || IsVectorEmpty(profileVector))
                return "Top izbor ove sedmice";

            var categoryContribution = profileVector[featureSpace.CategoryIndexes[vehicle.CategoryId]] * vehicleVector[featureSpace.CategoryIndexes[vehicle.CategoryId]];
            var fuelContribution = profileVector[featureSpace.FuelTypeIndexes[vehicle.FuelTypeId]] * vehicleVector[featureSpace.FuelTypeIndexes[vehicle.FuelTypeId]];
            var transmissionContribution = profileVector[featureSpace.TransmissionIndexes[vehicle.TransmissionId]] * vehicleVector[featureSpace.TransmissionIndexes[vehicle.TransmissionId]];
            var priceContribution = profileVector[featureSpace.PriceIndex] * vehicleVector[featureSpace.PriceIndex];

            var dominantFactor = new[]
            {
                (Name: "category", Score: categoryContribution),
                (Name: "fuel", Score: fuelContribution),
                (Name: "transmission", Score: transmissionContribution),
                (Name: "price", Score: priceContribution)
            }
            .OrderByDescending(x => x.Score)
            .First();

            return dominantFactor.Name switch
            {
                "category" => $"jer ste pregledali {vehicle.Category.Name} kategoriju",
                "fuel" => $"jer često birate vozila na {vehicle.FuelType.Name}",
                "transmission" => $"jer vam odgovara {vehicle.Transmission.Name} mjenjač",
                "price" => "jer odgovara vašem budžetu",
                _ => "jer odgovara vašim interesovanjima"
            };
        }

        private static bool IsVectorEmpty(IReadOnlyList<double> vector)
        {
            for (var index = 0; index < vector.Count; index++)
            {
                if (vector[index] > 0)
                    return false;
            }

            return true;
        }

        private static double GetInteractionWeight(InteractionSignal signal, DateTime now)
        {
            var ageDays = Math.Max(0, (now - signal.OccurredAt).TotalDays);
            var recencyWeight = 1.0 / (1.0 + (ageDays / 30.0));

            return signal.Type switch
            {
                InteractionSignalType.View => 0.6 * recencyWeight,
                InteractionSignalType.Reservation => 1.0 * recencyWeight,
                InteractionSignalType.Review => 1.4 * recencyWeight * Math.Max(0.6, (signal.Rating ?? 0) / 5.0),
                _ => 0
            };
        }

        private static double NormalizePrice(decimal price, decimal minPrice, decimal maxPrice)
        {
            if (maxPrice <= minPrice)
                return 0.5;

            return (double)((price - minPrice) / (maxPrice - minPrice));
        }

        private sealed record InteractionSignal(int VehicleId, DateTime OccurredAt, InteractionSignalType Type, int? Rating);

        private enum InteractionSignalType
        {
            View,
            Reservation,
            Review
        }

        private sealed record FeatureSpace(
            IReadOnlyDictionary<int, int> CategoryIndexes,
            IReadOnlyDictionary<int, int> FuelTypeIndexes,
            IReadOnlyDictionary<int, int> TransmissionIndexes,
            int PriceIndex)
        {
            public int Dimension => PriceIndex + 1;
        }

        private sealed record RecommendationCandidate(
            Vehicle Vehicle,
            double[] Vector,
            double Similarity,
            double Popularity,
            double Score,
            string Reason);
    }
}
