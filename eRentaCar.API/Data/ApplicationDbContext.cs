using eRentaCar.API.Models;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Identity.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore;
using System.Collections.Generic;
using System.Reflection.Emit;

namespace eRentaCar.API.Data
{
    public class ApplicationDbContext : IdentityDbContext<ApplicationUser, IdentityRole<int>, int>
    {
        public ApplicationDbContext(DbContextOptions<ApplicationDbContext> options) : base(options) { }

        public DbSet<Country> Countries { get; set; }
        public DbSet<City> Cities { get; set; }
        public DbSet<VehicleCategory> VehicleCategories { get; set; }
        public DbSet<VehicleBrand> VehicleBrands { get; set; }
        public DbSet<FuelType> FuelTypes { get; set; }
        public DbSet<Transmission> Transmissions { get; set; }
        public DbSet<Location> Locations { get; set; }
        public DbSet<Vehicle> Vehicles { get; set; }
        public DbSet<VehicleImage> VehicleImages { get; set; }
        public DbSet<ExtraService> ExtraServices { get; set; }
        public DbSet<Payment> Payments { get; set; }
        public DbSet<Reservation> Reservations { get; set; }
        public DbSet<ReservationExtra> ReservationExtras { get; set; }
        public DbSet<VehicleReview> VehicleReviews { get; set; }
        public DbSet<Notification> Notifications { get; set; }
        public DbSet<News> News { get; set; }
        public DbSet<SearchHistory> SearchHistories { get; set; }
        public DbSet<PasswordResetToken> PasswordResetTokens { get; set; }

