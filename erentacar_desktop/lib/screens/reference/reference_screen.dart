import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../config/api_config.dart';
import '../../services/api_service.dart';

class ReferenceScreen extends StatefulWidget {
  const ReferenceScreen({super.key});

  @override
  State<ReferenceScreen> createState() => _ReferenceScreenState();
}

class _ReferenceScreenState extends State<ReferenceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiService _api = ApiService();

  List<dynamic> _categories = [];
  List<dynamic> _brands = [];
  List<dynamic> _fuelTypes = [];
  List<dynamic> _transmissions = [];
  List<dynamic> _cities = [];
  List<dynamic> _countries = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _loadAll();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _api.get(ApiConfig.categories),
        _api.get(ApiConfig.brands),
        _api.get(ApiConfig.fuelTypes),
        _api.get(ApiConfig.transmissions),
        _api.get(ApiConfig.cities),
        _api.get(ApiConfig.countries),
      ]);
      setState(() {
        _categories = results[0];
        _brands = results[1];
        _fuelTypes = results[2];
        _transmissions = results[3];
        _cities = results[4];
        _countries = results[5];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _showSimpleDialog({
    required String title,
    required String fieldLabel,
    String? initialValue,
    required Future<void> Function(String value) onSave,
  }) {
    final ctrl = TextEditingController(text: initialValue ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: 300,
          child: TextField(
            controller: ctrl,
            autofocus: true,
            decoration:
                InputDecoration(labelText: fieldLabel, isDense: true),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Odustani'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (ctrl.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              await onSave(ctrl.text.trim());
            },
            child: const Text('Sačuvaj'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteItem(String endpoint, int id, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Brisanje'),
        content: Text('Jeste li sigurni da želite obrisati "$name"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Odustani'),
          ),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Obriši'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _api.delete('$endpoint/$id');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Uspješno obrisano.'),
          backgroundColor: AppTheme.success,
        ),
      );
      _loadAll();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppTheme.error),
      );
    }
  }

  Widget _buildSimpleList({
    required List<dynamic> items,
    required String nameField,
    required VoidCallback onAdd,
    required Function(Map<String, dynamic>) onEdit,
    required Function(Map<String, dynamic>) onDelete,
  }) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Dodaj'),
            onPressed: onAdd,
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: Card(
            child: ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1),
              itemBuilder: (context, index) {
                final item = items[index] as Map<String, dynamic>;
                return ListTile(
                  title: Text(item[nameField] ?? ''),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined,
                            color: AppTheme.accent, size: 20),
                        onPressed: () => onEdit(item),
                        tooltip: 'Uredi',
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline,
                            color: AppTheme.error, size: 20),
                        onPressed: () => onDelete(item),
                        tooltip: 'Obriši',
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Referentni podaci',
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark)),
            const SizedBox(height: 16),
            TabBar(
              controller: _tabController,
              labelColor: AppTheme.accent,
              unselectedLabelColor: AppTheme.textMuted,
              indicatorColor: AppTheme.accent,
              isScrollable: true,
              tabs: const [
                Tab(text: 'Kategorije'),
                Tab(text: 'Marke'),
                Tab(text: 'Gorivo'),
                Tab(text: 'Mjenjači'),
                Tab(text: 'Gradovi'),
                Tab(text: 'Države'),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildSimpleList(
                    items: _categories,
                    nameField: 'name',
                    onAdd: () => _showSimpleDialog(
                      title: 'Dodaj kategoriju',
                      fieldLabel: 'Naziv kategorije',
                      onSave: (val) async {
                        await _api.post('/api/reference/categories',
                            {'name': val});
                        _loadAll();
                      },
                    ),
                    onEdit: (item) => _showSimpleDialog(
                      title: 'Uredi kategoriju',
                      fieldLabel: 'Naziv kategorije',
                      initialValue: item['name'],
                      onSave: (val) async {
                        await _api.put(
                            '/api/reference/categories/${item['id']}',
                            {'name': val});
                        _loadAll();
                      },
                    ),
                    onDelete: (item) => _deleteItem(
                        '/api/reference/categories', item['id'], item['name']),
                  ),
                  _buildSimpleList(
                    items: _brands,
                    nameField: 'name',
                    onAdd: () => _showSimpleDialog(
                      title: 'Dodaj marku',
                      fieldLabel: 'Naziv marke',
                      onSave: (val) async {
                        await _api.post('/api/reference/brands',
                            {'name': val});
                        _loadAll();
                      },
                    ),
                    onEdit: (item) => _showSimpleDialog(
                      title: 'Uredi marku',
                      fieldLabel: 'Naziv marke',
                      initialValue: item['name'],
                      onSave: (val) async {
                        await _api.put(
                            '/api/reference/brands/${item['id']}',
                            {'name': val});
                        _loadAll();
                      },
                    ),
                    onDelete: (item) => _deleteItem(
                        '/api/reference/brands', item['id'], item['name']),
                  ),
                  _buildSimpleList(
                    items: _fuelTypes,
                    nameField: 'name',
                    onAdd: () => _showSimpleDialog(
                      title: 'Dodaj tip goriva',
                      fieldLabel: 'Naziv tipa goriva',
                      onSave: (val) async {
                        await _api.post('/api/reference/fueltypes',
                            {'name': val});
                        _loadAll();
                      },
                    ),
                    onEdit: (item) => _showSimpleDialog(
                      title: 'Uredi tip goriva',
                      fieldLabel: 'Naziv tipa goriva',
                      initialValue: item['name'],
                      onSave: (val) async {
                        await _api.put(
                            '/api/reference/fueltypes/${item['id']}',
                            {'name': val});
                        _loadAll();
                      },
                    ),
                    onDelete: (item) => _deleteItem(
                        '/api/reference/fueltypes', item['id'], item['name']),
                  ),
                  _buildSimpleList(
                    items: _transmissions,
                    nameField: 'name',
                    onAdd: () => _showSimpleDialog(
                      title: 'Dodaj tip mjenjača',
                      fieldLabel: 'Naziv tipa mjenjača',
                      onSave: (val) async {
                        await _api.post('/api/reference/transmissions',
                            {'name': val});
                        _loadAll();
                      },
                    ),
                    onEdit: (item) => _showSimpleDialog(
                      title: 'Uredi tip mjenjača',
                      fieldLabel: 'Naziv tipa mjenjača',
                      initialValue: item['name'],
                      onSave: (val) async {
                        await _api.put(
                            '/api/reference/transmissions/${item['id']}',
                            {'name': val});
                        _loadAll();
                      },
                    ),
                    onDelete: (item) => _deleteItem(
                        '/api/reference/transmissions',
                        item['id'],
                        item['name']),
                  ),
                  _buildSimpleList(
                    items: _cities,
                    nameField: 'name',
                    onAdd: () => _showSimpleDialog(
                      title: 'Dodaj grad',
                      fieldLabel: 'Naziv grada',
                      onSave: (val) async {
                        await _api.post('/api/reference/cities',
                            {'name': val, 'countryId': 1});
                        _loadAll();
                      },
                    ),
                    onEdit: (item) => _showSimpleDialog(
                      title: 'Uredi grad',
                      fieldLabel: 'Naziv grada',
                      initialValue: item['name'],
                      onSave: (val) async {
                        await _api.put(
                            '/api/reference/cities/${item['id']}',
                            {'name': val, 'countryId': 1});
                        _loadAll();
                      },
                    ),
                    onDelete: (item) => _deleteItem(
                        '/api/reference/cities', item['id'], item['name']),
                  ),
                  _buildSimpleList(
                    items: _countries,
                    nameField: 'name',
                    onAdd: () => _showSimpleDialog(
                      title: 'Dodaj državu',
                      fieldLabel: 'Naziv države',
                      onSave: (val) async {
                        await _api.post('/api/reference/countries',
                            {'name': val, 'code': val.substring(0, 2).toUpperCase()});
                        _loadAll();
                      },
                    ),
                    onEdit: (item) => _showSimpleDialog(
                      title: 'Uredi državu',
                      fieldLabel: 'Naziv države',
                      initialValue: item['name'],
                      onSave: (val) async {
                        await _api.put(
                            '/api/reference/countries/${item['id']}',
                            {'name': val, 'code': item['code']});
                        _loadAll();
                      },
                    ),
                    onDelete: (item) => _deleteItem(
                        '/api/reference/countries',
                        item['id'],
                        item['name']),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}