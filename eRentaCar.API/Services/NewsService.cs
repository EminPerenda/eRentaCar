using eRentaCar.API.Data;
using eRentaCar.API.DTOs;
using eRentaCar.API.DTOs.News;
using eRentaCar.API.Exceptions;
using eRentaCar.API.Models;
using eRentaCar.API.Services.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace eRentaCar.API.Services
{
    public class NewsService : INewsService
    {
        private readonly ApplicationDbContext _context;

        public NewsService(ApplicationDbContext context)
        {
            _context = context;
        }

        public async Task<PagedResponse<NewsResponse>> GetAllAsync(bool onlyVisible = true, int page = 1, int pageSize = 20)
        {
            if (pageSize > 100) pageSize = 100;

            var query = _context.News
                .Include(x => x.Author)
                .AsQueryable();

            if (onlyVisible)
                query = query.Where(x => x.IsVisible);

            var totalCount = await query.CountAsync();

            var news = await query
                .OrderByDescending(x => x.PublishedAt)
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .ToListAsync();

            return new PagedResponse<NewsResponse>
            {
                Items = news.Select(MapToResponse).ToList(),
                TotalCount = totalCount,
                Page = page,
                PageSize = pageSize
            };
        }

        public async Task<NewsResponse> GetByIdAsync(int id)
        {
            var news = await _context.News
                .Include(x => x.Author)
                .FirstOrDefaultAsync(x => x.Id == id)
                ?? throw new NotFoundException("Vijest", id);

            return MapToResponse(news);
        }

        public async Task<NewsResponse> CreateAsync(int authorId, NewsRequest request)
        {
            var news = new News
            {
                Title = request.Title,
                Content = request.Content,
                ImageUrl = request.ImageUrl,
                IsVisible = request.IsVisible,
                AuthorId = authorId,
                PublishedAt = DateTime.UtcNow
            };

            _context.News.Add(news);
            await _context.SaveChangesAsync();

            return await GetByIdAsync(news.Id);
        }

        public async Task<NewsResponse> UpdateAsync(int id, NewsRequest request)
        {
            var news = await _context.News.FindAsync(id)
                ?? throw new NotFoundException("Vijest", id);

            news.Title = request.Title;
            news.Content = request.Content;
            news.ImageUrl = request.ImageUrl;
            news.IsVisible = request.IsVisible;

            await _context.SaveChangesAsync();

            return await GetByIdAsync(news.Id);
        }

        public async Task DeleteAsync(int id)
        {
            var news = await _context.News.FindAsync(id)
                ?? throw new NotFoundException("Vijest", id);

            _context.News.Remove(news);
            await _context.SaveChangesAsync();
        }

        private static NewsResponse MapToResponse(News n) => new()
        {
            Id = n.Id,
            Title = n.Title,
            Content = n.Content,
            ImageUrl = n.ImageUrl,
            PublishedAt = n.PublishedAt,
            Author = $"{n.Author.FirstName} {n.Author.LastName}",
            IsVisible = n.IsVisible
        };
    }
}
