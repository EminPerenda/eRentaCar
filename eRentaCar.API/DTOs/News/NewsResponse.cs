namespace eRentaCar.API.DTOs.News
{
    public class NewsResponse
    {
        public int Id { get; set; }
        public string Title { get; set; } = null!;
        public string Content { get; set; } = null!;
        public string? ImageUrl { get; set; }
        public DateTime PublishedAt { get; set; }
        public string Author { get; set; } = null!;
        public bool IsVisible { get; set; }
    }
}