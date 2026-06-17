import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../config/api_config.dart';
import '../../services/api_service.dart';

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            child: const Text('Vijesti i obavijesti',
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark)),
          ),
          const SizedBox(height: 12),
          TabBar(
            controller: _tabController,
            labelColor: AppTheme.accent,
            unselectedLabelColor: AppTheme.textMuted,
            indicatorColor: AppTheme.accent,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            tabs: const [
              Tab(icon: Icon(Icons.newspaper_outlined, size: 18), text: 'Vijesti i promocije'),
              Tab(icon: Icon(Icons.notifications_outlined, size: 18), text: 'Obavijesti'),
            ],
          ),
          const Divider(height: 1),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                _NewsTab(),
                _NotificationsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Vijesti tab
// ─────────────────────────────────────────────────────────────────────────────

class _NewsTab extends StatefulWidget {
  const _NewsTab();

  @override
  State<_NewsTab> createState() => _NewsTabState();
}

class _NewsTabState extends State<_NewsTab> {
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
      final data = await _api.get('${ApiConfig.news}/all');
      setState(() { _news = data; _isLoading = false; });
    } catch (_) { setState(() => _isLoading = false); }
  }

  Future<void> _delete(int id, String title) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Brisanje vijesti'),
        content: Text('Sigurno želite obrisati "$title"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Odustani')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Obriši'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await _api.delete('${ApiConfig.news}/$id');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vijest je obrisana.'), backgroundColor: AppTheme.success));
      _loadNews();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.error));
    }
  }

  void _showDialog({Map<String, dynamic>? news}) {
    final titleCtrl = TextEditingController(text: news?['title'] ?? '');
    final contentCtrl = TextEditingController(text: news?['content'] ?? '');
    final imageCtrl = TextEditingController(text: news?['imageUrl'] ?? '');
    bool isVisible = news?['isVisible'] ?? true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDs) => AlertDialog(
          title: Text(news == null ? 'Dodaj vijest' : 'Uredi vijest'),
          content: SizedBox(
            width: 600,
            child: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                TextField(controller: titleCtrl,
                    decoration: const InputDecoration(labelText: 'Naslov', isDense: true)),
                const SizedBox(height: 12),
                TextField(controller: contentCtrl,
                    decoration: const InputDecoration(labelText: 'Sadržaj', isDense: true),
                    maxLines: 5),
                const SizedBox(height: 12),
                TextField(controller: imageCtrl,
                    decoration: const InputDecoration(labelText: 'URL slike (opcionalno)', isDense: true)),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text('Vidljivo klijentima'),
                  value: isVisible,
                  activeColor: AppTheme.accent,
                  onChanged: (v) => setDs(() => isVisible = v),
                  contentPadding: EdgeInsets.zero,
                ),
              ]),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Odustani')),
            ElevatedButton(
              onPressed: () async {
                if (titleCtrl.text.trim().isEmpty || contentCtrl.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Naslov i sadržaj su obavezni.'), backgroundColor: AppTheme.error));
                  return;
                }
                try {
                  final body = {
                    'title': titleCtrl.text.trim(),
                    'content': contentCtrl.text.trim(),
                    'imageUrl': imageCtrl.text.trim().isEmpty ? null : imageCtrl.text.trim(),
                    'isVisible': isVisible,
                  };
                  if (news == null) {
                    await _api.post(ApiConfig.news, body);
                  } else {
                    await _api.put('${ApiConfig.news}/${news['id']}', body);
                  }
                  Navigator.pop(ctx);
                  _loadNews();
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(news == null ? 'Vijest je dodana.' : 'Vijest je ažurirana.'),
                    backgroundColor: AppTheme.success,
                  ));
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.error));
                }
              },
              child: Text(news == null ? 'Objavi' : 'Sačuvaj'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          ElevatedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Dodaj vijest'),
            onPressed: () => _showDialog(),
          ),
        ]),
        const SizedBox(height: 16),
        Expanded(child: _buildContent()),
      ]),
    );
  }

  Widget _buildContent() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_news.isEmpty) return const Center(child: Text('Nema vijesti.', style: TextStyle(color: AppTheme.textMuted)));

    return ListView.builder(
      itemCount: _news.length,
      itemBuilder: (context, index) {
        final n = _news[index];
        final isVisible = n['isVisible'] as bool;
        final date = DateTime.parse(n['publishedAt']);

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                width: 60, height: 60,
                decoration: BoxDecoration(
                  color: AppTheme.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: n['imageUrl'] != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(n['imageUrl'], width: 60, height: 60, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(Icons.newspaper, color: AppTheme.accent, size: 28)))
                    : const Icon(Icons.newspaper, color: AppTheme.accent, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(child: Text(n['title'],
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark))),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: (isVisible ? AppTheme.success : Colors.grey).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(isVisible ? 'Vidljivo' : 'Skriveno',
                          style: TextStyle(color: isVisible ? AppTheme.success : Colors.grey,
                              fontSize: 12, fontWeight: FontWeight.w600)),
                    ),
                  ]),
                  const SizedBox(height: 4),
                  Text(n['content'], maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppTheme.textMuted)),
                  const SizedBox(height: 8),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Row(children: [
                      const Icon(Icons.person_outline, size: 14, color: AppTheme.textMuted),
                      const SizedBox(width: 4),
                      Text(n['author'], style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                      const SizedBox(width: 16),
                      const Icon(Icons.calendar_today_outlined, size: 14, color: AppTheme.textMuted),
                      const SizedBox(width: 4),
                      Text('${date.day}.${date.month}.${date.year}',
                          style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                    ]),
                    Row(children: [
                      IconButton(icon: const Icon(Icons.edit_outlined, color: AppTheme.accent, size: 20),
                          onPressed: () => _showDialog(news: n), tooltip: 'Uredi'),
                      IconButton(icon: const Icon(Icons.delete_outline, color: AppTheme.error, size: 20),
                          onPressed: () => _delete(n['id'], n['title']), tooltip: 'Obriši'),
                    ]),
                  ]),
                ]),
              ),
            ]),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Obavijesti tab
