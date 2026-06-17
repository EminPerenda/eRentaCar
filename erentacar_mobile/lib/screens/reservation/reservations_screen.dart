import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../config/api_config.dart';
import '../../services/api_service.dart';
import '../../services/payment_service.dart';

class ReservationsScreen extends StatefulWidget {
  const ReservationsScreen({super.key});

  @override
  State<ReservationsScreen> createState() => _ReservationsScreenState();
}

class _ReservationsScreenState extends State<ReservationsScreen>
    with SingleTickerProviderStateMixin {
  final ApiService _api = ApiService();
  late TabController _tabController;
  List<dynamic> _active = [];
  List<dynamic> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadReservations();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadReservations() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _api.get(ApiConfig.myReservations, params: {
          'status': 'Pending',
          'pageSize': 50,
        }),
        _api.get(ApiConfig.myReservations, params: {
          'pageSize': 50,
        }),
      ]);

      final all = results[1]['items'] as List;
      setState(() {
        _active = all
            .where((r) =>
                r['status'] == 'Pending' ||
                r['status'] == 'Confirmed' ||
                r['status'] == 'Active')
            .toList();
        _history = all
            .where((r) =>
                r['status'] == 'Completed' ||
                r['status'] == 'Cancelled')
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _payReservation(Map<String, dynamic> reservation) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Potvrda plaćanja'),
        content: Text(
          'Iznos za plaćanje: ${reservation['totalPrice']} KM\n\nJeste li sigurni da želite nastaviti s plaćanjem?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Odustani')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accent),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Plati'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      final paymentService = PaymentService();
      final success = await paymentService.payForReservation(
        reservationId: reservation['id'],
        amount: (reservation['totalPrice'] as num).toDouble(),
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Plaćanje je uspješno završeno!'),
            backgroundColor: AppTheme.success,
          ),
        );
        _loadReservations();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _cancelReservation(int id, String reason) async {
    try {
      await _api.patch(
        '${ApiConfig.reservations}/$id/cancel',
        data: {'reason': reason},
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Rezervacija je uspješno otkazana.'),
          backgroundColor: AppTheme.success,
        ),
      );
      _loadReservations();
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

  Future<void> _refundAndCancelReservation(
      Map<String, dynamic> reservation, String reason) async {
    setState(() => _isLoading = true);
    try {
      final paymentService = PaymentService();
      await paymentService.refundReservation(
        reservationId: reservation['id'],
      );

      await _api.patch(
        '${ApiConfig.reservations}/${reservation['id']}/cancel',
        data: {'reason': reason},
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Povrat novca je uspješno izvršen i rezervacija je otkazana.'),
          backgroundColor: AppTheme.success,
        ),
      );
      _loadReservations();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppTheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Moje rezervacije'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: [
            Tab(text: 'Aktivne (${_active.length})'),
            Tab(text: 'Historija (${_history.length})'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildReservationList(_active, isActive: true),
                _buildReservationList(_history, isActive: false),
              ],
            ),
    );
  }

  Widget _buildReservationList(List<dynamic> reservations,
      {required bool isActive}) {
    if (reservations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.calendar_today_outlined,
                size: 64, color: AppTheme.textMuted),
            const SizedBox(height: 16),
            Text(
              isActive
                  ? 'Nema aktivnih rezervacija.'
                  : 'Nema historije rezervacija.',
              style: const TextStyle(color: AppTheme.textMuted),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadReservations,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: reservations.length,
        itemBuilder: (context, index) => _buildReservationCard(
            reservations[index],
            isActive: isActive),
      ),
    );
  }

  Widget _buildReservationCard(Map<String, dynamic> reservation,
      {required bool isActive}) {
    final status = reservation['status'] as String;
    final color = _statusColor(status);
    final isPaid = _isPaidReservation(reservation);
    final canRefundCancel = isActive && status != 'Pending' && isPaid;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    reservation['vehicle'],
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _statusLabel(status),
                    style: TextStyle(
                        color: color, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.calendar_today_outlined,
                    size: 14, color: AppTheme.textMuted),
                const SizedBox(width: 6),
                Text(
                  '${_formatDate(reservation['startDate'])} → ${_formatDate(reservation['endDate'])}',
                  style: const TextStyle(color: AppTheme.textMuted),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.location_on_outlined,
                    size: 14, color: AppTheme.textMuted),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${reservation['pickupLocation']} → ${reservation['dropoffLocation']}',
                    style:
                        const TextStyle(color: AppTheme.textMuted),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${reservation['totalPrice']} KM',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.accent,
                  ),
                ),
                if (isActive && status == 'Pending')
                  TextButton.icon(
                    icon: const Icon(Icons.cancel_outlined,
                        color: AppTheme.error, size: 18),
                    label: Text(
                      canRefundCancel ? 'Povrat novca i otkaži' : 'Otkaži',
                      style: const TextStyle(color: AppTheme.error),
                    ),
                    onPressed: () => _showCancelDialog(
                      reservation,
                      refundBeforeCancel: canRefundCancel,
                    ),
                  ),
                if (!isActive && status == 'Completed')
                  TextButton.icon(
                    icon: const Icon(Icons.rate_review_outlined,
                        color: AppTheme.accent, size: 18),
                    label: const Text('Ostavi recenziju',
                        style: TextStyle(color: AppTheme.accent)),
                    onPressed: () => _showReviewDialog(reservation),
                  ),
              ],
            ),
            if (isActive && status == 'Pending') ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.payment, size: 18),
                  label: const Text('Plati online'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.success,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                  ),
                  onPressed: () => _payReservation(reservation),
                ),
              ),
            ],
            if (reservation['cancellationReason'] != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.error.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline,
                        size: 14, color: AppTheme.error),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Razlog: ${reservation['cancellationReason']}',
                        style: const TextStyle(
                            color: AppTheme.error, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showCancelDialog(Map<String, dynamic> reservation,
      {required bool refundBeforeCancel}) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          refundBeforeCancel
              ? 'Povrat novca i otkazivanje'
              : 'Otkazivanje rezervacije',
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Jeste li sigurni da želite otkazati rezervaciju?'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: Colors.orange.withValues(alpha: 0.3)),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Politika povrata novca:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '• Otkazivanje 48h+ prije preuzimanja: povrat 100%\n'
                      '• Otkazivanje 24-48h prije: povrat 50%\n'
                      '• Otkazivanje manje od 24h: bez povrata',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: 'Razlog otkazivanja',
                  hintText: 'Unesite razlog...',
                ),
                maxLines: 4,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Odustani'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.error),
            onPressed: () async {
              if (controller.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content:
                        Text('Razlog otkazivanja je obavezan.'),
                    backgroundColor: AppTheme.error,
                  ),
                );
                return;
              }
              Navigator.pop(ctx);
              if (refundBeforeCancel) {
                await _refundAndCancelReservation(
                    reservation, controller.text.trim());
              } else {
                await _cancelReservation(
                    reservation['id'], controller.text.trim());
              }
            },
            child: Text(refundBeforeCancel
                ? 'Povrati novac i otkaži'
                : 'Otkaži rezervaciju'),
          ),
        ],
      ),
    );
  }

  void _showReviewDialog(Map<String, dynamic> reservation) {
    final controller = TextEditingController();
    int rating = 5;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setState) {
        return AlertDialog(
          title: const Text('Ostavi recenziju'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Ocjena (1-5):'),
                const SizedBox(height: 8),
                Row(
                  children: List.generate(5, (i) {
                    final idx = i + 1;
                    return IconButton(
                      icon: Icon(
                        idx <= rating ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                      ),
                      onPressed: () => setState(() => rating = idx),
                    );
                  }),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: controller,
                  decoration: const InputDecoration(
                    labelText: 'Komentar (opcionalno)',
                    hintText: 'Napišite kratak komentar...',
                  ),
                  maxLines: 4,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Odustani'),
            ),
            ElevatedButton(
              onPressed: () async {
                final comment = controller.text.trim();
                Navigator.pop(ctx);
                try {
                  final vehicleId = reservation['vehicleId'] ??
                      (reservation['vehicle'] is Map
                          ? reservation['vehicle']['id']
                          : null);

                  final payload = {
                    'vehicleId': vehicleId,
                    'reservationId': reservation['id'],
                    'rating': rating,
                    'comment': comment.isEmpty ? null : comment,
                  };
                  await _api.post(ApiConfig.reviews, payload);
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Hvala na recenziji!'),
                      backgroundColor: AppTheme.success,
                    ),
                  );
                  _loadReservations();
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
              child: const Text('Pošalji'),
            ),
          ],
        );
      }),
    );
  }

  bool _isPaidReservation(Map<String, dynamic> reservation) {
    final paymentStatus = reservation['paymentStatus'];
    if (paymentStatus is String && paymentStatus.isNotEmpty) {
      final normalized = paymentStatus.toLowerCase();
      if (normalized == 'paid' ||
          normalized == 'succeeded' ||
          normalized == 'completed') {
        return true;
      }
    }

    final isPaid = reservation['isPaid'];
    if (isPaid is bool) {
      return isPaid;
    }

    return reservation['paymentIntentId'] != null;
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Pending':
        return Colors.orange;
      case 'Confirmed':
        return AppTheme.accent;
      case 'Active':
        return AppTheme.success;
      case 'Completed':
        return Colors.grey;
      case 'Cancelled':
        return AppTheme.error;
      default:
        return Colors.grey;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'Pending':
        return 'Na čekanju';
      case 'Confirmed':
        return 'Potvrđena';
      case 'Active':
        return 'Aktivna';
      case 'Completed':
        return 'Završena';
      case 'Cancelled':
        return 'Otkazana';
      default:
        return status;
    }
  }

  String _formatDate(String dateStr) {
    final date = DateTime.parse(dateStr);
    return '${date.day}.${date.month}.${date.year}';
  }
}