        protected override void OnModelCreating(ModelBuilder builder)
        {
            base.OnModelCreating(builder);

            // ---------- ApplicationUser ----------
            builder.Entity<ApplicationUser>(e =>
            {
                e.Property(x => x.FirstName).IsRequired().HasMaxLength(50);
                e.Property(x => x.LastName).IsRequired().HasMaxLength(50);
                e.Property(x => x.DriverLicenseNo).HasMaxLength(20);
                e.Property(x => x.RowVersion).IsRowVersion();

                e.HasOne(x => x.City)
                    .WithMany()
                    .HasForeignKey(x => x.CityId)
                    .OnDelete(DeleteBehavior.Restrict);
            });

            // ---------- Country ----------
            builder.Entity<Country>(e =>
            {
                e.Property(x => x.Name).IsRequired().HasMaxLength(80);
                e.Property(x => x.Code).IsRequired().HasMaxLength(3);
                e.HasIndex(x => x.Code).IsUnique();
                e.HasIndex(x => x.Name).IsUnique();
            });

            // ---------- City ----------
            builder.Entity<City>(e =>
            {
                e.Property(x => x.Name).IsRequired().HasMaxLength(80);

                e.HasOne(x => x.Country)
                    .WithMany(x => x.Cities)
                    .HasForeignKey(x => x.CountryId)
                    .OnDelete(DeleteBehavior.Restrict);
            });

            // ---------- VehicleCategory ----------
            builder.Entity<VehicleCategory>(e =>
            {
                e.Property(x => x.Name).IsRequired().HasMaxLength(80);
                e.HasIndex(x => x.Name).IsUnique();
            });

            // ---------- VehicleBrand ----------
            builder.Entity<VehicleBrand>(e =>
            {
                e.Property(x => x.Name).IsRequired().HasMaxLength(80);
                e.HasIndex(x => x.Name).IsUnique();
            });

            // ---------- FuelType ----------
            builder.Entity<FuelType>(e =>
            {
                e.Property(x => x.Name).IsRequired().HasMaxLength(50);
                e.HasIndex(x => x.Name).IsUnique();
            });

            // ---------- Transmission ----------
            builder.Entity<Transmission>(e =>
            {
                e.Property(x => x.Name).IsRequired().HasMaxLength(50);
                e.HasIndex(x => x.Name).IsUnique();
            });

            // ---------- Location ----------
            builder.Entity<Location>(e =>
            {
                e.Property(x => x.Name).IsRequired().HasMaxLength(100);
                e.Property(x => x.Address).IsRequired().HasMaxLength(200);
                e.Property(x => x.Phone).HasMaxLength(20);
                e.Property(x => x.WorkingHours).HasMaxLength(80);
                e.Property(x => x.Latitude).HasColumnType("decimal(9,6)");
                e.Property(x => x.Longitude).HasColumnType("decimal(9,6)");
                e.Property(x => x.RowVersion).IsRowVersion();

                e.HasOne(x => x.City)
                    .WithMany()
                    .HasForeignKey(x => x.CityId)
                    .OnDelete(DeleteBehavior.Restrict);
            });

            // ---------- Vehicle ----------
            builder.Entity<Vehicle>(e =>
            {
                e.Property(x => x.LicensePlate).IsRequired().HasMaxLength(15);
                e.HasIndex(x => x.LicensePlate).IsUnique();
                e.Property(x => x.Model).IsRequired().HasMaxLength(80);
                e.Property(x => x.PricePerDay).HasColumnType("decimal(8,2)");
                e.Property(x => x.RowVersion).IsRowVersion();

                e.HasOne(x => x.Brand)
                    .WithMany(x => x.Vehicles)
                    .HasForeignKey(x => x.BrandId)
                    .OnDelete(DeleteBehavior.Restrict);

                e.HasOne(x => x.Category)
                    .WithMany(x => x.Vehicles)
                    .HasForeignKey(x => x.CategoryId)
                    .OnDelete(DeleteBehavior.Restrict);

                e.HasOne(x => x.FuelType)
                    .WithMany(x => x.Vehicles)
                    .HasForeignKey(x => x.FuelTypeId)
                    .OnDelete(DeleteBehavior.Restrict);

                e.HasOne(x => x.Transmission)
                    .WithMany(x => x.Vehicles)
                    .HasForeignKey(x => x.TransmissionId)
                    .OnDelete(DeleteBehavior.Restrict);

                e.HasOne(x => x.CurrentLocation)
                    .WithMany(x => x.Vehicles)
                    .HasForeignKey(x => x.CurrentLocationId)
                    .OnDelete(DeleteBehavior.Restrict);
            });

            // ---------- VehicleImage ----------
            builder.Entity<VehicleImage>(e =>
            {
                e.Property(x => x.ImageUrl).IsRequired();

                e.HasOne(x => x.Vehicle)
                    .WithMany(x => x.Images)
                    .HasForeignKey(x => x.VehicleId)
                    .OnDelete(DeleteBehavior.Cascade);
            });

            // ---------- ExtraService ----------
            builder.Entity<ExtraService>(e =>
            {
                e.Property(x => x.Name).IsRequired().HasMaxLength(80);
                e.HasIndex(x => x.Name).IsUnique();
                e.Property(x => x.PricePerDay).HasColumnType("decimal(8,2)");
                e.Property(x => x.RowVersion).IsRowVersion();
            });

            // ---------- Payment ----------
            builder.Entity<Payment>(e =>
            {
                e.Property(x => x.Amount).HasColumnType("decimal(8,2)");
                e.Property(x => x.RefundAmount).HasColumnType("decimal(8,2)");
                e.Property(x => x.PaymentIntentId).IsRequired();
                e.HasIndex(x => x.PaymentIntentId).IsUnique();

                e.HasOne(x => x.User)
                    .WithMany()
                    .HasForeignKey(x => x.UserId)
                    .OnDelete(DeleteBehavior.Restrict);
            });

            // ---------- Reservation ----------
            builder.Entity<Reservation>(e =>
            {
                e.Property(x => x.BasePrice).HasColumnType("decimal(8,2)");
                e.Property(x => x.ExtrasPrice).HasColumnType("decimal(8,2)");
                e.Property(x => x.TotalPrice).HasColumnType("decimal(8,2)");
                e.Property(x => x.RowVersion).IsRowVersion();

                e.HasOne(x => x.User)
                    .WithMany(x => x.Reservations)
                    .HasForeignKey(x => x.UserId)
                    .OnDelete(DeleteBehavior.Restrict);

                e.HasOne(x => x.Vehicle)
                    .WithMany(x => x.Reservations)
                    .HasForeignKey(x => x.VehicleId)
                    .OnDelete(DeleteBehavior.Restrict);

                e.HasOne(x => x.PickupLocation)
                    .WithMany()
                    .HasForeignKey(x => x.PickupLocationId)
                    .OnDelete(DeleteBehavior.Restrict);

                e.HasOne(x => x.DropoffLocation)
                    .WithMany()
                    .HasForeignKey(x => x.DropoffLocationId)
                    .OnDelete(DeleteBehavior.Restrict);

                e.HasOne(x => x.Payment)
                    .WithOne(x => x.Reservation)
                    .HasForeignKey<Reservation>(x => x.PaymentId)
                    .OnDelete(DeleteBehavior.Restrict);

                e.HasOne(x => x.ApprovedBy)
                    .WithMany()
                    .HasForeignKey(x => x.ApprovedById)
                    .OnDelete(DeleteBehavior.Restrict);

                e.HasOne(x => x.CancelledBy)
                    .WithMany()
                    .HasForeignKey(x => x.CancelledById)
                    .OnDelete(DeleteBehavior.Restrict);

                e.HasOne(x => x.CompletedBy)
                    .WithMany()
                    .HasForeignKey(x => x.CompletedById)
                    .OnDelete(DeleteBehavior.Restrict);

                e.HasOne(x => x.ActivatedBy)
                    .WithMany()
                    .HasForeignKey(x => x.ActivatedById)
                    .OnDelete(DeleteBehavior.Restrict);
            });

            // ---------- ReservationExtra ----------
            builder.Entity<ReservationExtra>(e =>
            {
                e.Property(x => x.PriceAtTime).HasColumnType("decimal(8,2)");

                e.HasOne(x => x.Reservation)
                    .WithMany(x => x.Extras)
                    .HasForeignKey(x => x.ReservationId)
                    .OnDelete(DeleteBehavior.Cascade);

                e.HasOne(x => x.ExtraService)
                    .WithMany(x => x.ReservationExtras)
                    .HasForeignKey(x => x.ExtraServiceId)
                    .OnDelete(DeleteBehavior.Restrict);
            });

            // ---------- VehicleReview ----------
            builder.Entity<VehicleReview>(e =>
            {
                e.Property(x => x.Rating).IsRequired();
                e.ToTable(t => t.HasCheckConstraint("CK_VehicleReview_Rating", "[Rating] >= 1 AND [Rating] <= 5"));

                e.HasOne(x => x.User)
                    .WithMany(x => x.Reviews)
                    .HasForeignKey(x => x.UserId)
                    .OnDelete(DeleteBehavior.Restrict);

                e.HasOne(x => x.Vehicle)
                    .WithMany(x => x.Reviews)
                    .HasForeignKey(x => x.VehicleId)
                    .OnDelete(DeleteBehavior.Restrict);

                e.HasOne(x => x.Reservation)
                    .WithOne(x => x.Review)
                    .HasForeignKey<VehicleReview>(x => x.ReservationId)
                    .OnDelete(DeleteBehavior.Restrict);
            });

            // ---------- Notification ----------
            builder.Entity<Notification>(e =>
            {
                e.Property(x => x.Title).IsRequired().HasMaxLength(150);
                e.Property(x => x.Message).IsRequired();

                e.HasOne(x => x.User)
                    .WithMany(x => x.Notifications)
                    .HasForeignKey(x => x.UserId)
                    .OnDelete(DeleteBehavior.Cascade);
            });

            // ---------- News ----------
            builder.Entity<News>(e =>
            {
                e.Property(x => x.Title).IsRequired().HasMaxLength(200);
                e.Property(x => x.Content).IsRequired();
                e.Property(x => x.RowVersion).IsRowVersion();

                e.HasOne(x => x.Author)
                    .WithMany()
                    .HasForeignKey(x => x.AuthorId)
                    .OnDelete(DeleteBehavior.Restrict);
            });

            // ---------- SearchHistory ----------
            builder.Entity<SearchHistory>(e =>
            {
                e.HasOne(x => x.User)
                    .WithMany(x => x.SearchHistories)
                    .HasForeignKey(x => x.UserId)
                    .OnDelete(DeleteBehavior.Cascade);

                e.HasOne(x => x.Vehicle)
                    .WithMany(x => x.SearchHistories)
                    .HasForeignKey(x => x.VehicleId)
                    .OnDelete(DeleteBehavior.Restrict);

                e.HasOne(x => x.Category)
                    .WithMany()
                    .HasForeignKey(x => x.CategoryId)
                    .OnDelete(DeleteBehavior.Restrict);
            });
        }
    }
}