import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../config/app_theme.dart';
import '../../config/api_config.dart';
import '../../services/api_service.dart';

class LocationsScreen extends StatefulWidget {
  const LocationsScreen({super.key});

  @override
  State<LocationsScreen> createState() => _LocationsScreenState();
}

class _LocationsScreenState extends State<LocationsScreen> {
  final ApiService _api = ApiService();
  List<dynamic> _locations = [];
  List<dynamic> _cities = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _api.get(ApiConfig.locations),
        _api.get(ApiConfig.cities),
      ]);
      setState(() {
        _locations = results[0];
        _cities = results[1];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteLocation(int id, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Brisanje lokacije'),
        content: Text('Jeste li sigurni da želite obrisati lokaciju "$name"?'),
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

    if (confirm != true) return;

    try {
      await _api.delete('${ApiConfig.locations}/$id');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lokacija je uspješno obrisana.'),
          backgroundColor: AppTheme.success,
        ),
      );
      _loadData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.error),
      );
    }
  }

  void _showLocationDialog({Map<String, dynamic>? location}) {
    final nameCtrl = TextEditingController(text: location?['name'] ?? '');
    final addressCtrl = TextEditingController(text: location?['address'] ?? '');
    final phoneCtrl = TextEditingController(text: location?['phone'] ?? '');
    final hoursCtrl = TextEditingController(text: location?['workingHours'] ?? '');

    int? selectedCityId = location != null
        ? _cities.firstWhere((c) => c['name'] == location['city'],
            orElse: () => {'id': null})['id']
        : null;

    double? pickedLat = (location?['latitude'] as num?)?.toDouble();
    double? pickedLng = (location?['longitude'] as num?)?.toDouble();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(location == null ? 'Dodaj lokaciju' : 'Uredi lokaciju'),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Naziv poslovnice', isDense: true),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: addressCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Adresa', isDense: true),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    isExpanded: true,
                    decoration: const InputDecoration(
                        labelText: 'Grad', isDense: true),
                    value: selectedCityId,
                    items: _cities
                        .map((c) => DropdownMenuItem<int>(
                              value: c['id'] as int,
                              child: Text(c['name'],
                                  overflow: TextOverflow.ellipsis),
                            ))
                        .toList(),
                    onChanged: (v) =>
                        setDialogState(() => selectedCityId = v),
                  ),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(
                      child: TextField(
                        controller: phoneCtrl,
                        decoration: const InputDecoration(
                            labelText: 'Telefon', isDense: true),
                        keyboardType: TextInputType.phone,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: hoursCtrl,
                        decoration: const InputDecoration(
                            labelText: 'Radno vrijeme', isDense: true),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 16),
                  // Map coordinate picker
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.background,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: Colors.grey.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Koordinate poslovnice',
                            style: TextStyle(
                                fontSize: 12, color: AppTheme.textMuted)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: pickedLat != null && pickedLng != null
                                  ? Row(
                                      children: [
                                        const Icon(Icons.location_on,
                                            size: 16, color: AppTheme.accent),
                                        const SizedBox(width: 6),
                                        Text(
                                          '${pickedLat!.toStringAsFixed(5)}, ${pickedLng!.toStringAsFixed(5)}',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w500,
                                              color: AppTheme.textDark),
                                        ),
                                      ],
                                    )
                                  : const Row(
                                      children: [
                                        Icon(Icons.location_off_outlined,
                                            size: 16,
                                            color: AppTheme.textMuted),
                                        SizedBox(width: 6),
                                        Text('Nije odabrana lokacija',
                                            style: TextStyle(
                                                color: AppTheme.textMuted)),
                                      ],
                                    ),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton.icon(
                              icon: const Icon(Icons.map_outlined, size: 16),
                              label: const Text('Odaberi na karti'),
                              onPressed: () async {
                                final result = await showDialog<LatLng>(
                                  context: ctx,
                                  builder: (_) => _MapPickerDialog(
                                    initialLat: pickedLat,
                                    initialLng: pickedLng,
                                  ),
                                );
                                if (result != null) {
                                  setDialogState(() {
                                    pickedLat = result.latitude;
                                    pickedLng = result.longitude;
                                  });
                                }
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Odustani'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  final body = {
                    'name': nameCtrl.text.trim(),
                    'address': addressCtrl.text.trim(),
                    'cityId': selectedCityId,
                    'phone': phoneCtrl.text.trim(),
                    'workingHours': hoursCtrl.text.trim(),
                    'latitude': pickedLat,
                    'longitude': pickedLng,
                  };

                  if (location == null) {
                    await _api.post(ApiConfig.locations, body);
                  } else {
                    await _api.put(
                        '${ApiConfig.locations}/${location['id']}', body);
                  }

                  Navigator.pop(ctx);
                  _loadData();
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(location == null
                          ? 'Lokacija je uspješno dodana.'
                          : 'Lokacija je uspješno ažurirana.'),
                      backgroundColor: AppTheme.success,
                    ),
                  );
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(e.toString()),
                        backgroundColor: AppTheme.error),
                  );
                }
              },
              child: Text(location == null ? 'Dodaj' : 'Sačuvaj'),
            ),
          ],
        ),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Lokacije',
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDark)),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Dodaj lokaciju'),
                  onPressed: () => _showLocationDialog(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(child: _buildContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_locations.isEmpty) {
      return const Center(child: Text('Nema lokacija.'));
    }

    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Card(
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(AppTheme.background),
            dataRowMinHeight: 70,
            dataRowMaxHeight: 80,
            columns: const [
              DataColumn(label: SizedBox(width: 140, child: Text('Naziv'))),
              DataColumn(label: SizedBox(width: 160, child: Text('Adresa'))),
              DataColumn(label: SizedBox(width: 100, child: Text('Grad'))),
              DataColumn(label: SizedBox(width: 120, child: Text('Telefon'))),
              DataColumn(label: SizedBox(width: 140, child: Text('Radno vrijeme'))),
              DataColumn(label: SizedBox(width: 160, child: Text('Vozila'))),
              DataColumn(label: SizedBox(width: 80, child: Text('Akcije'))),
            ],
            rows: _locations.map((l) {
              return DataRow(cells: [
                DataCell(SizedBox(
                  width: 140,
                  child: Text(l['name'],
                      style: const TextStyle(fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2),
                )),
                DataCell(SizedBox(
                  width: 160,
                  child: Text(l['address'],
                      overflow: TextOverflow.ellipsis, maxLines: 2),
                )),
                DataCell(SizedBox(
                  width: 100,
                  child: Text(l['city'], overflow: TextOverflow.ellipsis),
                )),
                DataCell(SizedBox(
                  width: 120,
                  child: Text(l['phone'] ?? '-'),
                )),
                DataCell(SizedBox(
                  width: 140,
                  child: Text(l['workingHours'] ?? '-',
                      overflow: TextOverflow.ellipsis, maxLines: 2),
                )),
                DataCell(SizedBox(
                  width: 160,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.success.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${l['availableVehicles']} dostupna',
                          style: const TextStyle(
                              color: AppTheme.success,
                              fontSize: 12,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.accent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${l['rentedVehicles']} iznajmljena',
                          style: const TextStyle(
                              color: AppTheme.accent,
                              fontSize: 12,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                )),
                DataCell(Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined,
                          color: AppTheme.accent, size: 20),
                      onPressed: () => _showLocationDialog(location: l),
                      tooltip: 'Uredi',
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline,
                          color: AppTheme.error, size: 20),
                      onPressed: () => _deleteLocation(l['id'], l['name']),
                      tooltip: 'Obriši',
                    ),
                  ],
                )),
              ]);
            }).toList(),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Map Picker Dialog
