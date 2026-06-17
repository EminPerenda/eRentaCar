import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../config/api_config.dart';
import '../../services/api_service.dart';

class ReservationsScreen extends StatefulWidget {
  const ReservationsScreen({super.key});

  @override
  State<ReservationsScreen> createState() => _ReservationsScreenState();
}

class _ReservationsScreenState extends State<ReservationsScreen> {
  final ApiService _api = ApiService();
  List<dynamic> _reservations = [];
  List<dynamic> _vehicles = [];
  List<dynamic> _locations = [];
  bool _isLoading = true;
  String? _selectedStatus;
  int? _selectedVehicleId;
  int? _selectedPickupLocationId;
  final TextEditingController _clientCtrl = TextEditingController();
  DateTimeRange? _selectedPeriod;
  int _page = 1;
  int _totalCount = 0;
  final int _pageSize = 10;

  final List<Map<String, String>> _statuses = [
    {'value': '', 'label': 'Sve'},
    {'value': 'Pending', 'label': 'Na čekanju'},
    {'value': 'Confirmed', 'label': 'Potvrđena'},
    {'value': 'Active', 'label': 'Aktivna'},
    {'value': 'Completed', 'label': 'Završena'},
    {'value': 'Cancelled', 'label': 'Otkazana'},
  ];

  @override
  void initState() {
    super.initState();
    _loadReservations();
    _loadVehicles();
    _loadLocations();
  }

  Future<void> _loadVehicles() async {
    try {
      final data = await _api.get(ApiConfig.vehicles, params: {'pageSize': 100});
      setState(() => _vehicles = data['items'] as List);
    } catch (_) {}
  }

  Future<void> _loadLocations() async {
    try {
      final data = await _api.get(ApiConfig.locations);
      setState(() => _locations = data as List);
    } catch (_) {}
  }

