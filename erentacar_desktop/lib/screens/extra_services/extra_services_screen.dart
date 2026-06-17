import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../config/api_config.dart';
import '../../services/api_service.dart';

class ExtraServicesScreen extends StatefulWidget {
  const ExtraServicesScreen({super.key});

  @override
  State<ExtraServicesScreen> createState() => _ExtraServicesScreenState();
}

class _ExtraServicesScreenState extends State<ExtraServicesScreen> {
  final ApiService _api = ApiService();
  List<dynamic> _services = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final data = await _api.get(ApiConfig.extraServicesAdmin);
      setState(() {
        _services = data as List;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _delete(Map<String, dynamic> service) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Brisanje usluge'),
        content: Text('Sigurno želite obrisati uslugu "${service['name']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Odustani'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Obriši'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await _api.delete('${ApiConfig.extraServices}/${service['id']}');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usluga je obrisana.'), backgroundColor: AppTheme.success),
      );
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.error),
      );
    }
  }

  void _openDialog([Map<String, dynamic>? service]) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => _ExtraServiceDialog(api: _api, service: service),
    );
    if (saved == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Dodatne usluge',
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Nova usluga'),
                  onPressed: () => _openDialog(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Upravljajte katalogom dodatnih usluga koje klijenti mogu odabrati tokom rezervacije.',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
            ),
            const SizedBox(height: 20),
            Expanded(child: _buildContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_services.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.miscellaneous_services_outlined,
                size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            const Text('Nema dodatnih usluga.',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 16)),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Dodaj prvu uslugu'),
              onPressed: () => _openDialog(),
            ),
          ],
        ),
      );
    }

    return Card(
      child: SingleChildScrollView(
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(AppTheme.background),
          columns: const [
            DataColumn(label: Text('Naziv')),
            DataColumn(label: Text('Opis')),
            DataColumn(label: Text('Cijena/dan')),
            DataColumn(label: Text('Dostupnost')),
            DataColumn(label: Text('Akcije')),
          ],
          rows: _services.map((s) {
            final isAvailable = s['isAvailable'] as bool;
            return DataRow(cells: [
              DataCell(Text(s['name'] ?? '',
                  style: const TextStyle(fontWeight: FontWeight.w600))),
              DataCell(
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 300),
                  child: Text(
                    s['description'] ?? '—',
                    style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              DataCell(Text(
                '${s['pricePerDay']} KM',
                style: const TextStyle(
                    fontWeight: FontWeight.w600, color: AppTheme.accent),
              )),
              DataCell(
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color:
                        (isAvailable ? AppTheme.success : AppTheme.error)
                            .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isAvailable ? 'Dostupno' : 'Nedostupno',
                    style: TextStyle(
                      color: isAvailable ? AppTheme.success : AppTheme.error,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              DataCell(Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined,
                        color: AppTheme.accent, size: 20),
                    onPressed: () => _openDialog(s),
                    tooltip: 'Uredi',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline,
                        color: AppTheme.error, size: 20),
                    onPressed: () => _delete(s),
                    tooltip: 'Obriši',
                  ),
                ],
              )),
            ]);
          }).toList(),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _ExtraServiceDialog extends StatefulWidget {
  final ApiService api;
  final Map<String, dynamic>? service;

  const _ExtraServiceDialog({required this.api, this.service});

  @override
  State<_ExtraServiceDialog> createState() => _ExtraServiceDialogState();
}

class _ExtraServiceDialogState extends State<_ExtraServiceDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _priceCtrl;
  bool _isAvailable = true;
  bool _isSaving = false;

  bool get _isEdit => widget.service != null;

  @override
  void initState() {
    super.initState();
    final s = widget.service;
    _nameCtrl = TextEditingController(text: s?['name'] ?? '');
    _descCtrl = TextEditingController(text: s?['description'] ?? '');
    _priceCtrl = TextEditingController(
        text: s != null ? '${s['pricePerDay']}' : '');
    _isAvailable = s?['isAvailable'] as bool? ?? true;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final body = {
      'name': _nameCtrl.text.trim(),
      'description': _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      'pricePerDay': double.parse(_priceCtrl.text.trim().replaceAll(',', '.')),
      'isAvailable': _isAvailable,
    };

    try {
      if (_isEdit) {
        await widget.api.put(
            '${ApiConfig.extraServices}/${widget.service!['id']}', body);
      } else {
        await widget.api.post(ApiConfig.extraServices, body);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEdit ? 'Usluga je ažurirana.' : 'Usluga je dodana.'),
          backgroundColor: AppTheme.success,
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding:
          const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
      child: SizedBox(
        width: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: AppTheme.accent.withValues(alpha: 0.06),
                border: Border(
                    bottom: BorderSide(
                        color: Colors.grey.withValues(alpha: 0.15))),
              ),
              child: Row(
                children: [
                  Text(
                    _isEdit ? 'Uredi uslugu' : 'Nova dodatna usluga',
                    style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDark),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context, false),
                  ),
                ],
              ),
            ),
            // Form
            Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _nameCtrl,
                      decoration:
                          const InputDecoration(labelText: 'Naziv usluge', isDense: true),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Obavezno' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descCtrl,
                      decoration: const InputDecoration(
                          labelText: 'Opis (opcionalno)', isDense: true),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _priceCtrl,
                      decoration: const InputDecoration(
                          labelText: 'Cijena po danu (KM)',
                          isDense: true,
                          suffixText: 'KM'),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Obavezno';
                        final val = double.tryParse(v.trim().replaceAll(',', '.'));
                        if (val == null || val < 0) return 'Unesite valjanu cijenu';
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Switch(
                          value: _isAvailable,
                          onChanged: (val) => setState(() => _isAvailable = val),
                          activeColor: AppTheme.success,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _isAvailable ? 'Dostupno' : 'Nedostupno',
                          style: TextStyle(
                            color: _isAvailable ? AppTheme.success : AppTheme.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          '— klijenti je mogu odabrati',
                          style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: _isSaving
                              ? null
                              : () => Navigator.pop(context, false),
                          child: const Text('Odustani'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _isSaving ? null : _save,
                          child: _isSaving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2))
                              : Text(_isEdit ? 'Spremi' : 'Dodaj'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
