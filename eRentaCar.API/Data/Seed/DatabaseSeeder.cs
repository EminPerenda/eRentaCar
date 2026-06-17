using eRentaCar.API.Constants;
using eRentaCar.API.Enums;
using eRentaCar.API.Models;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;

namespace eRentaCar.API.Data.Seed
{
    public static class DatabaseSeeder
    {
        public static async Task SeedAsync(ApplicationDbContext context, UserManager<ApplicationUser> userManager, RoleManager<IdentityRole<int>> roleManager)
        {
            // ---------- Roles ----------
            string[] roles = { AppRoles.Admin, AppRoles.Client };
            foreach (var role in roles)
            {
                if (!await roleManager.RoleExistsAsync(role))
                    await roleManager.CreateAsync(new IdentityRole<int>(role));
            }

            // ---------- Countries ----------
            if (!await context.Countries.AnyAsync())
            {
                context.Countries.AddRange(
                    new Country { Name = "Bosna i Hercegovina", Code = "BA" },
                    new Country { Name = "Hrvatska", Code = "HR" },
                    new Country { Name = "Srbija", Code = "RS" },
                    new Country { Name = "Crna Gora", Code = "ME" }
                );
                await context.SaveChangesAsync();
            }

            // ---------- Cities ----------
            if (!await context.Cities.AnyAsync())
            {
                var ba = await context.Countries.FirstAsync(x => x.Code == "BA");
                var hr = await context.Countries.FirstAsync(x => x.Code == "HR");

                context.Cities.AddRange(
                    new City { Name = "Sarajevo", CountryId = ba.Id },
                    new City { Name = "Mostar", CountryId = ba.Id },
                    new City { Name = "Banja Luka", CountryId = ba.Id },
                    new City { Name = "Tuzla", CountryId = ba.Id },
                    new City { Name = "Zenica", CountryId = ba.Id },
                    new City { Name = "Zagreb", CountryId = hr.Id },
                    new City { Name = "Split", CountryId = hr.Id }
                );
                await context.SaveChangesAsync();
            }

            // ---------- Vehicle Categories ----------
            if (!await context.VehicleCategories.AnyAsync())
            {
                context.VehicleCategories.AddRange(
                    new VehicleCategory { Name = "Mali automobil", Description = "Ekonomični gradski automobili" },
                    new VehicleCategory { Name = "Kompaktni", Description = "Kompaktni automobili za svakodnevnu upotrebu" },
                    new VehicleCategory { Name = "SUV", Description = "Sportska terenska vozila" },
                    new VehicleCategory { Name = "Luksuzni", Description = "Luksuzni automobili premium klase" },
                    new VehicleCategory { Name = "Kombi", Description = "Kombiji i minivani za veće grupe" }
                );
                await context.SaveChangesAsync();
            }

            // ---------- Vehicle Brands ----------
            if (!await context.VehicleBrands.AnyAsync())
            {
                context.VehicleBrands.AddRange(
                    new VehicleBrand { Name = "Volkswagen" },
                    new VehicleBrand { Name = "BMW" },
                    new VehicleBrand { Name = "Mercedes-Benz" },
                    new VehicleBrand { Name = "Toyota" },
                    new VehicleBrand { Name = "Škoda" },
                    new VehicleBrand { Name = "Peugeot" },
                    new VehicleBrand { Name = "Ford" },
                    new VehicleBrand { Name = "Audi" }
                );
                await context.SaveChangesAsync();
            }

            // ---------- Fuel Types ----------
            if (!await context.FuelTypes.AnyAsync())
            {
                context.FuelTypes.AddRange(
                    new FuelType { Name = "Benzin" },
                    new FuelType { Name = "Dizel" },
                    new FuelType { Name = "Hibrid" },
                    new FuelType { Name = "Električni" },
                    new FuelType { Name = "Plin" }
                );
                await context.SaveChangesAsync();
            }

            // ---------- Transmissions ----------
            if (!await context.Transmissions.AnyAsync())
            {
                context.Transmissions.AddRange(
                    new Transmission { Name = "Manuelni" },
                    new Transmission { Name = "Automatski" },
                    new Transmission { Name = "Poluautomatski" }
                );
                await context.SaveChangesAsync();
            }

            // ---------- Extra Services ----------
            if (!await context.ExtraServices.AnyAsync())
            {
                context.ExtraServices.AddRange(
                    new ExtraService { Name = "GPS navigacija", Description = "Uređaj za navigaciju u vozilu", PricePerDay = 5 },
                    new ExtraService { Name = "Dječije sjedalo", Description = "Sigurnosno sjedalo za djecu do 18kg", PricePerDay = 4 },
                    new ExtraService { Name = "Puno kasko osiguranje", Description = "Potpuno osiguranje vozila bez franšize", PricePerDay = 15 },
                    new ExtraService { Name = "Zimske gume", Description = "Vozilo opremljeno zimskim gumama", PricePerDay = 8 },
                    new ExtraService { Name = "Nosač za bicikle", Description = "Nosač za prijevoz bicikala", PricePerDay = 6 }
                );
                await context.SaveChangesAsync();
            }

            // ---------- Locations ----------
            if (!await context.Locations.AnyAsync())
            {
                var sarajevo = await context.Cities.FirstAsync(x => x.Name == "Sarajevo");
                var mostar = await context.Cities.FirstAsync(x => x.Name == "Mostar");
                var banjaLuka = await context.Cities.FirstAsync(x => x.Name == "Banja Luka");

                context.Locations.AddRange(
                    new Location
                    {
                        Name = "Sarajevo - Aerodrom",
                        Address = "Kurta Schorka 36",
                        CityId = sarajevo.Id,
                        Phone = "+387 33 289 100",
                        WorkingHours = "Pon-Ned 06:00-22:00",
                        Latitude = 43.824683m,
                        Longitude = 18.331383m
                    },
                    new Location
                    {
                        Name = "Sarajevo - Centar",
                        Address = "Ferhadija 12",
                        CityId = sarajevo.Id,
                        Phone = "+387 33 555 100",
                        WorkingHours = "Pon-Pet 08:00-20:00",
                        Latitude = 43.859748m,
                        Longitude = 18.432617m
                    },
                    new Location
                    {
                        Name = "Mostar - Centar",
                        Address = "Bulevar narodne revolucije 4",
                        CityId = mostar.Id,
                        Phone = "+387 36 555 200",
                        WorkingHours = "Pon-Sub 08:00-18:00",
                        Latitude = 43.343472m,
                        Longitude = 17.807885m
                    },
                    new Location
                    {
                        Name = "Banja Luka - Centar",
                        Address = "Kralja Petra I Karađorđevića 5",
                        CityId = banjaLuka.Id,
                        Phone = "+387 51 555 300",
                        WorkingHours = "Pon-Pet 08:00-18:00",
                        Latitude = 44.772183m,
                        Longitude = 17.191000m
                    }
                );
                await context.SaveChangesAsync();
            }

            // ---------- Admin User ----------
            if (await userManager.FindByNameAsync("admin@erentacar.ba") == null)
            {
                var sarajevo = await context.Cities.FirstAsync(x => x.Name == "Sarajevo");

                var admin = new ApplicationUser
                {
                    UserName = "admin@erentacar.ba",
                    Email = "admin@erentacar.ba",
                    FirstName = "Admin",
                    LastName = "eRentaCar",
                    CityId = sarajevo.Id,
                    IsActive = true,
                    EmailConfirmed = true
                };

                await userManager.CreateAsync(admin, "Admin1234!");
                await userManager.AddToRoleAsync(admin, AppRoles.Admin);
            }

            // ---------- Desktop Test Admin ----------
            if (await userManager.FindByNameAsync("desktop@test.com") == null)
            {
                var sarajevo = await context.Cities.FirstAsync(x => x.Name == "Sarajevo");

                var desktopAdmin = new ApplicationUser
                {
                    UserName = "desktop@test.com",
                    Email = "desktop@test.com",
                    FirstName = "Desktop",
                    LastName = "Admin",
                    CityId = sarajevo.Id,
                    IsActive = true,
                    EmailConfirmed = true
                };

                await userManager.CreateAsync(desktopAdmin, "Test1234!");
                await userManager.AddToRoleAsync(desktopAdmin, AppRoles.Admin);
            }

            // ---------- Test Client ----------
            if (await userManager.FindByNameAsync("klijent@erentacar.ba") == null)
            {
                var sarajevo = await context.Cities.FirstAsync(x => x.Name == "Sarajevo");

                var client = new ApplicationUser
                {
                    UserName = "klijent@erentacar.ba",
                    Email = "klijent@erentacar.ba",
                    FirstName = "Test",
                    LastName = "Klijent",
                    CityId = sarajevo.Id,
                    IsActive = true,
                    EmailConfirmed = true,
                    DriverLicenseNo = "BA123456"
                };

                await userManager.CreateAsync(client, "Klijent1234!");
                await userManager.AddToRoleAsync(client, AppRoles.Client);
            }

            // ---------- Mobile Test Client ----------
            if (await userManager.FindByNameAsync("mobile@test.com") == null)
            {
                var sarajevo = await context.Cities.FirstAsync(x => x.Name == "Sarajevo");

                var mobileClient = new ApplicationUser
                {
                    UserName = "mobile@test.com",
                    Email = "mobile@test.com",
                    FirstName = "Mobile",
                    LastName = "Klijent",
                    CityId = sarajevo.Id,
                    IsActive = true,
                    EmailConfirmed = true,
                    DriverLicenseNo = "BA654321"
                };

                await userManager.CreateAsync(mobileClient, "Test1234!");
                await userManager.AddToRoleAsync(mobileClient, AppRoles.Client);
            }

            // ---------- Vehicles ----------
            if (!await context.Vehicles.AnyAsync())
            {
                var vw = await context.VehicleBrands.FirstAsync(x => x.Name == "Volkswagen");
                var bmw = await context.VehicleBrands.FirstAsync(x => x.Name == "BMW");
                var toyota = await context.VehicleBrands.FirstAsync(x => x.Name == "Toyota");
                var skoda = await context.VehicleBrands.FirstAsync(x => x.Name == "Škoda");
                var mercedes = await context.VehicleBrands.FirstAsync(x => x.Name == "Mercedes-Benz");

                var kompaktni = await context.VehicleCategories.FirstAsync(x => x.Name == "Kompaktni");
                var suv = await context.VehicleCategories.FirstAsync(x => x.Name == "SUV");
                var mali = await context.VehicleCategories.FirstAsync(x => x.Name == "Mali automobil");
                var luksuzni = await context.VehicleCategories.FirstAsync(x => x.Name == "Luksuzni");

                var benzin = await context.FuelTypes.FirstAsync(x => x.Name == "Benzin");
                var dizel = await context.FuelTypes.FirstAsync(x => x.Name == "Dizel");
                var hibrid = await context.FuelTypes.FirstAsync(x => x.Name == "Hibrid");

                var manual = await context.Transmissions.FirstAsync(x => x.Name == "Manuelni");
                var auto = await context.Transmissions.FirstAsync(x => x.Name == "Automatski");

                var sarajevoAero = await context.Locations.FirstAsync(x => x.Name == "Sarajevo - Aerodrom");
                var sarajevoCentar = await context.Locations.FirstAsync(x => x.Name == "Sarajevo - Centar");
                var mostar = await context.Locations.FirstAsync(x => x.Name == "Mostar - Centar");

                context.Vehicles.AddRange(
                    new Vehicle
                    {
                        LicensePlate = "A12-B-345",
                        BrandId = vw.Id,
                        Model = "Golf 8 1.5 TSI",
                        Year = 2023,
                        CategoryId = kompaktni.Id,
                        FuelTypeId = benzin.Id,
                        TransmissionId = manual.Id,
                        Seats = 5,
                        PricePerDay = 62,
                        Mileage = 28400,
                        Description = "Odlično stanje, klima, parking senzori.",
                        CurrentLocationId = sarajevoAero.Id
                    },
                    new Vehicle
                    {
                        LicensePlate = "E23-J-111",
                        BrandId = bmw.Id,
                        Model = "X5 xDrive30d",
                        Year = 2022,
                        CategoryId = suv.Id,
                        FuelTypeId = dizel.Id,
                        TransmissionId = auto.Id,
                        Seats = 5,
                        PricePerDay = 180,
                        Mileage = 41200,
                        Description = "Premium SUV, panoramski krov, kožna sjedišta.",
                        CurrentLocationId = sarajevoAero.Id
                    },
                    new Vehicle
                    {
                        LicensePlate = "K77-T-892",
                        BrandId = toyota.Id,
                        Model = "Yaris 1.5 Hybrid",
                        Year = 2024,
                        CategoryId = mali.Id,
                        FuelTypeId = hibrid.Id,
                        TransmissionId = auto.Id,
                        Seats = 5,
                        PricePerDay = 48,
                        Mileage = 8900,
                        Description = "Štedljiv hibridni pogon, idealan za grad.",
                        CurrentLocationId = sarajevoCentar.Id
                    },
                    new Vehicle
                    {
                        LicensePlate = "M45-O-667",
                        BrandId = skoda.Id,
                        Model = "Octavia 2.0 TDI",
                        Year = 2022,
                        CategoryId = kompaktni.Id,
                        FuelTypeId = dizel.Id,
                        TransmissionId = manual.Id,
                        Seats = 5,
                        PricePerDay = 55,
                        Mileage = 52000,
                        Description = "Prostrana kabina, veliki prtljažnik.",
                        CurrentLocationId = mostar.Id
                    },
                    new Vehicle
                    {
                        LicensePlate = "S99-A-001",
                        BrandId = mercedes.Id,
                        Model = "E 220d AMG Line",
                        Year = 2023,
                        CategoryId = luksuzni.Id,
                        FuelTypeId = dizel.Id,
                        TransmissionId = auto.Id,
                        Seats = 5,
                        PricePerDay = 220,
                        Mileage = 19500,
                        Description = "Luksuzna limuzina, masažna sjedišta, Burmester audio.",
                        CurrentLocationId = sarajevoAero.Id
                    }
                );
                await context.SaveChangesAsync();
            }
        }
    }
}