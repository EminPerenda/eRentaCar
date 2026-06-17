namespace eRentaCar.API.DTOs.News
{
    public class NewsRequest
    {
        public string Title { get; set; } = null!;
        public string Content { get; set; } = null!;
        public string? ImageUrl { get; set; }
        public bool IsVisible { get; set; } = true;
    }
}