using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace eRentaCar.API.Migrations
{
    /// <inheritdoc />
    public partial class AddReservationActivation : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Reservations_AspNetUsers_CancelledById",
                table: "Reservations");

            migrationBuilder.DropForeignKey(
                name: "FK_Reservations_AspNetUsers_CompletedById",
                table: "Reservations");

            migrationBuilder.AddColumn<DateTime>(
                name: "ActivatedAt",
                table: "Reservations",
                type: "datetime2",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "ActivatedById",
                table: "Reservations",
                type: "int",
                nullable: true);

            migrationBuilder.CreateIndex(
                name: "IX_Reservations_ActivatedById",
                table: "Reservations",
                column: "ActivatedById");

            migrationBuilder.AddForeignKey(
                name: "FK_Reservations_AspNetUsers_ActivatedById",
                table: "Reservations",
                column: "ActivatedById",
                principalTable: "AspNetUsers",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);

            migrationBuilder.AddForeignKey(
                name: "FK_Reservations_AspNetUsers_CancelledById",
                table: "Reservations",
                column: "CancelledById",
                principalTable: "AspNetUsers",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);

            migrationBuilder.AddForeignKey(
                name: "FK_Reservations_AspNetUsers_CompletedById",
                table: "Reservations",
                column: "CompletedById",
                principalTable: "AspNetUsers",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Reservations_AspNetUsers_ActivatedById",
                table: "Reservations");

            migrationBuilder.DropForeignKey(
                name: "FK_Reservations_AspNetUsers_CancelledById",
                table: "Reservations");

            migrationBuilder.DropForeignKey(
                name: "FK_Reservations_AspNetUsers_CompletedById",
                table: "Reservations");

            migrationBuilder.DropIndex(
                name: "IX_Reservations_ActivatedById",
                table: "Reservations");

            migrationBuilder.DropColumn(
                name: "ActivatedAt",
                table: "Reservations");

            migrationBuilder.DropColumn(
                name: "ActivatedById",
                table: "Reservations");

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
    }
}
