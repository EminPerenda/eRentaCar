namespace eRentaCar.API.DTOs.Payment
{
    public class PaymentIntentResponse
    {
        public string ClientSecret { get; set; } = null!;
        public decimal Amount { get; set; }
        public string Currency { get; set; } = null!;
    }
}
