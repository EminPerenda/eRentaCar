import 'package:flutter/material.dart';
import '../../config/app_theme.dart';

class NewsDetailScreen extends StatelessWidget {
  final Map<String, dynamic> news;
  const NewsDetailScreen({super.key, required this.news});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(news['title'] ?? '')),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (news['imageUrl'] != null) ...[
              SizedBox(
                width: double.infinity,
                height: 240,
                child: Image.network(
                  news['imageUrl'],
                  width: double.infinity,
                  height: 240,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const SizedBox(),
                ),
              ),
            ],
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(news['title'] ?? '', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Text(news['content'] ?? '', style: const TextStyle(color: AppTheme.textMuted)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
