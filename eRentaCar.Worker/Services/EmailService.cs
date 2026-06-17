using System.Net;
using System.Net.Mail;

namespace eRentaCar.Worker.Services
{
    public class EmailService
    {
        private readonly string _host;
        private readonly int _port;
        private readonly string _username;
        private readonly string _password;
        private readonly bool _useSsl;
        private readonly ILogger<EmailService> _logger;

        public EmailService(ILogger<EmailService> logger)
        {
            _logger = logger;
            _host = Environment.GetEnvironmentVariable("SMTP_HOST") ?? "smtp.gmail.com";
            _port = int.Parse(Environment.GetEnvironmentVariable("SMTP_PORT") ?? "587");
            _username = Environment.GetEnvironmentVariable("SMTP_USERNAME") ?? "";
            _password = Environment.GetEnvironmentVariable("SMTP_PASSWORD") ?? "";
            _useSsl = bool.Parse(Environment.GetEnvironmentVariable("SMTP_USE_SSL") ?? "true");
        }

        public async Task SendAsync(string toEmail, string subject, string body)
        {
            try
            {
                using var client = new SmtpClient(_host, _port)
                {
                    Credentials = new NetworkCredential(_username, _password),
                    EnableSsl = _useSsl
                };

                var mail = new MailMessage
                {
                    From = new MailAddress(_username, "eRentaCar"),
                    Subject = subject,
                    Body = body,
                    IsBodyHtml = true
                };

                mail.To.Add(toEmail);

                await client.SendMailAsync(mail);
                _logger.LogInformation("Email uspješno poslan na {Email}", toEmail);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Greška pri slanju emaila na {Email}", toEmail);
            }
        }
    }
}