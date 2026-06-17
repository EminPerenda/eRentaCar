using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace eRentaCar.API.Migrations
{
    /// <inheritdoc />
    public partial class AddReservationIdToPayment : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<int>(
                name: "ReservationId",
                table: "Payments",
                type: "int",
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "ReservationId",
                table: "Payments");
        }
    }
}