// ─────────────────────────────────────────────────────────────────────────────

class _NotificationsTab extends StatefulWidget {
  const _NotificationsTab();

  @override
  State<_NotificationsTab> createState() => _NotificationsTabState();
}

class _NotificationsTabState extends State<_NotificationsTab> {
  final ApiService _api = ApiService();
  List<dynamic> _notifications = [];
  bool _isLoading = true;
  int _totalCount = 0;
  int _page = 1;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool reset = false}) async {
    if (reset) setState(() => _page = 1);
    setState(() => _isLoading = true);
    try {
      final data = await _api.get(ApiConfig.notificationsAdmin,
          params: {'page': _page, 'pageSize': 30});
      setState(() {
        _notifications = data['items'] as List;
        _totalCount = data['totalCount'] as int;
        _isLoading = false;
      });
    } catch (_) { setState(() => _isLoading = false); }
  }

  void _openSendDialog() async {
    await showDialog(
      context: context,
      builder: (ctx) => _SendNotificationDialog(api: _api),
    );
    _load(reset: true);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Action buttons
        Row(children: [
          ElevatedButton.icon(
            icon: const Icon(Icons.campaign_outlined, size: 18),
            label: const Text('Pošalji svim korisnicima'),
            onPressed: _openSendDialog,
          ),
          const SizedBox(width: 12),
          OutlinedButton.icon(
            icon: const Icon(Icons.person_outlined, size: 18),
            label: const Text('Pošalji korisniku'),
            onPressed: _openSendDialog,
          ),
          const Spacer(),
          Text('$_totalCount obavijesti ukupno',
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
        ]),
        const SizedBox(height: 20),
        const Text('Historija obavijesti',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
        const SizedBox(height: 10),
        Expanded(child: _buildList()),
        if (_totalCount > 30) _buildPagination(),
      ]),
    );
  }

  Widget _buildList() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_notifications.isEmpty) {
      return const Center(child: Text('Nema obavijesti.', style: TextStyle(color: AppTheme.textMuted)));
    }
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: Colors.grey.withValues(alpha: 0.15))),
      child: ListView.separated(
        itemCount: _notifications.length,
        separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.withValues(alpha: 0.1)),
        itemBuilder: (context, index) {
          final n = _notifications[index];
          final date = DateTime.parse(n['createdAt']);
          final isRead = n['isRead'] as bool;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: AppTheme.accent.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.notifications_outlined, size: 18, color: AppTheme.accent),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Text(n['title'] ?? '-',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: (isRead ? Colors.grey : AppTheme.accent).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(isRead ? 'Pročitano' : 'Nepročitano',
                          style: TextStyle(
                              fontSize: 10,
                              color: isRead ? Colors.grey : AppTheme.accent,
                              fontWeight: FontWeight.w600)),
                    ),
                  ]),
                  const SizedBox(height: 2),
                  Text(n['message'] ?? '-',
                      style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                ]),
              ),
              const SizedBox(width: 16),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(n['userName'] ?? '-',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text('${date.day}.${date.month}.${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}',
                    style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
              ]),
            ]),
          );
        },
      ),
    );
  }

  Widget _buildPagination() {
    final total = (_totalCount / 30).ceil();
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: _page > 1 ? () { setState(() => _page--); _load(); } : null,
        ),
        Text('Stranica $_page od $total'),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: _page < total ? () { setState(() => _page++); _load(); } : null,
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Send notification dialog
// ─────────────────────────────────────────────────────────────────────────────

