import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../config/api_config.dart';
import '../../services/api_service.dart';

class CreateReservationScreen extends StatefulWidget {
  final Map<String, dynamic> vehicle;
  final DateTime startDate;
  final DateTime endDate;

  const CreateReservationScreen({
    super.key,
    required this.vehicle,
    required this.startDate,
    required this.endDate,
  });

  @override
  State<CreateReservationScreen> createState() =>
      _CreateReservationScreenState();
}

class _CreateReservationScreenState extends State<CreateReservationScreen> {
  final ApiService _api = ApiService();
  List<dynamic> _locations = [];
  List<dynamic> _extraServices = [];
  int? _pickupLocationId;
  int? _dropoffLocationId;
  Map<int, int> _selectedExtras = {};
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _error;

  int get _totalDays =>
      widget.endDate.difference(widget.startDate).inDays;

  double get _basePrice =>
      (widget.vehicle['pricePerDay'] as num).toDouble() * _totalDays;

  double get _extrasPrice {
    double total = 0;
    for (final entry in _selectedExtras.entries) {
      final service = _extraServices.firstWhere(
        (s) => s['id'] == entry.key,
        orElse: () => null,
      );
      if (service != null) {
        total += (service['pricePerDay'] as num).toDouble() *
            _totalDays *
            entry.value;
      }
    }
    return total;
  }

  double get _totalPrice => _basePrice + _extrasPrice;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        _api.get('/api/locations'),
        _api.get(ApiConfig.extraServices),
      ]);
      setState(() {
        _locations = results[0];
        _extraServices = results[1];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _submitReservation() async {
    if (_pickupLocationId == null || _dropoffLocationId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Odaberite lokacije preuzimanja i povrata.'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final extras = _selectedExtras.entries
          .map((e) => {'extraServiceId': e.key, 'quantity': e.value})
          .toList();

      await _api.post(ApiConfig.reservations, {
        'vehicleId': widget.vehicle['id'],
        'pickupLocationId': _pickupLocationId,
        'dropoffLocationId': _dropoffLocationId,
        'startDate': widget.startDate.toIso8601String(),
        'endDate': widget.endDate.toIso8601String(),
        'extras': extras,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Rezervacija uspješno kreirana!'),
            backgroundColor: AppTheme.success,
          ),
        );
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kreiranje rezervacije'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildVehicleInfo(),
                      const SizedBox(height: 20),
                      _buildPeriodInfo(),
                      const SizedBox(height: 20),
                      _buildLocationPicker(),
                      const SizedBox(height: 20),
                      _buildExtraServices(),
                      const SizedBox(height: 20),
                      _buildPriceSummary(),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: _isSubmitting ? null : _submitReservation,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: _isSubmitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2),
                  )
                : Text(
                    'Rezerviši za ${_totalPrice.toStringAsFixed(2)} KM',
                    style: const TextStyle(fontSize: 16),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildVehicleInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.directions_car, size: 40, color: AppTheme.accent),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${widget.vehicle['brand']} ${widget.vehicle['model']}',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${widget.vehicle['pricePerDay']} KM/dan',
                    style: const TextStyle(color: AppTheme.accent),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Period iznajmljivanja',
                style:
                    TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildInfoTile(
                    Icons.calendar_today,
                    'Preuzimanje',
                    '${widget.startDate.day}.${widget.startDate.month}.${widget.startDate.year}',
                  ),
                ),
                const Icon(Icons.arrow_forward, color: AppTheme.textMuted),
                Expanded(
                  child: _buildInfoTile(
                    Icons.calendar_today,
                    'Povrat',
                    '${widget.endDate.day}.${widget.endDate.month}.${widget.endDate.year}',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                '$_totalDays dana',
                style: const TextStyle(
                    color: AppTheme.accent, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.accent, size: 20),
        const SizedBox(height: 4),
        Text(label,
            style:
                const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildLocationPicker() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Lokacije',
                style:
                    TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              value: _pickupLocationId,
              decoration: const InputDecoration(
                labelText: 'Lokacija preuzimanja',
                prefixIcon: Icon(Icons.location_on_outlined),
              ),
              items: _locations
                  .map((l) => DropdownMenuItem<int>(
                        value: l['id'] as int,
                        child: Text(l['name']),
                      ))
                  .toList(),
              onChanged: (val) =>
                  setState(() => _pickupLocationId = val),
              validator: (v) =>
                  v == null ? 'Odaberite lokaciju preuzimanja.' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              value: _dropoffLocationId,
              decoration: const InputDecoration(
                labelText: 'Lokacija povrata',
                prefixIcon: Icon(Icons.location_on_outlined),
              ),
              items: _locations
                  .map((l) => DropdownMenuItem<int>(
                        value: l['id'] as int,
                        child: Text(l['name']),
                      ))
                  .toList(),
              onChanged: (val) =>
                  setState(() => _dropoffLocationId = val),
              validator: (v) =>
                  v == null ? 'Odaberite lokaciju povrata.' : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExtraServices() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Dodatna oprema',
                style:
                    TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ..._extraServices.map((service) {
              final id = service['id'] as int;
              final isSelected = _selectedExtras.containsKey(id);
              return CheckboxListTile(
                title: Text(service['name']),
                subtitle: Text(
                  '+${service['pricePerDay']} KM/dan',
                  style: const TextStyle(color: AppTheme.accent),
                ),
                value: isSelected,
                activeColor: AppTheme.accent,
                onChanged: (val) {
                  setState(() {
                    if (val == true) {
                      _selectedExtras[id] = 1;
                    } else {
                      _selectedExtras.remove(id);
                    }
                  });
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceSummary() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Pregled cijene',
                style:
                    TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildPriceRow(
              'Osnovna cijena ($_totalDays dana × ${widget.vehicle['pricePerDay']} KM)',
              _basePrice,
            ),
            if (_extrasPrice > 0)
              _buildPriceRow('Dodatna oprema', _extrasPrice),
            const Divider(),
            _buildPriceRow('Ukupno', _totalPrice, isTotal: true),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceRow(String label, double amount,
      {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontWeight:
                    isTotal ? FontWeight.bold : FontWeight.normal,
                fontSize: isTotal ? 16 : 14,
              ),
            ),
          ),
          Text(
            '${amount.toStringAsFixed(2)} KM',
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 16 : 14,
              color: isTotal ? AppTheme.accent : AppTheme.textDark,
            ),
          ),
        ],
      ),
    );
  }
}