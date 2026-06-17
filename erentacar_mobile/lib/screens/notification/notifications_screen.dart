import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../config/api_config.dart';
import '../../services/api_service.dart';
import '../../services/signalr_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final ApiService _api = ApiService();
  List<dynamic> _notifications = [];
  bool _isLoading = true;

 final SignalRService _signalR = SignalRService();

@override
void initState() {
  super.initState();
  _loadNotifications();
  _signalR.onNotificationReceived = (data) {
    _loadNotifications();
  };
  _signalR.connect();
}

@override
void dispose() {
  _signalR.onNotificationReceived = null;
  super.dispose();
}
  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    try {
      final data = await _api.get(ApiConfig.notifications);
      setState(() {
        _notifications = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _markAsRead(int id) async {
    try {
      await _api.patch('${ApiConfig.notifications}/$id/read');
      setState(() {
        final index = _notifications.indexWhere((n) => n['id'] == id);
        if (index != -1) _notifications[index]['isRead'] = true;
      });
    } catch (_) {}
  }

  Future<void> _markAllAsRead() async {
    try {
      await _api.patch('${ApiConfig.notifications}/read-all');
      setState(() {
        for (final n in _notifications) {
          n['isRead'] = true;
        }
      });
    } catch (_) {}
  }

  int get _unreadCount =>
      _notifications.where((n) => n['isRead'] == false).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _unreadCount > 0
              ? 'Obavijesti ($_unreadCount)'
              : 'Obavijesti',
        ),
        actions: [
          if (_unreadCount > 0)
            TextButton(
              onPressed: _markAllAsRead,
              child: const Text(
                'Sve pročitano',
                style: TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.notifications_none,
                          size: 64, color: AppTheme.textMuted),
                      const SizedBox(height: 16),
                      const Text(
                        'Nema obavijesti.',
                        style: TextStyle(color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadNotifications,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) =>
                        _buildNotificationCard(_notifications[index]),
                  ),
                ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> notification) {
    final isRead = notification['isRead'] as bool;
    final type = notification['type'] as String;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isRead ? null : AppTheme.accent.withOpacity(0.05),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: isRead ? null : () => _markAsRead(notification['id']),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _typeColor(type).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _typeIcon(type),
                  color: _typeColor(type),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            notification['title'],
                            style: TextStyle(
                              fontWeight: isRead
                                  ? FontWeight.normal
                                  : FontWeight.bold,
                              color: AppTheme.textDark,
                            ),
                          ),
                        ),
                        if (!isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppTheme.accent,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification['message'],
                      style: const TextStyle(
                          color: AppTheme.textMuted, fontSize: 13),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _formatDate(notification['createdAt']),
                      style: const TextStyle(
                          color: AppTheme.textMuted, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'Reservation':
        return AppTheme.accent;
      case 'Payment':
        return AppTheme.success;
      case 'Cancellation':
        return AppTheme.error;
      default:
        return Colors.grey;
    }
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'Reservation':
        return Icons.calendar_today_outlined;
      case 'Payment':
        return Icons.payments_outlined;
      case 'Cancellation':
        return Icons.cancel_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

String _formatDate(String dateStr) {
    final raw = dateStr.endsWith('Z') ? dateStr : '${dateStr}Z';
    final date = DateTime.parse(raw).toLocal();
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inSeconds < 60) return 'Upravo';
    if (diff.inMinutes < 60) return 'Prije ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Prije ${diff.inHours} h';
    if (diff.inDays < 7) return 'Prije ${diff.inDays} dana';
    return '${date.day}.${date.month}.${date.year}';
  }
}