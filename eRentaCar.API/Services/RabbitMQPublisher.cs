using eRentaCar.API.Models;
using RabbitMQ.Client;
using System.Text;
using System.Text.Json;

namespace eRentaCar.API.Services
{
    public class RabbitMQPublisher : IDisposable, IAsyncDisposable
    {
        private readonly ConnectionFactory _factory;
        private readonly ILogger<RabbitMQPublisher> _logger;
        private const string QueueName = "notifications";

        private IConnection? _connection;
        private IChannel? _channel;
        private readonly SemaphoreSlim _lock = new(1, 1);

        private static string GetEnvOrDefault(string defaultValue, params string[] names)
        {
            foreach (var name in names)
            {
                var value = Environment.GetEnvironmentVariable(name);
                if (!string.IsNullOrWhiteSpace(value))
                    return value;
            }
            return defaultValue;
        }

        public RabbitMQPublisher(ILogger<RabbitMQPublisher> logger)
        {
            _logger = logger;
            _factory = new ConnectionFactory
            {
                HostName = GetEnvOrDefault("localhost", "RABBITMQ_HOST", "RabbitMQ__Host"),
                Port = int.Parse(GetEnvOrDefault("5672", "RABBITMQ_PORT", "RabbitMQ__Port")),
                UserName = GetEnvOrDefault("guest", "RABBITMQ_USERNAME", "RabbitMQ__Username"),
                Password = GetEnvOrDefault("guest", "RABBITMQ_PASSWORD", "RabbitMQ__Password")
            };
        }

        private async Task EnsureConnectedAsync()
        {
            if (_channel?.IsOpen == true) return;

            await _lock.WaitAsync();
            try
            {
                if (_channel?.IsOpen == true) return;

                for (var attempt = 1; attempt <= 5; attempt++)
                {
                    try
                    {
                        _connection = await _factory.CreateConnectionAsync();
                        _channel = await _connection.CreateChannelAsync();

                        await _channel.QueueDeclareAsync(
                            queue: QueueName,
                            durable: true,
                            exclusive: false,
                            autoDelete: false);

                        _logger.LogInformation("RabbitMQPublisher spojen na broker.");
                        return;
                    }
                    catch (Exception ex)
                    {
                        _logger.LogWarning("RabbitMQ veza nije uspostavljena, pokušaj {Attempt}/5: {Message}", attempt, ex.Message);
                        if (attempt < 5)
                            await Task.Delay(TimeSpan.FromSeconds(Math.Pow(2, attempt)));
                    }
                }

                _logger.LogError("Nije moguće spojiti se na RabbitMQ nakon 5 pokušaja.");
            }
            finally
            {
                _lock.Release();
            }
        }

        public async Task PublishAsync(NotificationMessage message)
        {
            try
            {
                await EnsureConnectedAsync();

                if (_channel == null)
                {
                    _logger.LogWarning("RabbitMQ kanal nedostupan; poruka neće biti objavljena.");
                    return;
                }

                var json = JsonSerializer.Serialize(message);
                var body = Encoding.UTF8.GetBytes(json);
                var props = new BasicProperties { Persistent = true };

                await _channel.BasicPublishAsync(
                    exchange: "",
                    routingKey: QueueName,
                    mandatory: false,
                    basicProperties: props,
                    body: body);

                _logger.LogInformation("Poruka objavljena na RabbitMQ za korisnika {UserId}.", message.UserId);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Greška pri objavljivanju poruke na RabbitMQ.");
            }
        }

        public void Dispose()
        {
            // Fire-and-forget close; resources will be reclaimed by GC / OS on process exit.
            // DisposeAsync is the proper path for callers that can await.
            _ = DisposeAsync().AsTask();
        }

        public async ValueTask DisposeAsync()
        {
            try { if (_channel != null) await _channel.CloseAsync(); } catch { }
            try { if (_connection != null) await _connection.CloseAsync(); } catch { }
            _lock.Dispose();
        }
    }
}
