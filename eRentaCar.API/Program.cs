using eRentaCar.API.Data;
using eRentaCar.API.Data.Seed;
using eRentaCar.API.Helpers;
using eRentaCar.API.Hubs;
using eRentaCar.API.Middleware;
using eRentaCar.API.Models;
using eRentaCar.API.Services;
using eRentaCar.API.Services.Interfaces;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Serilog;
using System.Text;



EnvHelper.Load(Path.Combine(Directory.GetCurrentDirectory(), "..", ".env"));

Log.Logger = new LoggerConfiguration()
    .MinimumLevel.Information()
    .MinimumLevel.Override("Microsoft.AspNetCore", Serilog.Events.LogEventLevel.Warning)
    .WriteTo.Console(outputTemplate: "[{Timestamp:HH:mm:ss} {Level:u3}] {Message:lj}{NewLine}{Exception}")
    .WriteTo.File(
        path: "logs/api-.log",
        rollingInterval: RollingInterval.Day,
        retainedFileCountLimit: 14,
        outputTemplate: "[{Timestamp:yyyy-MM-dd HH:mm:ss} {Level:u3}] {Message:lj}{NewLine}{Exception}")
    .CreateLogger();

static string? GetEnv(params string[] names)
{
    foreach (var name in names)
    {
        var value = Environment.GetEnvironmentVariable(name);
        if (!string.IsNullOrWhiteSpace(value))
            return value;
    }

    return null;
}

static string GetRequiredEnv(string errorMessage, params string[] names)
    => GetEnv(names) ?? throw new InvalidOperationException(errorMessage);

var builder = WebApplication.CreateBuilder(args);
builder.Host.UseSerilog();

var allowedOrigins = (Environment.GetEnvironmentVariable("ALLOWED_ORIGINS") ?? "*").Split(',');
builder.Services.AddCors(options =>
{
    options.AddPolicy("DefaultPolicy", policy =>
    {
        if (allowedOrigins.Length == 1 && allowedOrigins[0] == "*")
            policy.AllowAnyOrigin().AllowAnyHeader().AllowAnyMethod();
        else
            policy.WithOrigins(allowedOrigins).AllowAnyHeader().AllowAnyMethod().AllowCredentials();
    });
});

var connectionString = GetRequiredEnv(
    "CONNECTION_STRING nije postavljen u .env fajlu.",
    "CONNECTION_STRING",
    "ConnectionStrings__DefaultConnection");

builder.Services.AddDbContext<ApplicationDbContext>(options =>
    options.UseSqlServer(connectionString));

builder.Services.AddIdentity<ApplicationUser, IdentityRole<int>>(options =>
{
    options.Password.RequireDigit = true;
    options.Password.RequiredLength = 8;
    options.Password.RequireUppercase = false;
    options.Password.RequireNonAlphanumeric = false;
})
.AddEntityFrameworkStores<ApplicationDbContext>()
.AddDefaultTokenProviders();

builder.Services.AddSingleton<IWebHostEnvironment>(builder.Environment);
builder.Services.AddControllers();
builder.Services.AddSignalR();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(options =>
{
    var securityScheme = new Microsoft.OpenApi.Models.OpenApiSecurityScheme
    {
        Name = "Authorization",
        Type = Microsoft.OpenApi.Models.SecuritySchemeType.ApiKey,
        Scheme = "Bearer",
        BearerFormat = "JWT",
        In = Microsoft.OpenApi.Models.ParameterLocation.Header,
        Description = "Unesite token u formatu: Bearer {token}"
    };

    var securityRef = new Microsoft.OpenApi.Models.OpenApiSecurityScheme
    {
        Reference = new Microsoft.OpenApi.Models.OpenApiReference
        {
            Type = Microsoft.OpenApi.Models.ReferenceType.SecurityScheme,
            Id = "Bearer"
        }
    };

    options.AddSecurityDefinition("Bearer", securityScheme);
    options.AddSecurityRequirement(new Microsoft.OpenApi.Models.OpenApiSecurityRequirement
    {
        { securityRef, Array.Empty<string>() }
    });
});

var jwtKey = GetRequiredEnv(
    "JWT_KEY nije postavljen u .env fajlu.",
    "JWT_KEY",
    "JWT__Secret");

builder.Services.AddSingleton<ITokenRevocationService, TokenRevocationService>();

builder.Services.AddAuthentication(options =>
{
    options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
    options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
})
.AddJwtBearer(options =>
{
    options.TokenValidationParameters = new TokenValidationParameters
    {
        ValidateIssuerSigningKey = true,
        IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtKey)),
        ValidateIssuer = true,
        ValidIssuer = GetEnv("JWT_ISSUER", "JWT__Issuer"),
        ValidateAudience = true,
        ValidAudience = GetEnv("JWT_AUDIENCE", "JWT__Audience"),
        ValidateLifetime = true,
        ClockSkew = TimeSpan.Zero
    };
    options.Events = new JwtBearerEvents
    {
        OnTokenValidated = context =>
        {
            var revocation = context.HttpContext.RequestServices
                .GetRequiredService<ITokenRevocationService>();
            var jti = context.Principal?.FindFirst(System.IdentityModel.Tokens.Jwt.JwtRegisteredClaimNames.Jti)?.Value;
            if (jti != null && revocation.IsRevoked(jti))
                context.Fail("Token je opozvan.");
            return Task.CompletedTask;
        }
    };
});

builder.Services.AddMemoryCache();

var stripeKey = GetEnv("STRIPE_SECRET_KEY", "Stripe__SecretKey");
if (!string.IsNullOrWhiteSpace(stripeKey))
    global::Stripe.StripeConfiguration.ApiKey = stripeKey;

builder.Services.AddScoped<ITokenService, TokenService>();
builder.Services.AddScoped<IVehicleService, VehicleService>();
builder.Services.AddScoped<IReservationService, ReservationService>();
builder.Services.AddScoped<ILocationService, LocationService>();
builder.Services.AddScoped<IUserService, UserService>();
builder.Services.AddScoped<INotificationService, NotificationService>();
builder.Services.AddScoped<INewsService, NewsService>();
builder.Services.AddScoped<IReviewService, ReviewService>();
builder.Services.AddScoped<ISearchHistoryService, SearchHistoryService>();
builder.Services.AddScoped<IPasswordResetService, PasswordResetService>();
builder.Services.AddScoped<IPaymentService, PaymentService>();
builder.Services.AddScoped<IReportsService, ReportsService>();
builder.Services.AddScoped<IReferenceService, ReferenceService>();
builder.Services.AddScoped<IVehicleImageService, VehicleImageService>();
builder.Services.AddSingleton<RabbitMQPublisher>();
builder.Services.AddSingleton<EmailService>();

var app = builder.Build();

app.UseMiddleware<ExceptionMiddleware>();

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseStaticFiles();
app.UseCors("DefaultPolicy");
app.UseAuthentication();
app.UseAuthorization();
app.MapHub<NotificationHub>("/hubs/notifications");
app.MapControllers();
using (var scope = app.Services.CreateScope())
{
    var context = scope.ServiceProvider.GetRequiredService<ApplicationDbContext>();
    var userManager = scope.ServiceProvider.GetRequiredService<UserManager<ApplicationUser>>();
    var roleManager = scope.ServiceProvider.GetRequiredService<RoleManager<IdentityRole<int>>>();
    await DatabaseSeeder.SeedAsync(context, userManager, roleManager);
}
app.Run();