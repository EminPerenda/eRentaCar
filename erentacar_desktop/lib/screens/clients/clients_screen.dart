import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../config/api_config.dart';
import '../../services/api_service.dart';

class ClientsScreen extends StatefulWidget {
  const ClientsScreen({super.key});

  @override
  State<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends State<ClientsScreen> {
  final ApiService _api = ApiService();
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _clients = [];
  bool _isLoading = true;
  int _page = 1;
  int _totalCount = 0;
  final int _pageSize = 10;

  @override
  void initState() {
    super.initState();
    _loadClients();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadClients({bool reset = false}) async {
    if (reset) setState(() => _page = 1);
    setState(() => _isLoading = true);
    try {
      final params = <String, dynamic>{
        'page': _page,
        'pageSize': _pageSize,
      };
      if (_searchController.text.isNotEmpty) {
        params['search'] = _searchController.text;
      }
      final data = await _api.get(ApiConfig.users, params: params);
      setState(() {
        _clients = data['items'];
        _totalCount = data['totalCount'];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleActive(int id, bool isActive) async {
    try {
      await _api.patch('${ApiConfig.users}/$id/toggle-active');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isActive ? 'Klijent je deaktiviran.' : 'Klijent je aktiviran.'),
          backgroundColor: AppTheme.success,
        ),
      );
      _loadClients();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.error),
      );
    }
  }

  void _openClientProfile(Map<String, dynamic> client) {
    showDialog(
      context: context,
      builder: (ctx) => _ClientProfileDialog(
        client: client,
        api: _api,
        onChanged: _loadClients,
      ),
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
            const Text('Klijenti',
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark)),
            const SizedBox(height: 16),
            _buildFilters(),
            const SizedBox(height: 16),
            Expanded(child: _buildTable()),
            if (_totalCount > _pageSize) _buildPagination(),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Pretraži po imenu, e-mailu ili broju vozačke...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _loadClients(reset: true);
                      },
                    )
                  : null,
              isDense: true,
            ),
            onSubmitted: (_) => _loadClients(reset: true),
          ),
        ),
        const SizedBox(width: 16),
        Text('Ukupno: $_totalCount klijenata',
            style: const TextStyle(color: AppTheme.textMuted)),
      ],
    );
  }

  Widget _buildTable() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_clients.isEmpty) {
      return const Center(child: Text('Nema klijenata.'));
    }

    return Card(
      child: SingleChildScrollView(
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(AppTheme.background),
          columns: const [
            DataColumn(label: Text('Ime i prezime')),
            DataColumn(label: Text('E-mail')),
            DataColumn(label: Text('Telefon')),
            DataColumn(label: Text('Rezervacija')),
            DataColumn(label: Text('Potrošeno')),
            DataColumn(label: Text('Status')),
            DataColumn(label: Text('Akcije')),
          ],
          rows: _clients.map((c) {
            final isActive = c['isActive'] as bool;
            return DataRow(cells: [
              DataCell(Text('${c['firstName']} ${c['lastName']}',
                  style: const TextStyle(fontWeight: FontWeight.w600))),
              DataCell(Text(c['email'])),
              DataCell(Text(c['phoneNumber'] ?? '-')),
              DataCell(Text('${c['reservationCount']}')),
              DataCell(Text('${c['totalSpent']} KM')),
              DataCell(Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (isActive ? AppTheme.success : AppTheme.error).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isActive ? 'Aktivan' : 'Deaktiviran',
                  style: TextStyle(
                    color: isActive ? AppTheme.success : AppTheme.error,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )),
              DataCell(Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.person_outlined, color: AppTheme.accent, size: 20),
                    onPressed: () => _openClientProfile(c),
                    tooltip: 'Profil klijenta',
                  ),
                  IconButton(
                    icon: Icon(
                      isActive ? Icons.block_outlined : Icons.check_circle_outline,
                      color: isActive ? AppTheme.error : AppTheme.success,
                      size: 20,
                    ),
                    onPressed: () => _toggleActive(c['id'], isActive),
                    tooltip: isActive ? 'Deaktiviraj' : 'Aktiviraj',
                  ),
                ],
              )),
            ]);
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildPagination() {
    final totalPages = (_totalCount / _pageSize).ceil();
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: _page > 1
                ? () {
                    setState(() => _page--);
                    _loadClients();
                  }
                : null,
          ),
          Text('Stranica $_page od $totalPages'),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _page < totalPages
                ? () {
                    setState(() => _page++);
                    _loadClients();
                  }
                : null,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Client Profile Dialog
