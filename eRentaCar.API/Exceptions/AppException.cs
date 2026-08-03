namespace eRentaCar.API.Exceptions
{
    public class AppException : Exception
    {
        public int StatusCode { get; }
        public string? ErrorCode { get; }

        public AppException(string message, int statusCode = 400) : base(message)
        {
            StatusCode = statusCode;
        }

        public AppException(string message, int statusCode, string errorCode) : base(message)
        {
            StatusCode = statusCode;
            ErrorCode = errorCode;
        }
    }
}