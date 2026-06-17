import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../config/app_theme.dart';
import '../../config/api_config.dart';
import '../../services/api_service.dart';
import '../reservation/create_reservation_screen.dart';

class AvailabilityCalendarScreen extends StatefulWidget {
  final Map<String, dynamic> vehicle;
  const AvailabilityCalendarScreen({super.key, required this.vehicle});

  @override
  State<AvailabilityCalendarScreen> createState() =>
      _AvailabilityCalendarScreenState();
}

class _AvailabilityCalendarScreenState
    extends State<AvailabilityCalendarScreen> {
  final ApiService _api = ApiService();
  Set<DateTime> _occupiedDates = {};
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isLoading = true;
  DateTime _focusedDay = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadOccupiedDates();
  }

  Future<void> _loadOccupiedDates() async {
    try {
      final data = await _api.get('${ApiConfig.vehicles}/${widget.vehicle['id']}/occupied-dates');
      final ranges = data as List;

      final occupied = <DateTime>{};
      for (final r in ranges) {
        final start = DateTime.parse(r['startDate']);
        final end = DateTime.parse(r['endDate']);
        var current = DateTime(start.year, start.month, start.day);
        final last = DateTime(end.year, end.month, end.day);
        while (!current.isAfter(last)) {
          occupied.add(current);
          current = current.add(const Duration(days: 1));
        }
      }

      setState(() {
        _occupiedDates = occupied;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  bool _isOccupied(DateTime day) {
    final d = DateTime(day.year, day.month, day.day);
    return _occupiedDates.contains(d);
  }

  bool _isSelected(DateTime day) {
    if (_startDate == null) return false;
    final d = DateTime(day.year, day.month, day.day);
    final start =
        DateTime(_startDate!.year, _startDate!.month, _startDate!.day);
    if (_endDate == null) {
      return d == start;
    }
    final end = DateTime(_endDate!.year, _endDate!.month, _endDate!.day);
    return !d.isBefore(start) && !d.isAfter(end);
  }

  void _onDaySelected(DateTime day, DateTime focused) {
    if (_isOccupied(day) || day.isBefore(DateTime.now())) return;

    setState(() {
      _focusedDay = focused;
      if (_startDate == null || (_startDate != null && _endDate != null)) {
        _startDate = day;
        _endDate = null;
      } else {
        if (day.isBefore(_startDate!)) {
          _startDate = day;
          _endDate = null;
        } else {
          var current = _startDate!.add(const Duration(days: 1));
          bool hasOccupied = false;
          while (!current.isAfter(day)) {
            if (_isOccupied(current)) {
              hasOccupied = true;
              break;
            }
            current = current.add(const Duration(days: 1));
          }

          if (hasOccupied) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Odabrani period sadrži zauzete termine.'),
                backgroundColor: AppTheme.error,
              ),
            );
          } else {
            _endDate = day;
          }
        }
      }
    });
  }

  int get _totalDays {
    if (_startDate == null || _endDate == null) return 0;
    return _endDate!.difference(_startDate!).inDays;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dostupnost vozila'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    '${widget.vehicle['brand']} ${widget.vehicle['model']}',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                TableCalendar(
                  firstDay: DateTime.now(),
                  lastDay: DateTime.now().add(const Duration(days: 365)),
                  focusedDay: _focusedDay,
                  calendarFormat: CalendarFormat.month,
                  onDaySelected: _onDaySelected,
                  onPageChanged: (focusedDay) {
                    setState(() => _focusedDay = focusedDay);
                  },
                  calendarBuilders: CalendarBuilders(
                    defaultBuilder: (context, day, focusedDay) {
                      final isOcc = _isOccupied(day);
                      final isSel = _isSelected(day);
                      Color bg = Colors.transparent;
                      Color fg = AppTheme.textDark;

                      if (isOcc) {
                        bg = AppTheme.error.withOpacity(0.15);
                        fg = AppTheme.error;
                      } else if (isSel) {
                        bg = AppTheme.success.withOpacity(0.2);
                        fg = AppTheme.success;
                      }

                      return Container(
                        margin: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: bg,
                          borderRadius: BorderRadius.circular(8),
                          border: isSel && !isOcc
                              ? Border.all(color: AppTheme.success, width: 2)
                              : null,
                        ),
                        child: Center(
                          child: Text(
                            '${day.day}',
                            style: TextStyle(
                                color: fg, fontWeight: FontWeight.w500),
                          ),
                        ),
                      );
                    },
                    todayBuilder: (context, day, focusedDay) {
                      final isOcc = _isOccupied(day);
                      final isSel = _isSelected(day);
                      Color bg = Colors.transparent;
                      Color fg = AppTheme.accent;
                      Border? border = Border.all(color: AppTheme.accent, width: 2);

                      if (isOcc) {
                        bg = AppTheme.error.withOpacity(0.15);
                        fg = AppTheme.error;
                        border = Border.all(color: AppTheme.error, width: 2);
                      } else if (isSel) {
                        bg = AppTheme.success.withOpacity(0.2);
                        fg = AppTheme.success;
                        border = Border.all(color: AppTheme.success, width: 2);
                      }

                      return Container(
                        margin: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: bg,
                          borderRadius: BorderRadius.circular(8),
                          border: border,
                        ),
                        child: Center(
                          child: Text(
                            '${day.day}',
                            style: TextStyle(
                                color: fg, fontWeight: FontWeight.bold),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildLegend(AppTheme.success, 'Slobodno'),
                      const SizedBox(width: 24),
                      _buildLegend(AppTheme.error, 'Zauzeto'),
                    ],
                  ),
                ),
                if (_startDate != null && _endDate != null)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.background,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Odabrani period',
                          style: TextStyle(color: AppTheme.textMuted),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_startDate!.day}.${_startDate!.month}.${_startDate!.year} → ${_endDate!.day}.${_endDate!.month}.${_endDate!.year} ($_totalDays dana)',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
      bottomNavigationBar: _startDate != null && _endDate != null
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CreateReservationScreen(
                        vehicle: widget.vehicle,
                        startDate: _startDate!,
                        endDate: _endDate!,
                      ),
                    ),
                  ),
                  child: const Text('Nastavi na rezervaciju',
                      style: TextStyle(fontSize: 16)),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildLegend(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            border: Border.all(color: color),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(label),
      ],
    );
  }
}   