namespace eRentaCar.API.Exceptions
{
    public class NotFoundException : AppException
    {
        public NotFoundException(string resource, int id)
            : base($"{resource} s ID-om {id} nije pronađen.", 404) { }

        public NotFoundException(string message)
            : base(message, 404) { }
    }
}