  Future<void> _loadReservations({bool reset = false}) async {
    if (reset) setState(() => _page = 1);
    setState(() => _isLoading = true);
    try {
      final params = <String, dynamic>{
        'page': _page,
        'pageSize': _pageSize,
      };
      if (_selectedStatus != null && _selectedStatus!.isNotEmpty) {
        params['status'] = _selectedStatus;
      }
      if (_selectedVehicleId != null) params['vehicleId'] = _selectedVehicleId;
      if (_selectedPickupLocationId != null) params['locationId'] = _selectedPickupLocationId;
      if (_clientCtrl.text.trim().isNotEmpty) params['clientName'] = _clientCtrl.text.trim();
      if (_selectedPeriod != null) {
        params['from'] = _selectedPeriod!.start.toIso8601String();
        params['to'] = _selectedPeriod!.end.toIso8601String();
      }
      final data = await _api.get(ApiConfig.reservations, params: params);
      setState(() {
        _reservations = data['items'];
        _totalCount = data['totalCount'];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _confirmReservation(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Potvrda rezervacije'),
        content: const Text('Jeste li sigurni da želite potvrditi ovu rezervaciju?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Odustani')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.success),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Potvrdi'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await _api.patch('${ApiConfig.reservations}/$id/confirm');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rezervacija je uspješno potvrđena.'), backgroundColor: AppTheme.success),
      );
      _loadReservations();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.error),
      );
    }
  }

  Future<void> _rejectReservation(int id) async {
    final reasonCtrl = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Odbijanje rezervacije'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Unesite razlog odbijanja rezervacije:'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonCtrl,
              decoration: const InputDecoration(hintText: 'Razlog...', isDense: true),
              maxLines: 2,
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Odustani')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Odbij'),
          ),
        ],
      ),
    );
    if (confirm != true || reasonCtrl.text.trim().isEmpty) return;
    try {
      await _api.patch('${ApiConfig.reservations}/$id/reject',
          data: {'reason': reasonCtrl.text.trim()});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rezervacija je odbijena.'), backgroundColor: AppTheme.success),
      );
      _loadReservations();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.error),
      );
    }
  }

  Future<void> _activateReservation(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Aktivacija rezervacije'),
        content: const Text('Potvrdite da je klijent preuzeo vozilo i aktivirajte rezervaciju.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Odustani')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accent),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Aktiviraj'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await _api.patch('${ApiConfig.reservations}/$id/activate');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rezervacija je aktivirana.'), backgroundColor: AppTheme.success),
      );
      _loadReservations();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.error),
      );
    }
  }

  Future<void> _cancelReservation(int id) async {
    final reasonCtrl = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Otkazivanje rezervacije'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Unesite razlog otkazivanja:'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonCtrl,
              decoration: const InputDecoration(
                  hintText: 'Razlog...', isDense: true),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Odustani'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Otkaži'),
          ),
        ],
      ),
    );

    if (confirm != true || reasonCtrl.text.trim().isEmpty) return;

    try {
      await _api.patch('${ApiConfig.reservations}/$id/cancel',
          data: {'reason': reasonCtrl.text.trim()});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Rezervacija je otkazana.'),
          backgroundColor: AppTheme.success,
        ),
      );
      _loadReservations();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.error),
      );
    }
  }

  Future<void> _completeReservation(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Završetak rezervacije'),
        content: const Text('Jeste li sigurni da želite završiti ovu rezervaciju?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Odustani'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Završi'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _api.patch('${ApiConfig.reservations}/$id/complete');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Rezervacija je završena.'),
          backgroundColor: AppTheme.success,
        ),
      );
      _loadReservations();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Rezervacije',
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
    return Column(
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: 170,
              child: DropdownButtonFormField<String>(
                key: ValueKey('status-${_selectedStatus ?? 'all'}'),
                initialValue: _selectedStatus ?? '',
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Status', isDense: true),
                items: _statuses
                    .map((s) => DropdownMenuItem<String>(value: s['value'], child: Text(s['label']!)))
                    .toList(),
                onChanged: (val) {
                  setState(() => _selectedStatus = val);
                  _loadReservations(reset: true);
                },
              ),
            ),
            SizedBox(
              width: 180,
              child: DropdownButtonFormField<int?>(
                key: ValueKey('vehicle-${_selectedVehicleId ?? 'all'}'),
                initialValue: _selectedVehicleId,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Vozilo', isDense: true),
                items: [
                  const DropdownMenuItem<int?>(value: null, child: Text('Svi')),
                  ..._vehicles.map((v) => DropdownMenuItem<int?>(
                      value: v['id'] as int?,
                      child: Text('${v['brand']} ${v['model']}', overflow: TextOverflow.ellipsis)))
                ],
                onChanged: (val) {
                  setState(() => _selectedVehicleId = val);
                  _loadReservations(reset: true);
                },
              ),
            ),
            SizedBox(
              width: 190,
              child: DropdownButtonFormField<int?>(
                key: ValueKey('location-${_selectedPickupLocationId ?? 'all'}'),
                initialValue: _selectedPickupLocationId,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Lokacija preuzimanja', isDense: true),
                items: [
                  const DropdownMenuItem<int?>(value: null, child: Text('Sve')),
                  ..._locations.map((l) => DropdownMenuItem<int?>(
                      value: l['id'] as int?,
                      child: Text(l['name'] ?? l['city'] ?? '', overflow: TextOverflow.ellipsis)))
                ],
                onChanged: (val) {
                  setState(() => _selectedPickupLocationId = val);
                  _loadReservations(reset: true);
                },
              ),
            ),
            SizedBox(
              width: 180,
              child: TextField(
                controller: _clientCtrl,
                decoration: const InputDecoration(labelText: 'Klijent (ime/email)', isDense: true),
                onSubmitted: (_) => _loadReservations(reset: true),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: Text('Ukupno: $_totalCount rezervacija', style: const TextStyle(color: AppTheme.textMuted)),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            ElevatedButton(
              onPressed: () async {
                final picked = await showDateRangePicker(context: context, firstDate: DateTime(2000), lastDate: DateTime(2100));
                if (picked != null) {
                  setState(() => _selectedPeriod = picked);
                  _loadReservations(reset: true);
                }
              },
              child: Text(_selectedPeriod == null ? 'Period' : '${_selectedPeriod!.start.day}.${_selectedPeriod!.start.month}.${_selectedPeriod!.start.year} - ${_selectedPeriod!.end.day}.${_selectedPeriod!.end.month}.${_selectedPeriod!.end.year}'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedPeriod = null;
                  _clientCtrl.clear();
                  _selectedVehicleId = null;
                  _selectedPickupLocationId = null;
                  _selectedStatus = '';
                });
                _loadReservations(reset: true);
              },
              child: const Text('Reset'),
            ),
          ],
        )
      ],
    );
  }

  Widget _buildTable() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_reservations.isEmpty) {
      return const Center(child: Text('Nema rezervacija.'));
    }

    return Card(
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(AppTheme.background),
            columns: const [
              DataColumn(label: Text('Klijent')),
              DataColumn(label: Text('Vozilo')),
              DataColumn(label: Text('Period')),
              DataColumn(label: Text('Lokacije')),
              DataColumn(label: Text('Cijena')),
              DataColumn(label: Text('Status')),
              DataColumn(label: Text('Akcije')),
            ],
            rows: _reservations.map((r) {
              final status = r['status'] as String;
              return DataRow(cells: [
                DataCell(Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(r['clientName'],
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    Text(r['clientEmail'],
                        style: const TextStyle(
                            fontSize: 11, color: AppTheme.textMuted)),
                  ],
                )),
                DataCell(Text(r['vehicle'])),
                DataCell(Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(_formatDate(r['startDate'])),
                    Text(_formatDate(r['endDate']),
                        style: const TextStyle(color: AppTheme.textMuted)),
                  ],
                )),
                DataCell(Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(r['pickupLocation'],
                        style: const TextStyle(fontSize: 12)),
                    Text(r['dropoffLocation'],
                        style: const TextStyle(
                            fontSize: 12, color: AppTheme.textMuted)),
                  ],
                )),
                DataCell(Text('${r['totalPrice']} KM',
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.accent))),
                DataCell(_buildStatusBadge(status)),
                DataCell(_buildActions(r)),
              ]);
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildActions(Map<String, dynamic> r) {
    final status = r['status'] as String;
    final id = r['id'] as int;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Details — always available
        IconButton(
          icon: const Icon(Icons.remove_red_eye, size: 18),
          onPressed: () => _showReservationDetail(id),
          tooltip: 'Detalji',
        ),

        // Confirm — only for Pending
        if (status == 'Pending') ...[
          IconButton(
            icon: const Icon(Icons.check_circle_outline, color: AppTheme.success, size: 20),
            onPressed: () => _confirmReservation(id),
            tooltip: 'Potvrdi',
          ),
          IconButton(
            icon: const Icon(Icons.block_outlined, color: AppTheme.error, size: 20),
            onPressed: () => _rejectReservation(id),
            tooltip: 'Odbij',
          ),
        ],

        // Activate — only for Confirmed (car picked up)
        if (status == 'Confirmed')
          IconButton(
            icon: const Icon(Icons.drive_eta_outlined, color: Colors.blue, size: 20),
            onPressed: () => _activateReservation(id),
            tooltip: 'Aktiviraj (vozilo preuzeto)',
          ),

        // Complete — for Confirmed or Active
        if (status == 'Confirmed' || status == 'Active')
          IconButton(
            icon: const Icon(Icons.done_all, color: AppTheme.accent, size: 20),
            onPressed: () => _completeReservation(id),
            tooltip: 'Završi',
          ),

        // Cancel — for non-terminal statuses
        if (status != 'Cancelled' && status != 'Completed')
          IconButton(
            icon: const Icon(Icons.cancel_outlined, color: AppTheme.error, size: 20),
            onPressed: () => _cancelReservation(id),
            tooltip: 'Otkaži',
          ),

        // Disabled indicator for terminal statuses
        if (status == 'Completed')
          Tooltip(
            message: 'Završena rezervacija — nema dostupnih akcija',
            child: Icon(Icons.lock_outline, size: 18, color: Colors.grey.shade400),
          ),
        if (status == 'Cancelled')
          Tooltip(
            message: 'Otkazana rezervacija — nema dostupnih akcija',
            child: Icon(Icons.lock_outline, size: 18, color: Colors.grey.shade400),
          ),
      ],
    );
  }

  Future<void> _showReservationDetail(int id) async {
    try {
      final data = await _api.get('${ApiConfig.reservations}/$id');
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          title: const Text('Detalji rezervacije'),
          content: SizedBox(
            width: 560,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Klijent: ${data['clientName']} (${data['clientEmail']})'),
                  const SizedBox(height: 8),
                  Text('Vozilo: ${data['vehicle']}'),
                  const SizedBox(height: 8),
                  Text('Period: ${_formatDate(data['startDate'])} - ${_formatDate(data['endDate'])}'),
                  const SizedBox(height: 8),
                  Text('Preuzimanje: ${data['pickupLocation']}'),
                  Text('Povrat: ${data['dropoffLocation']}'),
                  const SizedBox(height: 8),
                  const Text('Odabrana oprema:'),
                  if (data['extras'] != null && (data['extras'] as List).isNotEmpty)
                    ...((data['extras'] as List).map((e) => Padding(
                          padding: const EdgeInsets.only(left: 8, top: 2),
                          child: Text('- ${e['serviceName']} x${e['quantity']} (${e['priceAtTime']} KM)'),
                        )))
                  else
                    const Padding(
                      padding: EdgeInsets.only(left: 8, top: 2),
                      child: Text('- Nema odabrane opreme'),
                    ),
                  const SizedBox(height: 8),
                  Text('Cijena: ${data['totalPrice']} KM'),
                  const SizedBox(height: 12),
                  const Text('Evidencija:'),
                  const SizedBox(height: 6),
                  if (data['approvedBy'] != null)
                    Text('Potvrdio: ${data['approvedBy']} (${_formatDateTime(data['approvedAt'])})'),
                  if (data['activatedBy'] != null)
                    Text('Aktivirao: ${data['activatedBy']} (${_formatDateTime(data['activatedAt'])})'),
                  if (data['completedBy'] != null)
                    Text('Završio: ${data['completedBy']} (${_formatDateTime(data['completedAt'])})'),
                  if (data['cancelledBy'] != null) ...[
                    () {
                      final reason = data['cancellationReason']?.toString() ?? '';
                      final isRejection = reason.startsWith('[ODBIJENO]');
                      return Text(
                        isRejection
                            ? 'Odbio: ${data['cancelledBy']} (${_formatDateTime(data['cancelledAt'])})'
                            : 'Otkazao: ${data['cancelledBy']} (${_formatDateTime(data['cancelledAt'])})',
                        style: const TextStyle(color: AppTheme.error),
                      );
                    }(),
                    if (data['cancellationReason'] != null && data['cancellationReason'].toString().trim().isNotEmpty)
                      Text(
                        'Razlog: ${data['cancellationReason'].toString().replaceFirst('[ODBIJENO] ', '')}',
                        style: const TextStyle(color: AppTheme.error),
                      ),
                  ],
                  Text('Kreirano: ${_formatDateTime(data['createdAt'])}'),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Zatvori')),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.error));
    }
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 12, fontWeight: FontWeight.w600)),
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
                    _loadReservations();
                  }
                : null,
          ),
          Text('Stranica $_page od $totalPages'),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _page < totalPages
                ? () {
                    setState(() => _page++);
                    _loadReservations();
                  }
                : null,
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateStr) {
    final date = DateTime.parse(dateStr);
    return '${date.day}.${date.month}.${date.year}';
  }

  String _formatDateTime(dynamic value) {
    if (value == null) return '-';
    final date = DateTime.parse(value.toString()).toLocal();
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return '${date.day}.${date.month}.${date.year} ${twoDigits(date.hour)}:${twoDigits(date.minute)}';
  }
}