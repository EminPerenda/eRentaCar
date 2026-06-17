using eRentaCar.API.Constants;
using eRentaCar.API.Data;
using eRentaCar.API.DTOs;
using eRentaCar.API.DTOs.User;
using eRentaCar.API.Enums;
using eRentaCar.API.Exceptions;
using eRentaCar.API.Models;
using eRentaCar.API.Services.Interfaces;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;

namespace eRentaCar.API.Services
{
    public class UserService : IUserService
    {
        private readonly ApplicationDbContext _context;
        private readonly UserManager<ApplicationUser> _userManager;

        public UserService(ApplicationDbContext context, UserManager<ApplicationUser> userManager)
        {
            _context = context;
            _userManager = userManager;
        }

        public async Task<PagedResponse<UserResponse>> GetAllAsync(string? search, int page, int pageSize)
        {
            if (pageSize > 100) pageSize = 100;

            var query = _context.Users
                .Include(x => x.City)
                .Include(x => x.Reservations)
                .AsQueryable();

            if (!string.IsNullOrEmpty(search))
                query = query.Where(x =>
                    x.FirstName.Contains(search) ||
                    x.LastName.Contains(search) ||
                    x.Email!.Contains(search) ||
                    (x.DriverLicenseNo != null && x.DriverLicenseNo.Contains(search)));

            var totalCount = await query.CountAsync();

            var users = await query
                .OrderByDescending(x => x.CreatedAt)
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .ToListAsync();

            var userIds = users.Select(u => u.Id).ToList();

            var rolesByUserId = await (
                from ur in _context.UserRoles
                join r in _context.Roles on ur.RoleId equals r.Id
                where userIds.Contains(ur.UserId)
                select new { ur.UserId, r.Name }
            ).ToDictionaryAsync(x => x.UserId, x => x.Name);

            var responses = users
                .Select(u => MapToResponse(u, rolesByUserId.GetValueOrDefault(u.Id, AppRoles.Client)))
                .ToList();

            return new PagedResponse<UserResponse>
            {
                Items = responses,
                TotalCount = totalCount,
                Page = page,
                PageSize = pageSize
            };
        }

        public async Task<UserResponse> GetByIdAsync(int id)
        {
            var user = await _context.Users
                .Include(x => x.City)
                .Include(x => x.Reservations)
                .FirstOrDefaultAsync(x => x.Id == id)
                ?? throw new NotFoundException("Korisnik", id);

            var roles = await _userManager.GetRolesAsync(user);
            return MapToResponse(user, roles.FirstOrDefault() ?? AppRoles.Client);
        }

        public async Task<UserResponse> GetCurrentAsync(int userId)
        {
            return await GetByIdAsync(userId);
        }

        public async Task<UserResponse> UpdateProfileAsync(int userId, UpdateProfileRequest request)
        {
            var user = await _userManager.FindByIdAsync(userId.ToString())
                ?? throw new NotFoundException("Korisnik", userId);

            if (request.ProfileImageUrl != null)
                user.ProfileImageUrl = request.ProfileImageUrl;

            user.FirstName = request.FirstName;
            user.LastName = request.LastName;
            user.PhoneNumber = request.PhoneNumber;
            user.CityId = request.CityId;
            user.DriverLicenseNo = request.DriverLicenseNo;

            await _userManager.UpdateAsync(user);

            return await GetByIdAsync(userId);
        }

        public async Task<UserResponse> UpdateUserAsync(int id, UpdateUserRequest request)
        {
            var user = await _userManager.FindByIdAsync(id.ToString())
                ?? throw new NotFoundException("Korisnik", id);

            user.FirstName = request.FirstName;
            user.LastName = request.LastName;
            user.PhoneNumber = request.PhoneNumber;
            user.CityId = request.CityId;
            user.DriverLicenseNo = request.DriverLicenseNo;
            user.IsActive = request.IsActive;

            await _userManager.UpdateAsync(user);

            return await GetByIdAsync(id);
        }

        public async Task ChangePasswordAsync(int userId, ChangePasswordRequest request)
        {
            var user = await _userManager.FindByIdAsync(userId.ToString())
                ?? throw new NotFoundException("Korisnik", userId);

            var result = await _userManager.ChangePasswordAsync(user, request.CurrentPassword, request.NewPassword);

            if (!result.Succeeded)
            {
                var errors = string.Join(", ", result.Errors.Select(x => x.Description));
                throw new BusinessException(errors);
            }
        }

        public async Task AdminResetPasswordAsync(int userId, string newPassword)
        {
            var user = await _userManager.FindByIdAsync(userId.ToString())
                ?? throw new NotFoundException("Korisnik", userId);
            var token = await _userManager.GeneratePasswordResetTokenAsync(user);
            var result = await _userManager.ResetPasswordAsync(user, token, newPassword);
            if (!result.Succeeded)
            {
                var errors = string.Join(", ", result.Errors.Select(x => x.Description));
                throw new BusinessException(errors);
            }
        }

        public async Task ToggleActiveAsync(int id)
        {
            var user = await _userManager.FindByIdAsync(id.ToString())
                ?? throw new NotFoundException("Korisnik", id);

            user.IsActive = !user.IsActive;
            await _userManager.UpdateAsync(user);
        }

        private static UserResponse MapToResponse(ApplicationUser u, string role) => new()
        {
            Id = u.Id,
            FirstName = u.FirstName,
            LastName = u.LastName,
            Email = u.Email!,
            PhoneNumber = u.PhoneNumber,
            City = u.City?.Name,
            CityId = u.CityId,
            DriverLicenseNo = u.DriverLicenseNo,
            ProfileImageUrl = u.ProfileImageUrl,
            IsActive = u.IsActive,
            CreatedAt = u.CreatedAt,
            Role = role,
            ReservationCount = u.Reservations.Count,
            TotalSpent = u.Reservations
                .Where(r => r.Status == ReservationStatus.Completed)
                .Sum(r => r.TotalPrice)
        };
    }
}
