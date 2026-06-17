import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../config/app_theme.dart';
import '../../config/api_config.dart';
import '../../services/api_service.dart';
import 'vehicle_detail_screen.dart';

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
  List<dynamic> _fuelTypes = [];
  List<dynamic> _transmissions = [];
  List<dynamic> _cities = [];
  List<dynamic> _recommendations = [];
  bool _isLoading = true;
  bool _isLoadingRecommendations = true;
  String? _error;

  int? _selectedCategoryId;
  int? _selectedFuelTypeId;
  int? _selectedTransmissionId;
  int? _selectedCityId;
  int? _selectedSeats;
  double _currentMinPrice = 0;
  double _currentMaxPrice = 500;
  DateTime? _startDate;
  DateTime? _endDate;
  String _sortBy = 'newest';
  int _page = 1;
  int _totalPages = 1;

  @override
void initState() {
  super.initState();
  _loadData();
  
  // Refresh preporuka kad se korisnik vrati na ekran
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (mounted) _loadRecommendations();
  });
}

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadVehicles(),
      _loadCategories(),
      _loadReferenceData(),
      _loadRecommendations(),
    ]);
  }

  Future<void> _loadCategories() async {
    try {
      final data = await _api.get(ApiConfig.categories);
      setState(() => _categories = data);
    } catch (_) {}
  }

  Future<void> _loadReferenceData() async {
    try {
      final results = await Future.wait([
        _api.get(ApiConfig.fuelTypes),
        _api.get(ApiConfig.transmissions),
        _api.get(ApiConfig.cities),
      ]);
      setState(() {
        _fuelTypes = results[0];
        _transmissions = results[1];
        _cities = results[2];
      });
    } catch (_) {}
  }

  Future<void> _loadRecommendations() async {
    setState(() => _isLoadingRecommendations = true);
    try {
      final data = await _api.get(ApiConfig.recommendations);
      setState(() {
        _recommendations = data;
        _isLoadingRecommendations = false;
      });
    } catch (_) {
      setState(() => _isLoadingRecommendations = false);
    }
  }

  Future<void> _loadVehicles({bool reset = false}) async {
    if (reset) {
      setState(() {
        _page = 1;
        _vehicles = [];
      });
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final params = <String, dynamic>{
        'page': _page,
        'pageSize': 10,
        'sortBy': _sortBy,
      };

      if (_searchController.text.isNotEmpty) {
        params['search'] = _searchController.text;
      }
      if (_selectedCategoryId != null) {
        params['categoryId'] = _selectedCategoryId;
      }
      if (_selectedFuelTypeId != null) {
        params['fuelTypeId'] = _selectedFuelTypeId;
      }
      if (_selectedTransmissionId != null) {
        params['transmissionId'] = _selectedTransmissionId;
      }
      if (_selectedCityId != null) {
        params['cityId'] = _selectedCityId;
      }
      if (_selectedSeats != null) {
        params['seats'] = _selectedSeats;
      }
      if (_currentMinPrice > 0) {
        params['minPrice'] = _currentMinPrice;
      }
      if (_currentMaxPrice < 500) {
        params['maxPrice'] = _currentMaxPrice;
      }
      if (_startDate != null) {
        params['startDate'] = _startDate!.toIso8601String();
      }
      if (_endDate != null) {
        params['endDate'] = _endDate!.toIso8601String();
      }

      final data = await _api.get(ApiConfig.vehicles, params: params);

      setState(() {
        _vehicles = data['items'];
        _totalPages = data['totalPages'];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  bool get _hasActiveFilters =>
      _selectedCategoryId != null ||
      _selectedFuelTypeId != null ||
      _selectedTransmissionId != null ||
      _selectedCityId != null ||
      _selectedSeats != null ||
      _currentMinPrice > 0 ||
      _currentMaxPrice < 500 ||
      _startDate != null ||
      _endDate != null;

  void _clearFilters() {
    setState(() {
      _selectedCategoryId = null;
      _selectedFuelTypeId = null;
      _selectedTransmissionId = null;
      _selectedCityId = null;
      _selectedSeats = null;
      _currentMinPrice = 0;
      _currentMaxPrice = 500;
      _startDate = null;
      _endDate = null;
    });
    _loadVehicles(reset: true);
  }

  Future<void> _pickDate(bool isStart) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart
          ? (_startDate ?? now)
          : (_endDate ?? now.add(const Duration(days: 1))),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_endDate != null && _endDate!.isBefore(_startDate!)) {
            _endDate = null;
          }
        } else {
          _endDate = picked;
        }
      });
      _loadVehicles(reset: true);
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vozila'),
        actions: [
          if (_hasActiveFilters)
            IconButton(
              icon: const Icon(Icons.filter_alt_off),
              onPressed: _clearFilters,
              tooltip: 'Ukloni filtere',
            ),
          IconButton(
            icon: Badge(
              isLabelVisible: _hasActiveFilters,
              child: const Icon(Icons.tune),
            ),
            onPressed: _showFilterSheet,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildDateFilter(),
          _buildActiveFiltersRow(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(_error!,
                                style: const TextStyle(
                                    color: AppTheme.error)),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadVehicles(),
                              child: const Text('Pokušaj ponovo'),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () => _loadData(),
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _vehicles.length +
                              (_page < _totalPages ? 1 : 0) +
                              (_recommendations.isNotEmpty ? 1 : 0) +
                              (_vehicles.isEmpty ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == 0 &&
                                _recommendations.isNotEmpty) {
                              return _buildRecommendations();
                            }
                            final vehicleIndex =
                                _recommendations.isNotEmpty
                                    ? index - 1
                                    : index;
                            if (_vehicles.isEmpty &&
                                vehicleIndex == 0) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(32),
                                  child: Text(
                                      'Nema dostupnih vozila.'),
                                ),
                              );
                            }
                            if (vehicleIndex == _vehicles.length) {
                              return _buildLoadMoreButton();
                            }
                            if (vehicleIndex >= 0 &&
                                vehicleIndex < _vehicles.length) {
                              return _buildVehicleCard(
                                  _vehicles[vehicleIndex]);
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Pretraži vozila...',
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
        ),
        onSubmitted: (_) => _loadVehicles(reset: true),
      ),
    );
  }

  Widget _buildDateFilter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              icon: const Icon(Icons.calendar_today_outlined,
                  size: 16),
              label: Text(
                _startDate != null
                    ? _formatDate(_startDate!)
                    : 'Od datuma',
                style: TextStyle(
                  color: _startDate != null
                      ? AppTheme.accent
                      : AppTheme.textMuted,
                ),
              ),
              onPressed: () => _pickDate(true),
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: _startDate != null
                      ? AppTheme.accent
                      : Colors.grey.shade300,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton.icon(
              icon: const Icon(Icons.calendar_today_outlined,
                  size: 16),
              label: Text(
                _endDate != null
                    ? _formatDate(_endDate!)
                    : 'Do datuma',
                style: TextStyle(
                  color: _endDate != null
                      ? AppTheme.accent
                      : AppTheme.textMuted,
                ),
              ),
              onPressed: () => _pickDate(false),
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: _endDate != null
                      ? AppTheme.accent
                      : Colors.grey.shade300,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveFiltersRow() {
    final activeFilters = <String>[];

    if (_selectedCategoryId != null) {
      final cat = _categories.firstWhere(
          (c) => c['id'] == _selectedCategoryId,
          orElse: () => {'name': ''});
      if (cat['name'] != '') activeFilters.add(cat['name']);
    }
    if (_selectedCityId != null) {
      final city = _cities.firstWhere(
          (c) => c['id'] == _selectedCityId,
          orElse: () => {'name': ''});
      if (city['name'] != '') activeFilters.add(city['name']);
    }
    if (_selectedFuelTypeId != null) {
      final fuel = _fuelTypes.firstWhere(
          (f) => f['id'] == _selectedFuelTypeId,
          orElse: () => {'name': ''});
      if (fuel['name'] != '') activeFilters.add(fuel['name']);
    }
    if (_selectedTransmissionId != null) {
      final trans = _transmissions.firstWhere(
          (t) => t['id'] == _selectedTransmissionId,
          orElse: () => {'name': ''});
      if (trans['name'] != '') activeFilters.add(trans['name']);
    }
    if (_selectedSeats != null) {
      activeFilters.add('$_selectedSeats sjedišta');
    }
    if (_currentMinPrice > 0 || _currentMaxPrice < 500) {
      activeFilters.add(
          '${_currentMinPrice.toInt()}-${_currentMaxPrice.toInt()} KM');
    }

    if (activeFilters.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: activeFilters.length,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Chip(
            label: Text(activeFilters[index],
                style: const TextStyle(fontSize: 12)),
            backgroundColor:
                AppTheme.accent.withValues(alpha: 0.1),
            side: BorderSide(
                color: AppTheme.accent.withValues(alpha: 0.3)),
            labelStyle: const TextStyle(color: AppTheme.accent),
            deleteIcon: const Icon(Icons.close,
                size: 14, color: AppTheme.accent),
            onDeleted: _clearFilters,
          ),
        ),
      ),
    );
  }

  Widget _buildRecommendations() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(0, 0, 0, 12),
          child: Row(
            children: [
              Icon(Icons.recommend,
                  color: AppTheme.accent, size: 20),
              SizedBox(width: 8),
              Text(
                'Preporučeno za vas',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _recommendations.length,
            itemBuilder: (context, index) {
              final r = _recommendations[index];
              return _buildRecommendationCard(r);
            },
          ),
        ),
        const SizedBox(height: 8),
        const Divider(),
        const SizedBox(height: 8),
        const Text(
          'Sva vozila',
          style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildRecommendationCard(Map<String, dynamic> vehicle) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              VehicleDetailScreen(vehicleId: vehicle['id']),
        ),
      ),
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12)),
              child: vehicle['primaryImageUrl'] != null
                  ? CachedNetworkImage(
                      imageUrl: (vehicle['primaryImageUrl'] is String && (vehicle['primaryImageUrl'] as String).startsWith('http'))
                          ? vehicle['primaryImageUrl']
                          : ApiConfig.baseUrl + (vehicle['primaryImageUrl'] ?? ''),
                      height: 100,
                      width: 160,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => Container(
                        height: 100,
                        color: AppTheme.background,
                        child: const Center(
                          child: Icon(Icons.directions_car,
                              size: 48, color: AppTheme.textMuted),
                        ),
                      ),
                    )
                  : Container(
                      height: 100,
                      color: AppTheme.background,
                      child: const Center(
                        child: Icon(Icons.directions_car,
                            size: 48, color: AppTheme.textMuted),
                      ),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    vehicle['vehicle'] ?? '',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${vehicle['pricePerDay']} KM/dan',
                    style: const TextStyle(
                        color: AppTheme.accent,
                        fontWeight: FontWeight.w600,
                        fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.recommend_outlined,
                          size: 12, color: AppTheme.textMuted),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          vehicle['reason'] ??
                              'Popularno vozilo',
                          style: const TextStyle(
                              fontSize: 10,
                              color: AppTheme.textMuted),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleCard(Map<String, dynamic> vehicle) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                VehicleDetailScreen(vehicleId: vehicle['id']),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12)),
              child: vehicle['primaryImageUrl'] != null
                    ? CachedNetworkImage(
                      imageUrl: (vehicle['primaryImageUrl'] is String && (vehicle['primaryImageUrl'] as String).startsWith('http'))
                        ? vehicle['primaryImageUrl']
                        : ApiConfig.baseUrl + (vehicle['primaryImageUrl'] ?? ''),
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) =>
                          _buildImagePlaceholder(),
                    )
                  : _buildImagePlaceholder(),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '${vehicle['brand']} ${vehicle['model']}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textDark,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.accent
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${vehicle['pricePerDay']} KM/dan',
                          style: const TextStyle(
                            color: AppTheme.accent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildSpec(Icons.category_outlined,
                          vehicle['category']),
                      const SizedBox(width: 16),
                      _buildSpec(
                          Icons.local_gas_station_outlined,
                          vehicle['fuelType']),
                      const SizedBox(width: 16),
                      _buildSpec(Icons.settings_outlined,
                          vehicle['transmission']),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.star,
                          color: Colors.amber, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        vehicle['averageRating'] > 0
                            ? '${vehicle['averageRating']} (${vehicle['reviewCount']})'
                            : 'Bez ocjene',
                        style: const TextStyle(
                            color: AppTheme.textMuted),
                      ),
                      const Spacer(),
                      const Icon(Icons.location_on_outlined,
                          size: 16, color: AppTheme.textMuted),
                      const SizedBox(width: 4),
                      Text(
                        vehicle['currentLocation'],
                        style: const TextStyle(
                            color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpec(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppTheme.textMuted),
        const SizedBox(width: 4),
        Text(text,
            style: const TextStyle(
                color: AppTheme.textMuted, fontSize: 12)),
      ],
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      height: 180,
      color: AppTheme.background,
      child: const Center(
        child: Icon(Icons.directions_car,
            size: 64, color: AppTheme.textMuted),
      ),
    );
  }

  Widget _buildLoadMoreButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: ElevatedButton(
          onPressed: () {
            setState(() => _page++);
            _loadVehicles();
          },
          child: const Text('Učitaj više'),
        ),
      ),
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => SafeArea(
          child: DraggableScrollableSheet(
            initialChildSize: 0.85,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            expand: false,
            builder: (ctx, scrollController) =>
                SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Filteri i sortiranje',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold)),
                      TextButton(
                        onPressed: () {
                          _clearFilters();
                          Navigator.pop(ctx);
                        },
                        child: const Text('Resetuj'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('Sortiraj po',
                      style: TextStyle(
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...[
                    'newest',
                    'price_asc',
                    'price_desc',
                    'rating'
                  ].map((s) {
                    final labels = {
                      'newest': 'Najnovije',
                      'price_asc': 'Cijena rastuće',
                      'price_desc': 'Cijena padajuće',
                      'rating': 'Ocjena',
                    };
                    return RadioListTile<String>(
                      title: Text(labels[s]!),
                      value: s,
                      groupValue: _sortBy,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (val) {
                        setState(() => _sortBy = val!);
                        setModalState(() {});
                      },
                    );
                  }),
                  const Divider(),
                  const SizedBox(height: 8),
                  const Text('Kategorija',
                      style: TextStyle(
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int?>(
                    value: _selectedCategoryId,
                    decoration: const InputDecoration(
                        isDense: true,
                        hintText: 'Sve kategorije'),
                    items: [
                      const DropdownMenuItem<int?>(
                          value: null,
                          child: Text('Sve kategorije')),
                      ..._categories.map((c) =>
                          DropdownMenuItem<int>(
                            value: c['id'] as int,
                            child: Text(c['name']),
                          )),
                    ],
                    onChanged: (val) {
                      setState(
                          () => _selectedCategoryId = val);
                      setModalState(() {});
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text('Grad',
                      style: TextStyle(
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int?>(
                    value: _selectedCityId,
                    decoration: const InputDecoration(
                        isDense: true,
                        hintText: 'Svi gradovi'),
                    items: [
                      const DropdownMenuItem<int?>(
                          value: null,
                          child: Text('Svi gradovi')),
                      ..._cities.map((c) =>
                          DropdownMenuItem<int>(
                            value: c['id'] as int,
                            child: Text(c['name']),
                          )),
                    ],
                    onChanged: (val) {
                      setState(() => _selectedCityId = val);
                      setModalState(() {});
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text('Gorivo',
                      style: TextStyle(
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int?>(
                    value: _selectedFuelTypeId,
                    decoration: const InputDecoration(
                        isDense: true,
                        hintText: 'Svi tipovi'),
                    items: [
                      const DropdownMenuItem<int?>(
                          value: null,
                          child: Text('Svi tipovi')),
                      ..._fuelTypes.map((f) =>
                          DropdownMenuItem<int>(
                            value: f['id'] as int,
                            child: Text(f['name']),
                          )),
                    ],
                    onChanged: (val) {
                      setState(
                          () => _selectedFuelTypeId = val);
                      setModalState(() {});
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text('Mjenjač',
                      style: TextStyle(
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int?>(
                    value: _selectedTransmissionId,
                    decoration: const InputDecoration(
                        isDense: true,
                        hintText: 'Svi tipovi'),
                    items: [
                      const DropdownMenuItem<int?>(
                          value: null,
                          child: Text('Svi tipovi')),
                      ..._transmissions.map((t) =>
                          DropdownMenuItem<int>(
                            value: t['id'] as int,
                            child: Text(t['name']),
                          )),
                    ],
                    onChanged: (val) {
                      setState(
                          () => _selectedTransmissionId = val);
                      setModalState(() {});
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text('Broj sjedišta',
                      style: TextStyle(
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children:
                        [null, 2, 4, 5, 7, 8].map((seats) {
                      final isSelected =
                          _selectedSeats == seats;
                      return ChoiceChip(
                        label: Text(seats == null
                            ? 'Sva'
                            : '$seats'),
                        selected: isSelected,
                        selectedColor: AppTheme.accent
                            .withValues(alpha: 0.2),
                        onSelected: (_) {
                          setState(
                              () => _selectedSeats = seats);
                          setModalState(() {});
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Raspon cijene',
                          style: TextStyle(
                              fontWeight: FontWeight.bold)),
                      Text(
                        '${_currentMinPrice.toInt()} — ${_currentMaxPrice.toInt()} KM',
                        style: const TextStyle(
                            color: AppTheme.accent,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  RangeSlider(
                    values: RangeValues(
                        _currentMinPrice, _currentMaxPrice),
                    min: 0,
                    max: 500,
                    divisions: 50,
                    activeColor: AppTheme.accent,
                    onChanged: (values) {
                      setState(() {
                        _currentMinPrice = values.start;
                        _currentMaxPrice = values.end;
                      });
                      setModalState(() {});
                    },
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _loadVehicles(reset: true);
                      },
                      style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              vertical: 14)),
                      child: const Text('Primijeni filtere',
                          style: TextStyle(fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}