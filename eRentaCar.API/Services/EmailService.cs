using System.Net;
using System.Net.Mail;
using eRentaCar.API.Helpers;

namespace eRentaCar.API.Services
{
    public class EmailService
    {
        private readonly string _host;
        private readonly int _port;
        private readonly string _username;
        private readonly string _password;

        public EmailService()
        {
            _host = EnvHelper.Get("SMTP_HOST");
            _port = int.Parse(EnvHelper.Get("SMTP_PORT"));
            _username = EnvHelper.Get("SMTP_USERNAME");
            _password = EnvHelper.Get("SMTP_PASSWORD");
        }

        public async Task SendEmailAsync(string to, string subject, string body)
        {
            using var client = new SmtpClient(_host, _port)
            {
                Credentials = new NetworkCredential(_username, _password),
                EnableSsl = true
            };

            var mail = new MailMessage
            {
                From = new MailAddress(_username, "eRentaCar"),
                Subject = subject,
                Body = body,
                IsBodyHtml = true
            };
            mail.To.Add(to);

            await client.SendMailAsync(mail);
        }
    }
}