// ─────────────────────────────────────────────────────────────────────────────

class _ClientProfileDialog extends StatefulWidget {
  final Map<String, dynamic> client;
  final ApiService api;
  final VoidCallback onChanged;

  const _ClientProfileDialog({
    required this.client,
    required this.api,
    required this.onChanged,
  });

  @override
  State<_ClientProfileDialog> createState() => _ClientProfileDialogState();
}

class _ClientProfileDialogState extends State<_ClientProfileDialog> {
  late Map<String, dynamic> _client;
  List<dynamic> _reservations = [];
  bool _loadingReservations = true;

  @override
  void initState() {
    super.initState();
    _client = Map<String, dynamic>.from(widget.client);
    _loadReservations();
  }

  Future<void> _loadReservations() async {
    setState(() => _loadingReservations = true);
    try {
      final data = await widget.api.get(ApiConfig.reservations, params: {
        'userId': _client['id'],
        'pageSize': 100,
      });
      setState(() {
        _reservations = data['items'] ?? [];
        _loadingReservations = false;
      });
    } catch (_) {
      setState(() => _loadingReservations = false);
    }
  }

  Future<void> _refreshClient() async {
    try {
      final data = await widget.api.get('${ApiConfig.users}/${_client['id']}');
      setState(() => _client = data);
      widget.onChanged();
    } catch (_) {}
  }

