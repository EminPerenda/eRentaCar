namespace eRentaCar.API.Services.Interfaces
{
    public interface IPasswordResetService
    {
        Task RequestResetAsync(string email);
        Task ConfirmResetAsync(string email, string code, string newPassword);
    }
}
