import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../config/app_theme.dart';
import '../../config/api_config.dart';
import '../../services/api_service.dart';

class VehiclesScreen extends StatefulWidget {
  const VehiclesScreen({super.key});

  @override
  State<VehiclesScreen> createState() => _VehiclesScreenState();
}

class _VehiclesScreenState extends State<VehiclesScreen> {
  final ApiService _api = ApiService();
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _vehicles = [];
  List<dynamic> _categories = [];
  bool _isLoading = true;
  int? _selectedCategoryId;
  int _page = 1;
  int _totalCount = 0;
  final int _pageSize = 10;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await Future.wait([_loadVehicles(), _loadCategories()]);
  }

  Future<void> _loadCategories() async {
    try {
      final data = await _api.get(ApiConfig.categories);
      setState(() => _categories = data);
    } catch (_) {}
  }

  Future<void> _loadVehicles({bool reset = false}) async {
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
      if (_selectedCategoryId != null) {
        params['categoryId'] = _selectedCategoryId;
      }
      final data = await _api.get(ApiConfig.vehicles, params: params);
      setState(() {
        _vehicles = data['items'];
        _totalCount = data['totalCount'];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteVehicle(int id, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Brisanje vozila'),
        content: Text('Jeste li sigurni da želite obrisati vozilo "$name"?'),
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
      await _api.delete('${ApiConfig.vehicles}/$id');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vozilo je uspješno obrisano.'),
          backgroundColor: AppTheme.success,
        ),
      );
      _loadVehicles(reset: true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  Future<void> _updateVehicleStatus(int id, int status) async {
    try {
      await _api.patch('${ApiConfig.vehicles}/$id/status?status=$status');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Status vozila je uspješno ažuriran.'),
          backgroundColor: AppTheme.success,
        ),
      );
      _loadVehicles(reset: true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.error),
      );
    }
  }

  Future<List<dynamic>> _loadVehicleImages(int vehicleId) async {
    final data = await _api.get('${ApiConfig.vehicles}/$vehicleId/images');
    return data as List<dynamic>;
  }

  Future<void> _uploadVehicleImage(int vehicleId,
      {required bool isPrimary}) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;

    try {
      await _api.uploadFile(
        '${ApiConfig.vehicles}/$vehicleId/images',
        file,
        data: {'isPrimary': isPrimary},
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Fotografija je uspješno dodana.'),
          backgroundColor: AppTheme.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.error),
      );
    }
  }

  Future<void> _setPrimaryImage(int vehicleId, int imageId) async {
    try {
      await _api.patch('${ApiConfig.vehicles}/$vehicleId/images/$imageId/primary');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Naslovna fotografija je ažurirana.'),
          backgroundColor: AppTheme.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.error),
      );
    }
  }

  Future<void> _deleteVehicleImage(int vehicleId, int imageId) async {
    try {
      await _api.delete('${ApiConfig.vehicles}/$vehicleId/images/$imageId');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Fotografija je obrisana.'),
          backgroundColor: AppTheme.success,
        ),
      );
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Vozni park',
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDark)),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Dodaj vozilo'),
                  onPressed: () => _showVehicleDialog(),
                ),
              ],
            ),
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
              hintText: 'Pretraži po registraciji, marki ili modelu...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _loadVehicles(reset: true);
                      },
                    )
                  : null,
              isDense: true,
            ),
            onSubmitted: (_) => _loadVehicles(reset: true),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: DropdownButtonFormField<int?>(
            value: _selectedCategoryId,
            decoration: const InputDecoration(
                labelText: 'Kategorija', isDense: true),
            items: [
              const DropdownMenuItem(value: null, child: Text('Sve')),
              ..._categories.map((c) => DropdownMenuItem<int>(
                    value: c['id'] as int,
                    child: Text(c['name']),
                  )),
            ],
            onChanged: (val) {
              setState(() => _selectedCategoryId = val);
              _loadVehicles(reset: true);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTable() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_vehicles.isEmpty) {
      return const Center(child: Text('Nema vozila.'));
    }

    return Card(
      child: SingleChildScrollView(
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(AppTheme.background),
          columns: const [
            DataColumn(label: Text('Slika')),
            DataColumn(label: Text('Registracija')),
            DataColumn(label: Text('Vozilo')),
            DataColumn(label: Text('Kategorija')),
            DataColumn(label: Text('Cijena/dan')),
            DataColumn(label: Text('Status')),
            DataColumn(label: Text('Lokacija')),
            DataColumn(label: Text('Akcije')),
          ],
          rows: _vehicles.map((v) {
            final status = v['status'] as String;
            final imageUrl = v['primaryImageUrl'] as String?;
            return DataRow(cells: [
              DataCell(_buildVehicleThumbnail(imageUrl)),
              DataCell(Text(v['licensePlate'],
                  style: const TextStyle(fontWeight: FontWeight.w600))),
              DataCell(Text('${v['brand']} ${v['model']} (${v['year']})')),
              DataCell(Text(v['category'])),
              DataCell(Text('${v['pricePerDay']} KM')),
              DataCell(_buildStatusBadge(status)),
              DataCell(Text(v['currentLocation'],
                  overflow: TextOverflow.ellipsis)),
              DataCell(Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.photo_library_outlined,
                        color: AppTheme.accent, size: 20),
                    onPressed: () => _showVehicleImagesDialog(v),
                    tooltip: 'Fotografije',
                  ),
                  IconButton(
                    icon: const Icon(Icons.swap_vert_outlined,
                        color: AppTheme.accent, size: 20),
                    onPressed: () => _showStatusDialog(v),
                    tooltip: 'Status',
                  ),
                  IconButton(
                    icon: const Icon(Icons.history_outlined,
                        color: AppTheme.accent, size: 20),
                    onPressed: () => _showReservationHistoryDialog(v),
                    tooltip: 'Historija',
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined,
                        color: AppTheme.accent, size: 20),
                    onPressed: () => _showVehicleDialog(vehicle: v),
                    tooltip: 'Uredi',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline,
                        color: AppTheme.error, size: 20),
                    onPressed: () => _deleteVehicle(
                        v['id'], '${v['brand']} ${v['model']}'),
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

  Widget _buildVehicleThumbnail(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return Container(
        width: 52,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Icon(Icons.directions_car_outlined, size: 20, color: Colors.grey),
      );
    }
    final fullUrl = imageUrl.startsWith('http')
        ? imageUrl
        : '${ApiConfig.baseUrl}$imageUrl';
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Image.network(
        fullUrl,
        width: 52,
        height: 36,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: 52,
          height: 36,
          color: Colors.grey.shade200,
          child: const Icon(Icons.broken_image_outlined, size: 20, color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String label;
    switch (status) {
      case 'Available':
        color = AppTheme.success;
        label = 'Dostupno';
        break;
      case 'Rented':
        color = AppTheme.accent;
        label = 'Iznajmljeno';
        break;
      case 'InService':
        color = Colors.orange;
        label = 'Na servisu';
        break;
      default:
        color = Colors.grey;
        label = 'Neaktivno';
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
                    _loadVehicles();
                  }
                : null,
          ),
          Text('Stranica $_page od $totalPages'),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _page < totalPages
                ? () {
                    setState(() => _page++);
                    _loadVehicles();
                  }
                : null,
          ),
        ],
      ),
    );
  }

  void _showStatusDialog(Map<String, dynamic> vehicle) {
    int selectedStatus = _vehicleStatusValue(vehicle['status'] as String);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Promjena statusa vozila'),
        content: DropdownButtonFormField<int>(
          value: selectedStatus,
          decoration: const InputDecoration(labelText: 'Status'),
          items: const [
            DropdownMenuItem(value: 0, child: Text('Dostupno')),
            DropdownMenuItem(value: 1, child: Text('Iznajmljeno')),
            DropdownMenuItem(value: 2, child: Text('Na servisu')),
            DropdownMenuItem(value: 3, child: Text('Neaktivno')),
          ],
          onChanged: (value) {
            if (value != null) selectedStatus = value;
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Odustani'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _updateVehicleStatus(vehicle['id'], selectedStatus);
            },
            child: const Text('Sačuvaj'),
          ),
        ],
      ),
    );
  }

  void _showReservationHistoryDialog(Map<String, dynamic> vehicle) {
    showDialog(
      context: context,
      builder: (ctx) => FutureBuilder<List<dynamic>>(
        future: _api.get(
          '${ApiConfig.vehicles}/${vehicle['id']}/reservations/history',
        ).then((data) => data as List<dynamic>),
        builder: (context, snapshot) {
          final title = 'Historija rezervacija - ${vehicle['brand']} ${vehicle['model']}';

          if (snapshot.connectionState == ConnectionState.waiting) {
            return AlertDialog(
              title: Text(title),
              content: const SizedBox(
                width: 900,
                height: 160,
                child: Center(child: CircularProgressIndicator()),
              ),
            );
          }

          if (snapshot.hasError) {
            return AlertDialog(
              title: Text(title),
              content: Text(snapshot.error.toString()),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Zatvori'),
                ),
              ],
            );
          }

          final history = snapshot.data ?? <dynamic>[];

          return AlertDialog(
            title: Text(title),
            content: SizedBox(
              width: 900,
              child: history.isEmpty
                  ? const Text('Nema rezervacija za ovo vozilo.')
                  : SingleChildScrollView(
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('Klijent')),
                          DataColumn(label: Text('Period')),
                          DataColumn(label: Text('Status')),
                          DataColumn(label: Text('Cijena')),
                          DataColumn(label: Text('Kreirano')),
                        ],
                        rows: history.map((r) {
                          final start = DateTime.parse(r['startDate']);
                          final end = DateTime.parse(r['endDate']);
                          final created = DateTime.parse(r['createdAt']);
                          return DataRow(cells: [
                            DataCell(Text('${r['clientName']}\n${r['clientEmail']}')),
                            DataCell(Text('${start.day}.${start.month}.${start.year} - ${end.day}.${end.month}.${end.year}')),
                            DataCell(Text(r['status'])),
                            DataCell(Text('${r['totalPrice']} KM')),
                            DataCell(Text('${created.day}.${created.month}.${created.year}')),
                          ]);
                        }).toList(),
                      ),
                    ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Zatvori'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showVehicleImagesDialog(Map<String, dynamic> vehicle) {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return FutureBuilder<List<dynamic>>(
            future: _loadVehicleImages(vehicle['id']),
            builder: (context, snapshot) {
              final title = 'Fotografije - ${vehicle['brand']} ${vehicle['model']}';

              if (snapshot.connectionState == ConnectionState.waiting) {
                return AlertDialog(
                  title: Text(title),
                  content: const SizedBox(
                    width: 900,
                    height: 180,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                );
              }

              if (snapshot.hasError) {
                return AlertDialog(
                  title: Text(title),
                  content: Text(snapshot.error.toString()),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Zatvori'),
                    ),
                  ],
                );
              }

              var images = snapshot.data ?? <dynamic>[];

              return AlertDialog(
                title: Text(title),
                content: SizedBox(
                  width: 900,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          ElevatedButton.icon(
                            icon: const Icon(Icons.add_photo_alternate_outlined),
                            label: const Text('Dodaj fotografiju'),
                            onPressed: () async {
                              await _uploadVehicleImage(vehicle['id'], isPrimary: false);
                              if (!mounted) return;
                              setDialogState(() {});
                            },
                          ),
                          const SizedBox(width: 12),
                          OutlinedButton.icon(
                            icon: const Icon(Icons.star_outline),
                            label: const Text('Dodaj naslovnu'),
                            onPressed: () async {
                              await _uploadVehicleImage(vehicle['id'], isPrimary: true);
                              if (!mounted) return;
                              setDialogState(() {});
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      FutureBuilder<List<dynamic>>(
                        future: _loadVehicleImages(vehicle['id']),
                        builder: (context, refreshedSnapshot) {
                          if (refreshedSnapshot.connectionState == ConnectionState.waiting) {
                            return const SizedBox(
                              height: 220,
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }

                          if (refreshedSnapshot.hasError) {
                            return Text(refreshedSnapshot.error.toString());
                          }

                          images = refreshedSnapshot.data ?? images;

                          if (images.isEmpty) {
                            return const Text('Nema fotografija za ovo vozilo.');
                          }

                          return SizedBox(
                            height: 420,
                            child: ListView.builder(
                              itemCount: images.length,
                              itemBuilder: (context, index) {
                                final image = images[index] as Map<String, dynamic>;
                                return Card(
                                  child: ListTile(
                                    leading: SizedBox(
                                      width: 72,
                                      height: 48,
                                      child: Image.network(
                                        ApiConfig.baseUrl + image['imageUrl'],
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.image_not_supported_outlined),
                                      ),
                                    ),
                                    title: Text(image['imageUrl']),
                                    subtitle: image['isPrimary'] == true
                                        ? const Text('Naslovna fotografija')
                                        : const Text('Obična fotografija'),
                                    trailing: Wrap(
                                      spacing: 8,
                                      children: [
                                        if (image['isPrimary'] != true)
                                          IconButton(
                                            icon: const Icon(Icons.star_border),
                                            tooltip: 'Postavi kao naslovnu',
                                            onPressed: () async {
                                              await _setPrimaryImage(vehicle['id'], image['id']);
                                              if (!mounted) return;
                                              setDialogState(() {});
                                            },
                                          ),
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline, color: AppTheme.error),
                                          tooltip: 'Obriši',
                                          onPressed: () async {
                                            await _deleteVehicleImage(vehicle['id'], image['id']);
                                            if (!mounted) return;
                                            setDialogState(() {});
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Zatvori'),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  int _vehicleStatusValue(String status) {
    switch (status) {
      case 'Available':
        return 0;
      case 'Rented':
        return 1;
      case 'InService':
        return 2;
      default:
        return 3;
    }
  }

  void _showVehicleDialog({Map<String, dynamic>? vehicle}) async {
    final brandsData = await _api.get(ApiConfig.brands);
    final fuelTypesData = await _api.get(ApiConfig.fuelTypes);
    final transmissionsData = await _api.get(ApiConfig.transmissions);
    final locationsData = await _api.get(ApiConfig.locations);

    if (!mounted) return;

    final brands = brandsData as List;
    final fuelTypes = fuelTypesData as List;
    final transmissions = transmissionsData as List;
    final locations = locationsData as List;

    final plateCtrl =
        TextEditingController(text: vehicle?['licensePlate'] ?? '');
    final modelCtrl =
        TextEditingController(text: vehicle?['model'] ?? '');
    final yearCtrl =
        TextEditingController(text: vehicle?['year']?.toString() ?? '');
    final seatsCtrl =
        TextEditingController(text: vehicle?['seats']?.toString() ?? '');
    final priceCtrl = TextEditingController(
        text: vehicle?['pricePerDay']?.toString() ?? '');
    final mileageCtrl =
        TextEditingController(text: vehicle?['mileage']?.toString() ?? '');
    final descCtrl =
        TextEditingController(text: vehicle?['description'] ?? '');

    int? selectedBrandId = vehicle != null
        ? brands
            .firstWhere((b) => b['name'] == vehicle['brand'],
                orElse: () => {'id': null})['id']
        : null;

    int? selectedCategoryId = vehicle != null
        ? _categories
            .firstWhere((c) => c['name'] == vehicle['category'],
                orElse: () => {'id': null})['id']
        : null;

    int? selectedFuelTypeId = vehicle != null
        ? fuelTypes
            .firstWhere((f) => f['name'] == vehicle['fuelType'],
                orElse: () => {'id': null})['id']
        : null;

    int? selectedTransmissionId = vehicle != null
        ? transmissions
            .firstWhere((t) => t['name'] == vehicle['transmission'],
                orElse: () => {'id': null})['id']
        : null;

    int? selectedLocationId = vehicle != null
        ? locations
            .firstWhere((l) => l['name'] == vehicle['currentLocation'],
                orElse: () => {'id': null})['id']
        : null;

    final vehicleFormKey = GlobalKey<FormState>();

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(vehicle == null ? 'Dodaj vozilo' : 'Uredi vozilo'),
          content: SizedBox(
            width: 600,
            child: Form(
              key: vehicleFormKey,
              child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(children: [
                    Expanded(
                      child: TextFormField(
                        controller: plateCtrl,
                        decoration: const InputDecoration(
                            labelText: 'Registarska oznaka', isDense: true,
                            helperText: 'Format: ABC-123 ili A12-B-345'),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Registarska oznaka je obavezna.';
                          if (!RegExp(r'^[A-Z0-9]{1,3}-[A-Z0-9]{1,3}(-[A-Z0-9]{1,3})?$').hasMatch(v.trim().toUpperCase())) {
                            return 'Format: ABC-123 ili A12-B-345';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: modelCtrl,
                        decoration: const InputDecoration(
                            labelText: 'Model', isDense: true),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Model je obavezan.' : null,
                      ),
                    ),
                  ]),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(
                      child: TextFormField(
                        controller: yearCtrl,
                        decoration: const InputDecoration(
                            labelText: 'Godište', isDense: true,
                            helperText: '2000–2026'),
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          final year = int.tryParse(v ?? '');
                          if (year == null) return 'Unesite godište (npr. 2022).';
                          if (year < 2000 || year > 2026) return 'Godište mora biti između 2000 i 2026.';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: seatsCtrl,
                        decoration: const InputDecoration(
                            labelText: 'Broj sjedišta', isDense: true,
                            helperText: '2–9'),
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          final n = int.tryParse(v ?? '');
                          if (n == null || n < 2 || n > 9) return 'Unesite broj sjedišta (2–9).';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: priceCtrl,
                        decoration: const InputDecoration(
                            labelText: 'Cijena/dan (KM)', isDense: true,
                            helperText: 'Npr. 50.00'),
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          final n = double.tryParse(v ?? '');
                          if (n == null || n <= 0) return 'Unesite cijenu > 0.';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: mileageCtrl,
                        decoration: const InputDecoration(
                            labelText: 'Kilometraža', isDense: true,
                            helperText: 'Npr. 25000'),
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          final n = int.tryParse(v ?? '');
                          if (n == null || n < 0) return 'Unesite kilometražu ≥ 0.';
                          return null;
                        },
                      ),
                    ),
                  ]),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        decoration: const InputDecoration(
                            labelText: 'Marka', isDense: true),
                        value: selectedBrandId,
                        items: brands
                            .map((b) => DropdownMenuItem<int>(
                                  value: b['id'] as int,
                                  child: Text(b['name']),
                                ))
                            .toList(),
                        onChanged: (v) =>
                            setDialogState(() => selectedBrandId = v),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        decoration: const InputDecoration(
                            labelText: 'Kategorija', isDense: true),
                        value: selectedCategoryId,
                        items: _categories
                            .map((c) => DropdownMenuItem<int>(
                                  value: c['id'] as int,
                                  child: Text(c['name']),
                                ))
                            .toList(),
                        onChanged: (v) =>
                            setDialogState(() => selectedCategoryId = v),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 12),
                  Row(children: [
  Expanded(
    child: DropdownButtonFormField<int>(
      decoration: const InputDecoration(
          labelText: 'Gorivo', isDense: true),
      value: selectedFuelTypeId,
      items: fuelTypes
          .map((f) => DropdownMenuItem<int>(
                value: f['id'] as int,
                child: Text(f['name']),
              ))
          .toList(),
      onChanged: (v) =>
          setDialogState(() => selectedFuelTypeId = v),
    ),
  ),
  const SizedBox(width: 12),
  Expanded(
    child: DropdownButtonFormField<int>(
      decoration: const InputDecoration(
          labelText: 'Mjenjač', isDense: true),
      value: selectedTransmissionId,
      items: transmissions
          .map((t) => DropdownMenuItem<int>(
                value: t['id'] as int,
                child: Text(t['name']),
              ))
          .toList(),
      onChanged: (v) =>
          setDialogState(() => selectedTransmissionId = v),
    ),
  ),
]),
const SizedBox(height: 12),
DropdownButtonFormField<int>(
  decoration: const InputDecoration(
      labelText: 'Lokacija', isDense: true),
  value: selectedLocationId,
  items: locations
      .map((l) => DropdownMenuItem<int>(
            value: l['id'] as int,
            child: Text(l['name']),
          ))
      .toList(),
  onChanged: (v) =>
      setDialogState(() => selectedLocationId = v),
),
const SizedBox(height: 12),
TextField(
  controller: descCtrl,
  decoration: const InputDecoration(
      labelText: 'Opis', isDense: true),
  maxLines: 2,
),
                ],
              ),
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
                if (!vehicleFormKey.currentState!.validate()) return;
                try {
                  final body = {
                    'licensePlate': plateCtrl.text.trim(),
                    'brandId': selectedBrandId,
                    'model': modelCtrl.text.trim(),
                    'year': int.tryParse(yearCtrl.text) ?? 0,
                    'categoryId': selectedCategoryId,
                    'fuelTypeId': selectedFuelTypeId,
                    'transmissionId': selectedTransmissionId,
                    'seats': int.tryParse(seatsCtrl.text) ?? 5,
                    'pricePerDay':
                        double.tryParse(priceCtrl.text) ?? 0,
                    'mileage': int.tryParse(mileageCtrl.text) ?? 0,
                    'description': descCtrl.text.trim(),
                    'currentLocationId': selectedLocationId,
                  };

                  if (vehicle == null) {
                    await _api.post(ApiConfig.vehicles, body);
                  } else {
                    await _api.put(
                        '${ApiConfig.vehicles}/${vehicle['id']}', body);
                  }

                  if (!mounted) return;
                  Navigator.of(context, rootNavigator: true).pop();
                  _loadVehicles(reset: true);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(vehicle == null
                          ? 'Vozilo je uspješno dodano.'
                          : 'Vozilo je uspješno ažurirano.'),
                      backgroundColor: AppTheme.success,
                    ),
                  );
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(e.toString()),
                      backgroundColor: AppTheme.error,
                    ),
                  );
                }
              },
              child: Text(vehicle == null ? 'Dodaj' : 'Sačuvaj'),
            ),
          ],
        ),
      ),
    );
  }
}