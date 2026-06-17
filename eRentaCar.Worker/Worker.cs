using eRentaCar.Worker.Models;
using eRentaCar.Worker.Services;
using RabbitMQ.Client;
using RabbitMQ.Client.Events;
using System.Collections.Concurrent;
using System.Text;
using System.Text.Json;

namespace eRentaCar.Worker
{
    public class Worker : BackgroundService
    {
        private readonly ILogger<Worker> _logger;
        private readonly EmailService _emailService;
        private IConnection? _connection;
        private IChannel? _channel;

        private const string QueueName = "notifications";
        private const int MaxRetries = 3;

        // Tracks delivery attempt counts for messages that keep failing
        private readonly ConcurrentDictionary<ulong, int> _retryCounts = new();

        public Worker(ILogger<Worker> logger, EmailService emailService)
        {
            _logger = logger;
            _emailService = emailService;
        }

        public override async Task StartAsync(CancellationToken cancellationToken)
        {
            await InitializeRabbitMqAsync();
            await base.StartAsync(cancellationToken);
        }

        private async Task InitializeRabbitMqAsync()
        {
            var host = Environment.GetEnvironmentVariable("RABBITMQ_HOST") ?? "localhost";
            var port = int.Parse(Environment.GetEnvironmentVariable("RABBITMQ_PORT") ?? "5672");
            var username = Environment.GetEnvironmentVariable("RABBITMQ_USERNAME") ?? "guest";
            var password = Environment.GetEnvironmentVariable("RABBITMQ_PASSWORD") ?? "guest";

            var factory = new ConnectionFactory
            {
                HostName = host,
                Port = port,
                UserName = username,
                Password = password
            };

            var retries = 0;
            while (retries < 5)
            {
                try
                {
                    _connection = await factory.CreateConnectionAsync();
                    _channel = await _connection.CreateChannelAsync();

                    await _channel.QueueDeclareAsync(
                        queue: QueueName,
                        durable: true,
                        exclusive: false,
                        autoDelete: false);

                    _logger.LogInformation("Worker spojen na RabbitMQ.");
                    return;
                }
                catch (Exception ex)
                {
                    retries++;
                    _logger.LogWarning("RabbitMQ nije dostupan, pokušaj {Retry}/5. Greška: {Message}", retries, ex.Message);
                    await Task.Delay(TimeSpan.FromSeconds(Math.Pow(2, retries)));
                }
            }

            _logger.LogError("Nije moguće spojiti se na RabbitMQ nakon 5 pokušaja.");
        }

        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {
            if (_channel == null)
            {
                _logger.LogError("RabbitMQ kanal nije inicijalizovan. Worker se gasi.");
                return;
            }

            var consumer = new AsyncEventingBasicConsumer(_channel);

            consumer.ReceivedAsync += async (sender, args) =>
            {
                var deliveryTag = args.DeliveryTag;
                try
                {
                    var body = args.Body.ToArray();
                    var json = Encoding.UTF8.GetString(body);
                    var message = JsonSerializer.Deserialize<NotificationMessage>(json);

                    if (message == null)
                    {
                        _logger.LogWarning("Primljena neispravna poruka iz RabbitMQ-a.");
                        await _channel.BasicAckAsync(deliveryTag, false);
                        return;
                    }

                    _logger.LogInformation("Obrada notifikacije za korisnika {UserId}: {Title}", message.UserId, message.Title);

                    if (!string.IsNullOrEmpty(message.Email))
                    {
                        await _emailService.SendAsync(
                            message.Email,
                            message.Title,
                            $"<h2>{message.Title}</h2><p>{message.Message}</p><br><p>eRentaCar tim</p>"
                        );
                    }

                    _retryCounts.TryRemove(deliveryTag, out _);
                    await _channel.BasicAckAsync(deliveryTag, false);
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Greška pri obradi poruke iz RabbitMQ-a.");

                    var attempts = _retryCounts.AddOrUpdate(deliveryTag, 1, (_, count) => count + 1);

                    if (attempts >= MaxRetries)
                    {
                        _logger.LogError("Poruka odbačena nakon {MaxRetries} pokušaja (deliveryTag={Tag}).", MaxRetries, deliveryTag);
                        _retryCounts.TryRemove(deliveryTag, out _);
                        await _channel.BasicNackAsync(deliveryTag, false, requeue: false);
                    }
                    else
                    {
                        await Task.Delay(TimeSpan.FromSeconds(Math.Pow(2, attempts)));
                        await _channel.BasicNackAsync(deliveryTag, false, requeue: true);
                    }
                }
            };

            await _channel.BasicConsumeAsync(
                queue: QueueName,
                autoAck: false,
                consumer: consumer);

            _logger.LogInformation("Worker čeka poruke iz RabbitMQ-a...");

            while (!stoppingToken.IsCancellationRequested)
                await Task.Delay(1000, stoppingToken);
        }

        public override async Task StopAsync(CancellationToken cancellationToken)
        {
            if (_channel != null) await _channel.CloseAsync();
            if (_connection != null) await _connection.CloseAsync();
            _logger.LogInformation("Worker zaustavljen.");
            await base.StopAsync(cancellationToken);
        }
    }
}
