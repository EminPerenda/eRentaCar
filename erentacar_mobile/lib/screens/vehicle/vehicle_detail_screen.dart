import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../config/api_config.dart';
import '../../services/api_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'availability_calendar_screen.dart';

class VehicleDetailScreen extends StatefulWidget {
  final int vehicleId;
  const VehicleDetailScreen({super.key, required this.vehicleId});

  @override
  State<VehicleDetailScreen> createState() => _VehicleDetailScreenState();
}

class _VehicleDetailScreenState extends State<VehicleDetailScreen> {
  final ApiService _api = ApiService();
  Map<String, dynamic>? _vehicle;
  List<dynamic> _reviews = [];
  List<dynamic> _images = [];
  bool _isLoading = true;
  late PageController _pageController;
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _loadData();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        _api.get('${ApiConfig.vehicles}/${widget.vehicleId}'),
        _api.get('${ApiConfig.reviews}/vehicle/${widget.vehicleId}'),
        _api.get('${ApiConfig.vehicles}/${widget.vehicleId}/images'),
      ]);
      setState(() {
        _vehicle = results[0];
        _reviews = results[1];
        _images = results[2] is List ? results[2] : [];
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading data: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_vehicle == null) {
      return const Scaffold(
          body: Center(child: Text('Vozilo nije pronađeno.')));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('${_vehicle!['brand']} ${_vehicle!['model']}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                _images.isNotEmpty
                    ? SizedBox(
                        height: 250,
                        child: PageView.builder(
                          controller: _pageController,
                          onPageChanged: (index) => setState(() => _currentImageIndex = index),
                          itemCount: _images.length,
                          itemBuilder: (context, index) {
                            final img = _images[index];
                            final imageUrl = img is Map && img['imageUrl'] != null ? img['imageUrl'] : '';
                            final fullUrl = (imageUrl is String && imageUrl.startsWith('http'))
                                ? imageUrl
                                : ApiConfig.baseUrl + (imageUrl ?? '');
                            return CachedNetworkImage(
                              imageUrl: fullUrl,
                              fit: BoxFit.cover,
                              errorWidget: (_, __, ___) => Container(
                                color: AppTheme.background,
                                child: const Center(
                                  child: Icon(Icons.image_not_supported, size: 48, color: AppTheme.textMuted),
                                ),
                              ),
                            );
                          },
                        ),
                      )
                    : _vehicle!['primaryImageUrl'] != null
                        ? CachedNetworkImage(
                            imageUrl: (_vehicle!['primaryImageUrl'] is String && (_vehicle!['primaryImageUrl'] as String).startsWith('http'))
                                ? _vehicle!['primaryImageUrl']
                                : ApiConfig.baseUrl + (_vehicle!['primaryImageUrl'] ?? ''),
                            height: 250,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) => Container(
                              height: 250,
                              color: AppTheme.background,
                              child: const Center(
                                child: Icon(Icons.directions_car, size: 100, color: AppTheme.textMuted),
                              ),
                            ),
                          )
                        : Container(
                            height: 250,
                            color: AppTheme.background,
                            child: const Center(
                              child: Icon(Icons.directions_car, size: 100, color: AppTheme.textMuted),
                            ),
                          ),
                if (_images.length > 1)
                  Positioned(
                    bottom: 12,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          _images.length,
                          (index) => Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _currentImageIndex == index ? Colors.white : Colors.white70,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '${_vehicle!['brand']} ${_vehicle!['model']}',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textDark,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${_vehicle!['pricePerDay']} KM/dan',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.accent,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 18),
                      const SizedBox(width: 4),
                      Text(
                        _vehicle!['averageRating'] > 0
                            ? '${_vehicle!['averageRating']} (${_vehicle!['reviewCount']} recenzija)'
                            : 'Bez ocjene',
                        style: const TextStyle(color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('Specifikacije',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _buildSpecsGrid(),
                  if (_vehicle!['description'] != null) ...[
                    const SizedBox(height: 16),
                    const Text('Opis',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(_vehicle!['description'],
                        style: const TextStyle(color: AppTheme.textMuted)),
                  ],
                  const SizedBox(height: 16),
                  const Text('Recenzije',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  _reviews.isEmpty
                      ? const Text('Nema recenzija za ovo vozilo.',
                          style: TextStyle(color: AppTheme.textMuted))
                      : Column(
                          children: _reviews
                              .take(3)
                              .map((r) => _buildReviewCard(r))
                              .toList(),
                        ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    AvailabilityCalendarScreen(vehicle: _vehicle!),
              ),
            ),
            icon: const Icon(Icons.calendar_today),
            label: const Text('Provjeri dostupnost i rezerviši',
                style: TextStyle(fontSize: 16)),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSpecsGrid() {
    final specs = [
      {
        'icon': Icons.calendar_today_outlined,
        'label': 'Godište',
        'value': '${_vehicle!['year']}'
      },
      {
        'icon': Icons.people_outlined,
        'label': 'Sjedišta',
        'value': '${_vehicle!['seats']}'
      },
      {
        'icon': Icons.local_gas_station_outlined,
        'label': 'Gorivo',
        'value': _vehicle!['fuelType']
      },
      {
        'icon': Icons.settings_outlined,
        'label': 'Mjenjač',
        'value': _vehicle!['transmission']
      },
      {
        'icon': Icons.speed_outlined,
        'label': 'Kilometraža',
        'value': '${_vehicle!['mileage']} km'
      },
      {
        'icon': Icons.location_on_outlined,
        'label': 'Lokacija',
        'value': _vehicle!['currentLocation']
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2.5,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: specs.length,
      itemBuilder: (context, index) {
        final spec = specs[index];
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.background,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(spec['icon'] as IconData,
                  size: 18, color: AppTheme.accent),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(spec['label'] as String,
                        style: const TextStyle(
                            fontSize: 10, color: AppTheme.textMuted)),
                    Text(spec['value'] as String,
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> review) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(review['clientName'],
                      style:
                          const TextStyle(fontWeight: FontWeight.bold)),
                ),
                Row(
                  children: List.generate(
                    5,
                    (i) => Icon(
                      i < review['rating']
                          ? Icons.star
                          : Icons.star_border,
                      color: Colors.amber,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
            if (review['comment'] != null) ...[
              const SizedBox(height: 4),
              Text(review['comment'],
                  style: const TextStyle(color: AppTheme.textMuted)),
            ],
          ],
        ),
      ),
    );
  }
}