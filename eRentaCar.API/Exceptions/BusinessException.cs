namespace eRentaCar.API.Exceptions
{
    public class BusinessException : AppException
    {
        public BusinessException(string message) : base(message, 400) { }

        public BusinessException(string message, string errorCode) : base(message, 400, errorCode) { }
    }
}