import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../config/api_config.dart';
import '../../services/api_service.dart';
import 'news_detail_screen.dart';

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  final ApiService _api = ApiService();
  List<dynamic> _news = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNews();
  }

  Future<void> _loadNews() async {
    setState(() => _isLoading = true);
    try {
      final data = await _api.get(ApiConfig.news);
      setState(() {
        _news = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vijesti i promocije')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _news.isEmpty
              ? const Center(child: Text('Nema vijesti.'))
              : RefreshIndicator(
                  onRefresh: _loadNews,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _news.length,
                    itemBuilder: (context, index) {
                      final n = _news[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: InkWell(
                          onTap: () => _showFull(context, n),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 72,
                                  height: 72,
                                  decoration: BoxDecoration(
                                    color: AppTheme.accent.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: n['imageUrl'] != null
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: Image.network(
                                            n['imageUrl'],
                                            width: 72,
                                            height: 72,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) => const Icon(Icons.newspaper, color: AppTheme.accent, size: 36),
                                          ),
                                        )
                                      : const Icon(Icons.newspaper, color: AppTheme.accent, size: 36),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(n['title'] ?? '', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 6),
                                      Text(n['content'] ?? '', maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppTheme.textMuted)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  void _showFull(BuildContext context, Map<String, dynamic> n) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => NewsDetailScreen(news: n)),
    );
  }
}
