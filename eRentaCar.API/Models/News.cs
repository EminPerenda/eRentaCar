namespace eRentaCar.API.Models
{
    public class News
    {
        public int Id { get; set; }
        public string Title { get; set; } = null!;
        public string Content { get; set; } = null!;
        public string? ImageUrl { get; set; }
        public DateTime PublishedAt { get; set; } = DateTime.UtcNow;
        public int AuthorId { get; set; }
        public bool IsVisible { get; set; } = true;
        public byte[] RowVersion { get; set; } = null!;

        public ApplicationUser Author { get; set; } = null!;
    }
}