import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../vehicles/vehicles_screen.dart';
import '../reservations/reservations_screen.dart';
import '../clients/clients_screen.dart';
import '../locations/locations_screen.dart';
import '../reports/reports_screen.dart';
import '../news/news_screen.dart';
import '../../services/api_service.dart';
import '../../config/api_config.dart';
import '../reference/reference_screen.dart';
import '../extra_services/extra_services_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  final List<_NavItem> _navItems = [
    _NavItem(Icons.dashboard_outlined, Icons.dashboard, 'Dashboard'),
    _NavItem(Icons.directions_car_outlined, Icons.directions_car, 'Vozila'),
    _NavItem(Icons.calendar_today_outlined, Icons.calendar_today, 'Rezervacije'),
    _NavItem(Icons.people_outlined, Icons.people, 'Klijenti'),
    _NavItem(Icons.location_on_outlined, Icons.location_on, 'Lokacije'),
    _NavItem(Icons.miscellaneous_services_outlined, Icons.miscellaneous_services, 'Dod. usluge'),
    _NavItem(Icons.bar_chart_outlined, Icons.bar_chart, 'Izvještaji'),
    _NavItem(Icons.newspaper_outlined, Icons.newspaper, 'Vijesti'),
    _NavItem(Icons.settings_outlined, Icons.settings, 'Ref. podaci'),
  ];

  final List<Widget> _screens = [
    const _DashboardHome(),
    const VehiclesScreen(),
    const ReservationsScreen(),
    const ClientsScreen(),
    const LocationsScreen(),
    const ExtraServicesScreen(),
    const ReportsScreen(),
    const NewsScreen(),
    const ReferenceScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          _buildSidebar(),
          Expanded(child: _screens[_selectedIndex]),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 220,
      color: AppTheme.primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Icon(Icons.directions_car, color: Colors.white, size: 28),
                SizedBox(width: 10),
                Text(
                  'eRentaCar',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Admin Panel',
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ),
          const SizedBox(height: 32),
          Expanded(
            child: ListView.builder(
              itemCount: _navItems.length,
              itemBuilder: (context, index) {
                final item = _navItems[index];
                final isSelected = _selectedIndex == index;
                return InkWell(
                  onTap: () => setState(() => _selectedIndex = index),
                  child: Container(
                    margin: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 2),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.white.withValues(alpha: 0.15)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isSelected ? item.activeIcon : item.icon,
                          color: isSelected
                              ? Colors.white
                              : Colors.white60,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          item.label,
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : Colors.white60,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const Divider(color: Colors.white24),
          Padding(
            padding: const EdgeInsets.all(16),
            child: InkWell(
              onTap: () async {
                await context.read<AuthProvider>().logout();
              },
              child: const Row(
                children: [
                  Icon(Icons.logout, color: Colors.white60, size: 20),
                  SizedBox(width: 12),
                  Text('Odjava',
                      style: TextStyle(color: Colors.white60)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavItem(this.icon, this.activeIcon, this.label);
}
class _DashboardHome extends StatefulWidget {
  const _DashboardHome();

  @override
  State<_DashboardHome> createState() => _DashboardHomeState();
}

class _DashboardHomeState extends State<_DashboardHome> {
  final ApiService _api = ApiService();
  Map<String, dynamic>? _stats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final results = await Future.wait([
        _api.get(ApiConfig.vehicles, params: {'pageSize': 100}),
        _api.get(ApiConfig.reservations, params: {'pageSize': 100}),
      ]);

      final vehicles = results[0]['items'] as List;
      final reservations = results[1]['items'] as List;

      final available = vehicles.where((v) => v['status'] == 'Available').length;
      final rented = vehicles.where((v) => v['status'] == 'Rented').length;
      final inService = vehicles.where((v) => v['status'] == 'InService').length;

      final active = reservations.where((r) =>
          r['status'] == 'Pending' || r['status'] == 'Confirmed' || r['status'] == 'Active').length;

      final revenue = reservations
          .where((r) => r['status'] == 'Completed')
          .fold<double>(0, (sum, r) => sum + (r['totalPrice'] as num).toDouble());

      setState(() {
        _stats = {
          'totalVehicles': vehicles.length,
          'available': available,
          'rented': rented,
          'inService': inService,
          'activeReservations': active,
          'totalReservations': reservations.length,
          'revenue': revenue,
          'recentReservations': reservations.take(5).toList(),
        };
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_stats == null) {
      return const Center(child: Text('Greška pri učitavanju podataka.'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Dashboard',
              style: TextStyle(
                  fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
          const SizedBox(height: 24),
          _buildMetricCards(),
          const SizedBox(height: 24),
          _buildVehicleStatus(),
          const SizedBox(height: 24),
          _buildRecentReservations(),
        ],
      ),
    );
  }

  Widget _buildMetricCards() {
    final metrics = [
      {
        'label': 'Vozila u voznom parku',
        'value': '${_stats!['totalVehicles']}',
        'icon': Icons.directions_car,
        'color': AppTheme.accent,
      },
      {
        'label': 'Aktivne rezervacije',
        'value': '${_stats!['activeReservations']}',
        'icon': Icons.calendar_today,
        'color': Colors.orange,
      },
      {
        'label': 'Vozila na servisu',
        'value': '${_stats!['inService']}',
        'icon': Icons.build_outlined,
        'color': Colors.red,
      },
      {
        'label': 'Ukupan prihod',
        'value': '${(_stats!['revenue'] as double).toStringAsFixed(0)} KM',
        'icon': Icons.payments_outlined,
        'color': AppTheme.success,
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 2,
      ),
      itemCount: metrics.length,
      itemBuilder: (context, index) {
        final m = metrics[index];
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: (m['color'] as Color).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(m['icon'] as IconData,
                      color: m['color'] as Color, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(m['value'] as String,
                          style: const TextStyle(
                              fontSize: 22, fontWeight: FontWeight.bold)),
                      Text(m['label'] as String,
                          style: const TextStyle(
                              color: AppTheme.textMuted, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildVehicleStatus() {
    final statuses = [
      {'label': 'Dostupna', 'value': _stats!['available'], 'color': AppTheme.success},
      {'label': 'Iznajmljena', 'value': _stats!['rented'], 'color': AppTheme.accent},
      {'label': 'Na servisu', 'value': _stats!['inService'], 'color': Colors.orange},
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Status voznog parka',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              children: statuses.map((s) {
                return Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: (s['color'] as Color).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: (s['color'] as Color).withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '${s['value']}',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: s['color'] as Color,
                          ),
                        ),
                        Text(s['label'] as String,
                            style: const TextStyle(color: AppTheme.textMuted)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentReservations() {
    final reservations = _stats!['recentReservations'] as List;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Nedavne rezervacije',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            if (reservations.isEmpty)
              const Text('Nema rezervacija.',
                  style: TextStyle(color: AppTheme.textMuted))
            else
              Table(
                columnWidths: const {
                  0: FlexColumnWidth(2),
                  1: FlexColumnWidth(2),
                  2: FlexColumnWidth(2),
                  3: FlexColumnWidth(1.5),
                  4: FlexColumnWidth(1),
                },
                children: [
                  TableRow(
                    decoration: BoxDecoration(
                      border: Border(
                          bottom: BorderSide(color: Colors.grey.shade200))),
                    children: ['Klijent', 'Vozilo', 'Period', 'Cijena', 'Status']
                        .map((h) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text(h,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.textMuted,
                                      fontSize: 12)),
                            ))
                        .toList(),
                  ),
                  ...reservations.map((r) {
                    final status = r['status'] as String;
                    return TableRow(
                      children: [
                        _tableCell(r['clientName']),
                        _tableCell(r['vehicle']),
                        _tableCell(
                            '${_formatDate(r['startDate'])} - ${_formatDate(r['endDate'])}'),
                        _tableCell('${r['totalPrice']} KM'),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: _statusColor(status).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              _statusLabel(status),
                              style: TextStyle(
                                  color: _statusColor(status),
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _tableCell(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text(text,
          style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis),
    );
  }

  String _formatDate(String dateStr) {
    final date = DateTime.parse(dateStr);
    return '${date.day}.${date.month}.${date.year}';
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Pending': return Colors.orange;
      case 'Confirmed': return AppTheme.accent;
      case 'Active': return AppTheme.success;
      case 'Completed': return Colors.grey;
      case 'Cancelled': return AppTheme.error;
      default: return Colors.grey;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'Pending': return 'Na čekanju';
      case 'Confirmed': return 'Potvrđena';
      case 'Active': return 'Aktivna';
      case 'Completed': return 'Završena';
      case 'Cancelled': return 'Otkazana';
      default: return status;
    }
  }
}