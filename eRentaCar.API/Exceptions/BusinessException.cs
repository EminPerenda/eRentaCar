namespace eRentaCar.API.Exceptions
{
    public class BusinessException : AppException
    {
        public BusinessException(string message) : base(message, 400) { }
    }
}