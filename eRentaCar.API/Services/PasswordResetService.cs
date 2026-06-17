using eRentaCar.API.Data;
using eRentaCar.API.Exceptions;
using eRentaCar.API.Models;
using eRentaCar.API.Services.Interfaces;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using System.Security.Cryptography;

namespace eRentaCar.API.Services
{
    public class PasswordResetService : IPasswordResetService
    {
        private readonly ApplicationDbContext _context;
        private readonly EmailService _emailService;
        private readonly UserManager<ApplicationUser> _userManager;

        public PasswordResetService(ApplicationDbContext context, EmailService emailService, UserManager<ApplicationUser> userManager)
        {
            _context = context;
            _emailService = emailService;
            _userManager = userManager;
        }

        public async Task RequestResetAsync(string email)
        {
            var user = await _context.Users
                .FirstOrDefaultAsync(x => x.Email == email);

            if (user == null)
                return;

            var code = RandomNumberGenerator.GetInt32(100000, 1000000).ToString();
            var token = new PasswordResetToken
            {
                UserId = user.Id,
                Token = code,
                ExpiresAt = DateTime.UtcNow.AddMinutes(15),
                IsUsed = false
            };

            _context.PasswordResetTokens.Add(token);
            await _context.SaveChangesAsync();

            await _emailService.SendEmailAsync(
                user.Email!,
                "eRentaCar — Reset lozinke",
                $"Vaš kod za reset lozinke je: <b>{code}</b><br>Kod je validan 15 minuta."
            );
        }

        public async Task ConfirmResetAsync(string code, string newPassword)
        {
            var token = await _context.PasswordResetTokens
                .Include(x => x.User)
                .FirstOrDefaultAsync(x =>
                    x.Token == code &&
                    !x.IsUsed &&
                    x.ExpiresAt > DateTime.UtcNow);

            if (token == null)
                throw new BusinessException("Nevažeći ili istekli kod.");

            var user = token.User;
            var hasher = new PasswordHasher<ApplicationUser>();
            user.PasswordHash = hasher.HashPassword(user, newPassword);

            token.IsUsed = true;
            await _context.SaveChangesAsync();
        }
    }
}
