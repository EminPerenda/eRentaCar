namespace eRentaCar.API.Services.Interfaces
{
    public interface IPasswordResetService
    {
        Task RequestResetAsync(string email);
        Task ConfirmResetAsync(string code, string newPassword);
    }
}
