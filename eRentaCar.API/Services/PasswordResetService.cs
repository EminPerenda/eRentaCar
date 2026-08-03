using eRentaCar.API.Data;
using eRentaCar.API.Exceptions;
using eRentaCar.API.Models;
using eRentaCar.API.Services.Interfaces;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using System.Security.Cryptography;
using System.Text;

namespace eRentaCar.API.Services
{
    public class PasswordResetService : IPasswordResetService
    {
        private const int ResetCodeAttemptsLimit = 5;
        private static readonly TimeSpan ResetRequestCooldown = TimeSpan.FromMinutes(1);
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
            var user = await _userManager.FindByEmailAsync(email);

            if (user == null)
                return;

            var recentRequest = await _context.PasswordResetTokens
                .Where(x => x.UserId == user.Id)
                .OrderByDescending(x => x.CreatedAt)
                .FirstOrDefaultAsync();

            if (recentRequest != null && recentRequest.CreatedAt > DateTime.UtcNow.Subtract(ResetRequestCooldown))
                return;

            await InvalidateActiveTokensAsync(user.Id);

            var code = RandomNumberGenerator.GetInt32(100000, 1000000).ToString();
            var salt = RandomNumberGenerator.GetBytes(16);
            var token = new PasswordResetToken
            {
                UserId = user.Id,
                Token = ComputeTokenHash(code, salt),
                TokenSalt = Convert.ToBase64String(salt),
                ExpiresAt = DateTime.UtcNow.AddMinutes(15),
                IsUsed = false,
                AttemptCount = 0,
                CreatedAt = DateTime.UtcNow
            };

            _context.PasswordResetTokens.Add(token);
            await _context.SaveChangesAsync();

            await _emailService.SendEmailAsync(
                user.Email!,
                "eRentaCar — Reset lozinke",
                $"Vaš kod za reset lozinke je: <b>{code}</b><br>Kod je validan 15 minuta."
            );
        }

        public async Task ConfirmResetAsync(string email, string code, string newPassword)
        {
            var user = await _userManager.FindByEmailAsync(email);
            if (user == null)
                throw new BusinessException("Nevažeći kod.", "RESET_CODE_INVALID");

            var activeTokens = await _context.PasswordResetTokens
                .Where(x => x.UserId == user.Id && !x.IsUsed)
                .OrderByDescending(x => x.CreatedAt)
                .ToListAsync();

            var liveTokens = activeTokens
                .Where(x => x.ExpiresAt > DateTime.UtcNow)
                .ToList();

            var token = liveTokens
                .FirstOrDefault(x => VerifyToken(code, x.Token, x.TokenSalt));

            if (token == null)
            {
                if (liveTokens.Count > 0)
                {
                    var latestActiveToken = liveTokens[0];
                    latestActiveToken.AttemptCount++;
                    if (latestActiveToken.AttemptCount >= ResetCodeAttemptsLimit)
                    {
                        latestActiveToken.IsUsed = true;
                        latestActiveToken.UsedAt = DateTime.UtcNow;
                        await _context.SaveChangesAsync();
                        throw new BusinessException("Previše neuspješnih pokušaja. Zatražite novi kod.", "RESET_CODE_ATTEMPTS_EXCEEDED");
                    }

                    await _context.SaveChangesAsync();
                    throw new BusinessException("Neispravan kod.", "RESET_CODE_INVALID");
                }

                if (activeTokens.Count > 0)
                    throw new BusinessException("Kod je istekao. Zatražite novi kod.", "RESET_CODE_EXPIRED");

                throw new BusinessException("Nevažeći kod.", "RESET_CODE_INVALID");
            }

            var resetToken = await _userManager.GeneratePasswordResetTokenAsync(user);
            var result = await _userManager.ResetPasswordAsync(user, resetToken, newPassword);

            if (!result.Succeeded)
            {
                var errors = string.Join(", ", result.Errors.Select(x => x.Description));
                throw new BusinessException(errors);
            }

            token.IsUsed = true;
            token.UsedAt = DateTime.UtcNow;
            token.AttemptCount = 0;
            await _userManager.UpdateSecurityStampAsync(user);
            await _context.SaveChangesAsync();
        }

        private async Task InvalidateActiveTokensAsync(int userId)
        {
            var activeTokens = await _context.PasswordResetTokens
                .Where(x => x.UserId == userId && !x.IsUsed && x.ExpiresAt > DateTime.UtcNow)
                .ToListAsync();

            foreach (var activeToken in activeTokens)
            {
                activeToken.IsUsed = true;
                activeToken.UsedAt = DateTime.UtcNow;
            }

            if (activeTokens.Count > 0)
                await _context.SaveChangesAsync();
        }

        private static string ComputeTokenHash(string code, byte[] salt)
        {
            var codeBytes = Encoding.UTF8.GetBytes(code);
            var data = new byte[salt.Length + codeBytes.Length];
            Buffer.BlockCopy(salt, 0, data, 0, salt.Length);
            Buffer.BlockCopy(codeBytes, 0, data, salt.Length, codeBytes.Length);

            return Convert.ToBase64String(SHA256.HashData(data));
        }

        private static bool VerifyToken(string code, string storedHash, string storedSalt)
        {
            var salt = Convert.FromBase64String(storedSalt);
            var computed = ComputeTokenHash(code, salt);

            var computedBytes = Convert.FromBase64String(computed);
            var storedBytes = Convert.FromBase64String(storedHash);
            return CryptographicOperations.FixedTimeEquals(computedBytes, storedBytes);
        }
    }
}