class _SendNotificationDialog extends StatefulWidget {
  final ApiService api;
  const _SendNotificationDialog({required this.api});

  @override
  State<_SendNotificationDialog> createState() => _SendNotificationDialogState();
}

class _SendNotificationDialogState extends State<_SendNotificationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();
  bool _toAll = true;
  int? _selectedUserId;
  List<dynamic> _users = [];
  bool _loadingUsers = false;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() => _loadingUsers = true);
    try {
      final data = await widget.api.get(ApiConfig.users, params: {'pageSize': 100});
      setState(() { _users = data['items'] as List; _loadingUsers = false; });
    } catch (_) { setState(() => _loadingUsers = false); }
  }

  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_toAll && _selectedUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Odaberite korisnika.'), backgroundColor: AppTheme.error));
      return;
    }
    setState(() => _isSending = true);
    try {
      await widget.api.post(ApiConfig.notificationsSend, {
        'title': _titleCtrl.text.trim(),
        'message': _messageCtrl.text.trim(),
        if (!_toAll) 'userId': _selectedUserId,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_toAll
              ? 'Obavijest je poslana svim korisnicima.'
              : 'Obavijest je poslana korisniku.'),
          backgroundColor: AppTheme.success,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSending = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.error));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
      child: SizedBox(
        width: 500,
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: AppTheme.accent.withValues(alpha: 0.06),
              border: Border(bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.15))),
            ),
            child: Row(children: [
              const Icon(Icons.campaign_outlined, color: AppTheme.accent, size: 20),
              const SizedBox(width: 10),
              const Text('Pošalji obavijest',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
              const Spacer(),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // Target selector
                Card(
                  elevation: 0,
                  color: AppTheme.background,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Primatelji', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      const SizedBox(height: 8),
                      Row(children: [
                        Radio<bool>(value: true, groupValue: _toAll, activeColor: AppTheme.accent,
                            onChanged: (v) => setState(() => _toAll = true)),
                        const Text('Svi aktivni korisnici'),
                        const SizedBox(width: 24),
                        Radio<bool>(value: false, groupValue: _toAll, activeColor: AppTheme.accent,
                            onChanged: (v) => setState(() => _toAll = false)),
                        const Text('Odabrani korisnik'),
                      ]),
                      if (!_toAll) ...[
                        const SizedBox(height: 10),
                        _loadingUsers
                            ? const LinearProgressIndicator()
                            : DropdownButtonFormField<int?>(
                                value: _selectedUserId,
                                isExpanded: true,
                                decoration: const InputDecoration(
                                    labelText: 'Odaberi korisnika', isDense: true),
                                items: _users.map((u) => DropdownMenuItem<int?>(
                                  value: u['id'] as int?,
                                  child: Text('${u['firstName']} ${u['lastName']} — ${u['email']}',
                                      overflow: TextOverflow.ellipsis),
                                )).toList(),
                                onChanged: (v) => setState(() => _selectedUserId = v),
                              ),
                      ],
                    ]),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _titleCtrl,
                  decoration: const InputDecoration(labelText: 'Naslov obavijesti', isDense: true),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Obavezno' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _messageCtrl,
                  decoration: const InputDecoration(labelText: 'Poruka', isDense: true),
                  maxLines: 3,
                  validator: (v) => v == null || v.trim().isEmpty ? 'Obavezno' : null,
                ),
                const SizedBox(height: 24),
                Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                  TextButton(
                    onPressed: _isSending ? null : () => Navigator.pop(context),
                    child: const Text('Odustani'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    icon: _isSending
                        ? const SizedBox(width: 16, height: 16,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.send_outlined, size: 16),
                    label: Text(_toAll ? 'Pošalji svima' : 'Pošalji'),
                    onPressed: _isSending ? null : _send,
                  ),
                ]),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}
