using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace eRentaCar.API.Migrations
{
    /// <inheritdoc />
    public partial class HardenPasswordResetTokens : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql("DELETE FROM PasswordResetTokens;");

            migrationBuilder.AddColumn<int>(
                name: "AttemptCount",
                table: "PasswordResetTokens",
                type: "int",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<DateTime>(
                name: "CreatedAt",
                table: "PasswordResetTokens",
                type: "datetime2",
                nullable: false,
                defaultValue: new DateTime(1, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified));

            migrationBuilder.AddColumn<string>(
                name: "TokenSalt",
                table: "PasswordResetTokens",
                type: "nvarchar(max)",
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<DateTime>(
                name: "UsedAt",
                table: "PasswordResetTokens",
                type: "datetime2",
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "AttemptCount",
                table: "PasswordResetTokens");

            migrationBuilder.DropColumn(
                name: "CreatedAt",
                table: "PasswordResetTokens");

            migrationBuilder.DropColumn(
                name: "TokenSalt",
                table: "PasswordResetTokens");

            migrationBuilder.DropColumn(
                name: "UsedAt",
                table: "PasswordResetTokens");
        }
    }
}
