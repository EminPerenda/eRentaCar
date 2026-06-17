using eRentaCar.API.Exceptions;
using System.Net;
using System.Text.Json;

namespace eRentaCar.API.Middleware
{
    public class ExceptionMiddleware
    {
        private readonly RequestDelegate _next;
        private readonly ILogger<ExceptionMiddleware> _logger;

        public ExceptionMiddleware(RequestDelegate next, ILogger<ExceptionMiddleware> logger)
        {
            _next = next;
            _logger = logger;
        }

        public async Task InvokeAsync(HttpContext context)
        {
            try
            {
                await _next(context);
            }
            catch (Exception ex)
            {
                await HandleExceptionAsync(context, ex);
            }
        }

        private async Task HandleExceptionAsync(HttpContext context, Exception ex)
        {
            int statusCode;
            string message;

            switch (ex)
            {
                case AppException appEx:
                    statusCode = appEx.StatusCode;
                    message = appEx.Message;
                    _logger.LogWarning("AppException: {Message}", ex.Message);
                    break;
                default:
                    statusCode = (int)HttpStatusCode.InternalServerError;
                    message = "Došlo je do greške na serveru. Molimo pokušajte ponovo.";
                    _logger.LogError(ex, "Neočekivana greška: {Message}", ex.Message);
                    break;
            }

            context.Response.ContentType = "application/json";
            context.Response.StatusCode = statusCode;

            var response = new
            {
                status = statusCode,
                message
            };

            await context.Response.WriteAsync(JsonSerializer.Serialize(response));
        }
    }
}