  Future<void> _toggleActive() async {
    final isActive = _client['isActive'] as bool;
    try {
      await widget.api.patch('${ApiConfig.users}/${_client['id']}/toggle-active');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isActive ? 'Klijent je deaktiviran.' : 'Klijent je aktiviran.'),
          backgroundColor: AppTheme.success,
        ),
      );
      await _refreshClient();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.error),
      );
    }
  }

  void _openEdit() async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => _EditClientDialog(client: _client, api: widget.api),
    );
    if (saved == true) await _refreshClient();
  }

  @override
  Widget build(BuildContext context) {
    final isActive = _client['isActive'] as bool;
    final initials = '${(_client['firstName'] as String? ?? ' ')[0]}${(_client['lastName'] as String? ?? ' ')[0]}'.toUpperCase();
    final totalSpent = _client['totalSpent'];
    final reservationCount = _client['reservationCount'] ?? 0;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
      child: SizedBox(
        width: 780,
        height: MediaQuery.of(context).size.height * 0.82,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: AppTheme.accent.withValues(alpha: 0.06),
                border: Border(bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.15))),
              ),
              child: Row(
                children: [
                  const Text('Profil klijenta',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
                  const Spacer(),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    label: const Text('Uredi'),
                    onPressed: _openEdit,
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isActive ? AppTheme.error : AppTheme.success,
                    ),
                    icon: Icon(isActive ? Icons.block_outlined : Icons.check_circle_outline, size: 16),
                    label: Text(isActive ? 'Deaktiviraj' : 'Aktiviraj'),
                    onPressed: _toggleActive,
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            // Body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Client info card
                    Card(
                      elevation: 0,
                      color: AppTheme.background,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Avatar
                            CircleAvatar(
                              radius: 36,
                              backgroundColor: AppTheme.accent.withValues(alpha: 0.15),
                              child: Text(initials,
                                  style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.accent)),
                            ),
                            const SizedBox(width: 20),
                            // Info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text('${_client['firstName']} ${_client['lastName']}',
                                          style: const TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              color: AppTheme.textDark)),
                                      const SizedBox(width: 10),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: (isActive ? AppTheme.success : AppTheme.error).withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          isActive ? 'Aktivan' : 'Deaktiviran',
                                          style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: isActive ? AppTheme.success : AppTheme.error),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Wrap(
                                    spacing: 24,
                                    runSpacing: 8,
                                    children: [
                                      _infoChip(Icons.email_outlined, _client['email'] ?? '-'),
                                      if (_client['phoneNumber'] != null)
                                        _infoChip(Icons.phone_outlined, _client['phoneNumber']),
                                      if (_client['city'] != null)
                                        _infoChip(Icons.location_city_outlined, _client['city']),
                                      _infoChip(Icons.credit_card_outlined,
                                          _client['driverLicenseNo'] ?? 'Vozačka nije unesena'),
                                      if (_client['createdAt'] != null)
                                        _infoChip(Icons.calendar_today_outlined,
                                            'Registrovan: ${_formatDate(_client['createdAt'])}'),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            // Stats
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                _statBox('$reservationCount', 'rezervacija', Icons.receipt_long_outlined),
                                const SizedBox(height: 8),
                                _statBox('$totalSpent KM', 'ukupno potrošeno', Icons.payments_outlined),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Reservation history
                    const Text('Historija rezervacija',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textDark)),
                    const SizedBox(height: 12),
                    if (_loadingReservations)
                      const Center(child: CircularProgressIndicator())
                    else if (_reservations.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Text('Nema rezervacija.', style: TextStyle(color: AppTheme.textMuted)),
                      )
                    else
                      Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(color: Colors.grey.withValues(alpha: 0.15)),
                        ),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            headingRowColor: WidgetStateProperty.all(AppTheme.background),
                            dataRowMinHeight: 40,
                            dataRowMaxHeight: 52,
                            columns: const [
                              DataColumn(label: Text('Vozilo')),
                              DataColumn(label: Text('Period')),
                              DataColumn(label: Text('Preuzimanje')),
                              DataColumn(label: Text('Povrat')),
                              DataColumn(label: Text('Cijena')),
                              DataColumn(label: Text('Status')),
                            ],
                            rows: _reservations.map((r) {
                              return DataRow(cells: [
                                DataCell(Text(r['vehicle'] ?? '-',
                                    style: const TextStyle(fontWeight: FontWeight.w500))),
                                DataCell(Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(_formatDate(r['startDate']),
                                        style: const TextStyle(fontSize: 12)),
                                    Text(_formatDate(r['endDate']),
                                        style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                                  ],
                                )),
                                DataCell(Text(r['pickupLocation'] ?? '-',
                                    style: const TextStyle(fontSize: 12))),
                                DataCell(Text(r['dropoffLocation'] ?? '-',
                                    style: const TextStyle(fontSize: 12))),
                                DataCell(Text('${r['totalPrice']} KM',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600, color: AppTheme.accent))),
                                DataCell(_buildStatusBadge(r['status'] as String)),
                              ]);
                            }).toList(),
                          ),
                        ),
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

  Widget _infoChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppTheme.accent),
        const SizedBox(width: 5),
        Text(text, style: const TextStyle(fontSize: 13, color: AppTheme.textDark)),
      ],
    );
  }

  Widget _statBox(String value, String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.accent.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: AppTheme.accent),
              const SizedBox(width: 6),
              Text(value,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
            ],
          ),
          Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String label;
    switch (status) {
      case 'Pending':
        color = Colors.orange;
        label = 'Na čekanju';
        break;
      case 'Confirmed':
        color = AppTheme.accent;
        label = 'Potvrđena';
        break;
      case 'Active':
        color = AppTheme.success;
        label = 'Aktivna';
        break;
      case 'Completed':
        color = Colors.grey;
        label = 'Završena';
        break;
      case 'Cancelled':
        color = AppTheme.error;
        label = 'Otkazana';
        break;
      default:
        color = Colors.grey;
        label = status;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(label,
          style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }

  String _formatDate(String dateStr) {
    final date = DateTime.parse(dateStr);
    return '${date.day}.${date.month}.${date.year}';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Edit Client Dialog
// ─────────────────────────────────────────────────────────────────────────────

class _EditClientDialog extends StatefulWidget {
  final Map<String, dynamic> client;
  final ApiService api;

  const _EditClientDialog({required this.client, required this.api});

  @override
  State<_EditClientDialog> createState() => _EditClientDialogState();
}

class _EditClientDialogState extends State<_EditClientDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _firstNameCtrl;
  late TextEditingController _lastNameCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _licenseCtrl;
  final TextEditingController _newPasswordCtrl = TextEditingController();
  final TextEditingController _confirmPasswordCtrl = TextEditingController();
  int? _selectedCityId;
  List<dynamic> _cities = [];
  bool _isSaving = false;
  bool _loadingCities = true;
  bool _changePassword = false;
  bool _showNewPw = false;
  bool _showConfirmPw = false;

  @override
  void initState() {
    super.initState();
    _firstNameCtrl = TextEditingController(text: widget.client['firstName'] ?? '');
    _lastNameCtrl = TextEditingController(text: widget.client['lastName'] ?? '');
    _phoneCtrl = TextEditingController(text: widget.client['phoneNumber'] ?? '');
    _licenseCtrl = TextEditingController(text: widget.client['driverLicenseNo'] ?? '');
    _selectedCityId = widget.client['cityId'] as int?;
    _loadCities();
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _phoneCtrl.dispose();
    _licenseCtrl.dispose();
    _newPasswordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCities() async {
    try {
      final data = await widget.api.get(ApiConfig.cities);
      setState(() {
        _cities = data as List;
        _loadingCities = false;
      });
    } catch (_) {
      setState(() => _loadingCities = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      await widget.api.put('${ApiConfig.users}/${widget.client['id']}', {
        'firstName': _firstNameCtrl.text.trim(),
        'lastName': _lastNameCtrl.text.trim(),
        'phoneNumber': _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
        'cityId': _selectedCityId,
        'driverLicenseNo': _licenseCtrl.text.trim().isEmpty ? null : _licenseCtrl.text.trim(),
        'isActive': widget.client['isActive'],
      });
      if (_changePassword && _newPasswordCtrl.text.isNotEmpty) {
        await widget.api.post('${ApiConfig.users}/${widget.client['id']}/reset-password', {
          'newPassword': _newPasswordCtrl.text,
        });
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Podaci su uspješno ažurirani.'), backgroundColor: AppTheme.success),
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
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
      child: SizedBox(
        width: 460,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: AppTheme.accent.withValues(alpha: 0.06),
                border: Border(bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.15))),
              ),
              child: Row(
                children: [
                  const Text('Uredi klijenta',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
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
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _firstNameCtrl,
                            decoration: const InputDecoration(labelText: 'Ime', isDense: true),
                            validator: (v) => v == null || v.trim().isEmpty ? 'Obavezno' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _lastNameCtrl,
                            decoration: const InputDecoration(labelText: 'Prezime', isDense: true),
                            validator: (v) => v == null || v.trim().isEmpty ? 'Obavezno' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneCtrl,
                      decoration: const InputDecoration(labelText: 'Telefon', isDense: true),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),
                    _loadingCities
                        ? const LinearProgressIndicator()
                        : DropdownButtonFormField<int?>(
                            value: _selectedCityId,
                            isExpanded: true,
                            decoration: const InputDecoration(labelText: 'Grad', isDense: true),
                            items: [
                              const DropdownMenuItem<int?>(value: null, child: Text('— Nije odabran —')),
                              ..._cities.map((c) => DropdownMenuItem<int?>(
                                    value: c['id'] as int?,
                                    child: Text(c['name'] ?? '', overflow: TextOverflow.ellipsis),
                                  )),
                            ],
                            onChanged: (val) => setState(() => _selectedCityId = val),
                          ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _licenseCtrl,
                      decoration: const InputDecoration(labelText: 'Broj vozačke dozvole', isDense: true),
                    ),
                    const SizedBox(height: 16),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Postavi novu lozinku'),
                      value: _changePassword,
                      onChanged: (v) => setState(() => _changePassword = v ?? false),
                    ),
                    if (_changePassword) ...[
                      TextFormField(
                        controller: _newPasswordCtrl,
                        obscureText: !_showNewPw,
                        decoration: InputDecoration(
                          labelText: 'Nova lozinka',
                          helperText: 'Min. 8 znakova, mora sadržavati cifru.',
                          isDense: true,
                          suffixIcon: IconButton(
                            icon: Icon(_showNewPw ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                            onPressed: () => setState(() => _showNewPw = !_showNewPw),
                          ),
                        ),
                        validator: (v) {
                          if (!_changePassword) return null;
                          if (v == null || v.isEmpty) return 'Nova lozinka je obavezna.';
                          if (v.length < 8) return 'Min. 8 znakova.';
                          if (!RegExp(r'\d').hasMatch(v)) return 'Mora sadržavati cifru.';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _confirmPasswordCtrl,
                        obscureText: !_showConfirmPw,
                        decoration: InputDecoration(
                          labelText: 'Potvrda nove lozinke',
                          isDense: true,
                          suffixIcon: IconButton(
                            icon: Icon(_showConfirmPw ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                            onPressed: () => setState(() => _showConfirmPw = !_showConfirmPw),
                          ),
                        ),
                        validator: (v) {
                          if (!_changePassword) return null;
                          if (v != _newPasswordCtrl.text) return 'Lozinke se ne poklapaju.';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: _isSaving ? null : () => Navigator.pop(context, false),
                          child: const Text('Odustani'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _isSaving ? null : _save,
                          child: _isSaving
                              ? const SizedBox(
                                  width: 18, height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2))
                              : const Text('Spremi'),
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