// ─────────────────────────────────────────────────────────────────────────────

class _MapPickerDialog extends StatefulWidget {
  final double? initialLat;
  final double? initialLng;

  const _MapPickerDialog({this.initialLat, this.initialLng});

  @override
  State<_MapPickerDialog> createState() => _MapPickerDialogState();
}

class _MapPickerDialogState extends State<_MapPickerDialog> {
  LatLng? _selected;
  final MapController _mapController = MapController();

  // Default center: Sarajevo, Bosnia
  static const LatLng _defaultCenter = LatLng(43.8563, 18.4131);

  @override
  void initState() {
    super.initState();
    if (widget.initialLat != null && widget.initialLng != null) {
      _selected = LatLng(widget.initialLat!, widget.initialLng!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final initialCenter = _selected ?? _defaultCenter;
    final initialZoom = _selected != null ? 14.0 : 7.5;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
      child: SizedBox(
        width: 680,
        height: 520,
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: AppTheme.accent.withValues(alpha: 0.06),
                border: Border(
                    bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.15))),
              ),
              child: Row(
                children: [
                  const Icon(Icons.map_outlined, color: AppTheme.accent, size: 20),
                  const SizedBox(width: 8),
                  const Text('Odaberi lokaciju na karti',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDark)),
                  const Spacer(),
                  const Text('Klikni na kartu da postaviš marker',
                      style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                  const SizedBox(width: 12),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            // Map
            Expanded(
              child: ClipRect(
                child: FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: initialCenter,
                    initialZoom: initialZoom,
                    onTap: (tapPosition, latLng) {
                      setState(() => _selected = latLng);
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.erentacar.desktop',
                    ),
                    if (_selected != null)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _selected!,
                            width: 40,
                            height: 40,
                            child: const Icon(Icons.location_pin,
                                color: Colors.red, size: 40),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            // Footer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.background,
                border: Border(
                    top: BorderSide(color: Colors.grey.withValues(alpha: 0.15))),
              ),
              child: Row(
                children: [
                  if (_selected != null) ...[
                    const Icon(Icons.location_on,
                        size: 16, color: AppTheme.accent),
                    const SizedBox(width: 6),
                    Text(
                      '${_selected!.latitude.toStringAsFixed(6)}, ${_selected!.longitude.toStringAsFixed(6)}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w500, color: AppTheme.textDark),
                    ),
                  ] else
                    const Text('Klikni na kartu za odabir koordinata',
                        style: TextStyle(color: AppTheme.textMuted)),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Odustani'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Potvrdi'),
                    onPressed: _selected == null
                        ? null
                        : () => Navigator.pop(context, _selected),
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
