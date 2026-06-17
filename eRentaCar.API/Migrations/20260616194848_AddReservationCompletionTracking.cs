using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace eRentaCar.API.Migrations
{
    /// <inheritdoc />
    public partial class AddReservationCompletionTracking : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<DateTime>(
                name: "CancelledAt",
                table: "Reservations",
                type: "datetime2",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "CancelledById",
                table: "Reservations",
                type: "int",
                nullable: true);

            migrationBuilder.AddColumn<DateTime>(
                name: "CompletedAt",
                table: "Reservations",
                type: "datetime2",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "CompletedById",
                table: "Reservations",
                type: "int",
                nullable: true);

            migrationBuilder.CreateIndex(
                name: "IX_Reservations_CancelledById",
                table: "Reservations",
                column: "CancelledById");

            migrationBuilder.CreateIndex(
                name: "IX_Reservations_CompletedById",
                table: "Reservations",
                column: "CompletedById");

            migrationBuilder.AddForeignKey(
                name: "FK_Reservations_AspNetUsers_CancelledById",
                table: "Reservations",
                column: "CancelledById",
                principalTable: "AspNetUsers",
                principalColumn: "Id");

            migrationBuilder.AddForeignKey(
                name: "FK_Reservations_AspNetUsers_CompletedById",
                table: "Reservations",
                column: "CompletedById",
                principalTable: "AspNetUsers",
                principalColumn: "Id");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Reservations_AspNetUsers_CancelledById",
                table: "Reservations");

            migrationBuilder.DropForeignKey(
                name: "FK_Reservations_AspNetUsers_CompletedById",
                table: "Reservations");

            migrationBuilder.DropIndex(
                name: "IX_Reservations_CancelledById",
                table: "Reservations");

            migrationBuilder.DropIndex(
                name: "IX_Reservations_CompletedById",
                table: "Reservations");

            migrationBuilder.DropColumn(
                name: "CancelledAt",
                table: "Reservations");

            migrationBuilder.DropColumn(
                name: "CancelledById",
                table: "Reservations");

            migrationBuilder.DropColumn(
                name: "CompletedAt",
                table: "Reservations");

            migrationBuilder.DropColumn(
                name: "CompletedById",
                table: "Reservations");
        }
    }
}
