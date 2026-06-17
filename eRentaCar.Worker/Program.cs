using eRentaCar.Worker;
using eRentaCar.Worker.Services;
using Serilog;

var root = Directory.GetCurrentDirectory();
var envPath = Path.Combine(root, "..", ".env");

if (File.Exists(envPath))
{
    foreach (var line in File.ReadAllLines(envPath))
    {
        var trimmed = line.Trim();
        if (string.IsNullOrEmpty(trimmed) || trimmed.StartsWith("#")) continue;
        var index = trimmed.IndexOf('=');
        if (index < 0) continue;
        var key = trimmed[..index].Trim();
        var value = trimmed[(index + 1)..].Trim();
        Environment.SetEnvironmentVariable(key, value);
    }
}

Log.Logger = new LoggerConfiguration()
    .MinimumLevel.Information()
    .WriteTo.Console(outputTemplate: "[{Timestamp:HH:mm:ss} {Level:u3}] {Message:lj}{NewLine}{Exception}")
    .WriteTo.File(
        path: "logs/worker-.log",
        rollingInterval: RollingInterval.Day,
        retainedFileCountLimit: 14,
        outputTemplate: "[{Timestamp:yyyy-MM-dd HH:mm:ss} {Level:u3}] {Message:lj}{NewLine}{Exception}")
    .CreateLogger();

var builder = Host.CreateApplicationBuilder(args);
builder.Services.AddSerilog();

builder.Services.AddSingleton<EmailService>();
builder.Services.AddHostedService<Worker>();

var host = builder.Build();
host.Run();