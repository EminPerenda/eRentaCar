namespace eRentaCar.API.DTOs.Payment
{
    public class RefundResponse
    {
        public string Message { get; set; } = null!;
        public decimal RefundAmount { get; set; }
    }
}
