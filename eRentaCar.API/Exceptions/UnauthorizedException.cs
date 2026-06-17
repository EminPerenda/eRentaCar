namespace eRentaCar.API.Exceptions
{
    public class UnauthorizedException : AppException
    {
        public UnauthorizedException(string message = "Nemate pravo pristupa ovom resursu.")
            : base(message, 401) { }
    }
}