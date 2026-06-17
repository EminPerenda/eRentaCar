import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../config/app_theme.dart';
import '../../config/api_config.dart';
import '../../services/api_service.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiService _api = ApiService();

  DateTime _from = DateTime.now().subtract(const Duration(days: 30));
  DateTime _to = DateTime.now();

  Map<String, dynamic>? _financialData;
  Map<String, dynamic>? _vehicleData;
  Map<String, dynamic>? _clientData;
  Map<String, dynamic>? _locationData;

  bool _loadingFinancial = false;
  bool _loadingVehicle = false;
  bool _loadingClient = false;
  bool _loadingLocation = false;
  bool _generatingPdf = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) _loadCurrentTab();
    });
    _loadCurrentTab();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadCurrentTab() {
    switch (_tabController.index) {
      case 0: _loadFinancial(); break;
      case 1: _loadVehicle(); break;
      case 2: _loadClient(); break;
      case 3: _loadLocation(); break;
    }
  }

  String get _fromQ => _from.toIso8601String();
  String get _toQ => _to.toIso8601String();

  Future<void> _loadFinancial() async {
    setState(() => _loadingFinancial = true);
    try {
      final data = await _api.get('${ApiConfig.reports}/financial',
          params: {'from': _fromQ, 'to': _toQ});
      setState(() { _financialData = Map<String, dynamic>.from(data); _loadingFinancial = false; });
    } catch (_) { setState(() => _loadingFinancial = false); }
  }

  Future<void> _loadVehicle() async {
    setState(() => _loadingVehicle = true);
    try {
      final data = await _api.get('${ApiConfig.reports}/vehicles',
          params: {'from': _fromQ, 'to': _toQ});
      setState(() { _vehicleData = Map<String, dynamic>.from(data); _loadingVehicle = false; });
    } catch (_) { setState(() => _loadingVehicle = false); }
  }

  Future<void> _loadClient() async {
    setState(() => _loadingClient = true);
    try {
      final data = await _api.get('${ApiConfig.reports}/clients',
          params: {'from': _fromQ, 'to': _toQ});
      setState(() { _clientData = Map<String, dynamic>.from(data); _loadingClient = false; });
    } catch (_) { setState(() => _loadingClient = false); }
  }

  Future<void> _loadLocation() async {
    setState(() => _loadingLocation = true);
    try {
      final data = await _api.get('${ApiConfig.reports}/locations',
          params: {'from': _fromQ, 'to': _toQ});
      setState(() { _locationData = Map<String, dynamic>.from(data); _loadingLocation = false; });
    } catch (_) { setState(() => _loadingLocation = false); }
  }

  Future<void> _pickDate(bool isFrom) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isFrom ? _from : _to,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() { if (isFrom) _from = picked; else _to = picked; });
      _loadCurrentTab();
    }
  }

  Future<pw.Font> _font() => PdfGoogleFonts.notoSansRegular();
  Future<pw.Font> _fontBold() => PdfGoogleFonts.notoSansBold();

  String _fmt(DateTime d) => '${d.day}.${d.month}.${d.year}';
  String _fmtStr(String s) => _fmt(DateTime.parse(s));

  Future<void> _exportPdf() async {
    setState(() => _generatingPdf = true);
    try {
      final font = await _font();
      final bold = await _fontBold();
      final base = pw.TextStyle(font: font, fontSize: 9);
      final bld = pw.TextStyle(font: bold, fontWeight: pw.FontWeight.bold);

      final pdf = pw.Document();
      final period = '${_fmt(_from)} — ${_fmt(_to)}';

      switch (_tabController.index) {
        case 0: await _buildFinancialPdf(pdf, base, bld, period); break;
        case 1: await _buildVehiclePdf(pdf, base, bld, period); break;
        case 2: await _buildClientPdf(pdf, base, bld, period); break;
        case 3: await _buildLocationPdf(pdf, base, bld, period); break;
      }

      await Printing.layoutPdf(onLayout: (_) async => pdf.save());
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.error));
    } finally {
      if (mounted) setState(() => _generatingPdf = false);
    }
  }

  Future<void> _buildFinancialPdf(
      pw.Document pdf, pw.TextStyle base, pw.TextStyle bld, String period) async {
    final d = _financialData;
    if (d == null) return;
    final txs = d['transactions'] as List;
    final byLoc = d['byLocation'] as List;

    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      build: (ctx) => [
        pw.Text('eRentaCar — Finansijski izvještaj', style: bld.copyWith(fontSize: 18)),
        pw.Divider(),
        pw.Text('Period: $period', style: base),
        pw.SizedBox(height: 12),
        pw.Row(children: [
          pw.Expanded(child: pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: const pw.BoxDecoration(color: PdfColors.grey100),
            child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Text('Ukupan prihod', style: base),
              pw.Text('${(d['totalRevenue'] as num).toStringAsFixed(2)} KM', style: bld.copyWith(fontSize: 16)),
            ]),
          )),
          pw.SizedBox(width: 12),
          pw.Expanded(child: pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: const pw.BoxDecoration(color: PdfColors.grey100),
            child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Text('Broj transakcija', style: base),
              pw.Text('${d['transactionCount']}', style: bld.copyWith(fontSize: 16)),
            ]),
          )),
        ]),
        pw.SizedBox(height: 16),
        if (byLoc.isNotEmpty) ...[
          pw.Text('Prihod po lokaciji', style: bld),
          pw.SizedBox(height: 6),
          pw.TableHelper.fromTextArray(
            headers: ['Lokacija', 'Br. rezervacija', 'Prihod (KM)'],
            data: byLoc.map((l) => [l['name'], '${l['count']}', '${(l['revenue'] as num).toStringAsFixed(2)}']).toList(),
            headerStyle: bld, headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
            cellStyle: base, cellAlignment: pw.Alignment.centerLeft,
          ),
          pw.SizedBox(height: 16),
        ],
        pw.Text('Pregled transakcija', style: bld),
        pw.SizedBox(height: 6),
        pw.TableHelper.fromTextArray(
          headers: ['Klijent', 'Vozilo', 'Lokacija preuzimanja', 'Period', 'Iznos (KM)'],
          data: txs.map((r) => [
            r['clientName'],
            r['vehicle'],
            r['pickupLocation'],
            '${_fmtStr(r['startDate'])} - ${_fmtStr(r['endDate'])}',
            '${(r['totalPrice'] as num).toStringAsFixed(2)}',
          ]).toList(),
          headerStyle: bld, headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
          cellStyle: base, cellAlignment: pw.Alignment.centerLeft,
        ),
      ],
    ));
  }

  Future<void> _buildVehiclePdf(
      pw.Document pdf, pw.TextStyle base, pw.TextStyle bld, String period) async {
    final d = _vehicleData;
    if (d == null) return;
    final byVehicle = d['byVehicle'] as List;
    final byCategory = d['byCategory'] as List;

    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      build: (ctx) => [
        pw.Text('eRentaCar — Iskorištenost vozila', style: bld.copyWith(fontSize: 18)),
        pw.Divider(),
        pw.Text('Period: $period (${d['periodDays']} dana)', style: base),
        pw.SizedBox(height: 16),
        pw.Text('Po kategoriji', style: bld),
        pw.SizedBox(height: 6),
        pw.TableHelper.fromTextArray(
          headers: ['Kategorija', 'Vozila', 'Rezervacija', 'Prih. (KM)', 'Proš. trajanje'],
          data: byCategory.map((c) => [
            c['name'], '${c['vehicleCount']}', '${c['reservationCount']}',
            '${(c['revenue'] as num).toStringAsFixed(2)}', '${c['avgDays']} dana',
          ]).toList(),
          headerStyle: bld, headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
          cellStyle: base, cellAlignment: pw.Alignment.centerLeft,
        ),
        pw.SizedBox(height: 16),
        pw.Text('Po vozilu', style: bld),
        pw.SizedBox(height: 6),
        pw.TableHelper.fromTextArray(
          headers: ['Vozilo', 'Registracija', 'Kategorija', 'Dana', 'Iskorištenost', 'Prihod (KM)'],
          data: byVehicle.map((v) => [
            v['vehicle'], v['licensePlate'], v['category'],
            '${v['daysRented']}', '${v['utilizationPct']}%',
            '${(v['revenue'] as num).toStringAsFixed(2)}',
          ]).toList(),
          headerStyle: bld, headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
          cellStyle: base, cellAlignment: pw.Alignment.centerLeft,
        ),
      ],
    ));
  }

  Future<void> _buildClientPdf(
      pw.Document pdf, pw.TextStyle base, pw.TextStyle bld, String period) async {
    final d = _clientData;
    if (d == null) return;
    final byClient = d['byClient'] as List;

    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      build: (ctx) => [
        pw.Text('eRentaCar — Aktivnost klijenata', style: bld.copyWith(fontSize: 18)),
        pw.Divider(),
        pw.Text('Period: $period', style: base),
        pw.SizedBox(height: 12),
        pw.Row(children: [
          pw.Expanded(child: pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: const pw.BoxDecoration(color: PdfColors.grey100),
            child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Text('Aktivnih klijenata', style: base),
              pw.Text('${d['totalClients']}', style: bld.copyWith(fontSize: 16)),
            ]),
          )),
          pw.SizedBox(width: 12),
          pw.Expanded(child: pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: const pw.BoxDecoration(color: PdfColors.grey100),
            child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Text('Ukupan prihod', style: base),
              pw.Text('${(d['totalRevenue'] as num).toStringAsFixed(2)} KM', style: bld.copyWith(fontSize: 16)),
            ]),
          )),
        ]),
        pw.SizedBox(height: 16),
        pw.TableHelper.fromTextArray(
          headers: ['Klijent', 'E-mail', 'Rezervacija', 'Potrošeno (KM)', 'Top kategorija'],
          data: byClient.map((c) => [
            c['name'], c['email'], '${c['reservationCount']}',
            '${(c['totalSpent'] as num).toStringAsFixed(2)}', c['topCategory'],
          ]).toList(),
          headerStyle: bld, headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
          cellStyle: base, cellAlignment: pw.Alignment.centerLeft,
        ),
      ],
    ));
  }

  Future<void> _buildLocationPdf(
      pw.Document pdf, pw.TextStyle base, pw.TextStyle bld, String period) async {
    final d = _locationData;
    if (d == null) return;
    final byLocation = d['byLocation'] as List;

    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      build: (ctx) => [
        pw.Text('eRentaCar — Izvještaj po lokacijama', style: bld.copyWith(fontSize: 18)),
        pw.Divider(),
        pw.Text('Period: $period', style: base),
        pw.SizedBox(height: 16),
        pw.TableHelper.fromTextArray(
          headers: ['Lokacija', 'Grad', 'Preuzimanja', 'Povrati', 'Prihod (KM)', 'Top vozilo'],
          data: byLocation.map((l) => [
            l['name'], l['city'], '${l['pickupCount']}',
            '${l['dropoffCount']}', '${(l['revenue'] as num).toStringAsFixed(2)}', l['topVehicle'],
          ]).toList(),
          headerStyle: bld, headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
          cellStyle: base, cellAlignment: pw.Alignment.centerLeft,
        ),
      ],
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            child: Row(
              children: [
                const Text('Izvještaji',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
                const Spacer(),
                _buildDateRow(),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  icon: _generatingPdf
                      ? const SizedBox(width: 14, height: 14,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.picture_as_pdf_outlined, size: 16),
                  label: const Text('Preuzmi PDF'),
                  onPressed: _generatingPdf ? null : _exportPdf,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          TabBar(
            controller: _tabController,
            labelColor: AppTheme.accent,
            unselectedLabelColor: AppTheme.textMuted,
            indicatorColor: AppTheme.accent,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            tabs: const [
              Tab(icon: Icon(Icons.payments_outlined, size: 18), text: 'Finansijski'),
              Tab(icon: Icon(Icons.directions_car_outlined, size: 18), text: 'Iskorištenost vozila'),
              Tab(icon: Icon(Icons.people_outlined, size: 18), text: 'Aktivnost klijenata'),
              Tab(icon: Icon(Icons.location_on_outlined, size: 18), text: 'Lokacije'),
            ],
          ),
          const Divider(height: 1),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _FinancialTabBody(data: _financialData, loading: _loadingFinancial, onReload: _loadFinancial),
                _VehicleTabBody(data: _vehicleData, loading: _loadingVehicle, onReload: _loadVehicle),
                _ClientTabBody(data: _clientData, loading: _loadingClient, onReload: _loadClient),
                _LocationTabBody(data: _locationData, loading: _loadingLocation, onReload: _loadLocation),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateRow() {
    return Row(
      children: [
        const Text('Period:', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(width: 10),
        OutlinedButton.icon(
          icon: const Icon(Icons.calendar_today_outlined, size: 14),
          label: Text(_fmt(_from)),
          style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6)),
          onPressed: () => _pickDate(true),
        ),
        const Padding(padding: EdgeInsets.symmetric(horizontal: 6), child: Text('—')),
        OutlinedButton.icon(
          icon: const Icon(Icons.calendar_today_outlined, size: 14),
          label: Text(_fmt(_to)),
          style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6)),
          onPressed: () => _pickDate(false),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared helpers
// ─────────────────────────────────────────────────────────────────────────────

Widget _loadingOrEmpty(bool loading, VoidCallback onReload, String emptyMsg) {
  if (loading) return const Center(child: CircularProgressIndicator());
  return Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Text(emptyMsg, style: const TextStyle(color: AppTheme.textMuted)),
      const SizedBox(height: 12),
      OutlinedButton.icon(icon: const Icon(Icons.refresh), label: const Text('Pokušaj ponovo'), onPressed: onReload),
    ]),
  );
}

Widget _summaryCard(String value, String label, Color color, IconData icon) {
  return Card(
    elevation: 0,
    color: color.withValues(alpha: 0.06),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
      side: BorderSide(color: color.withValues(alpha: 0.2)),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(children: [
        Icon(icon, color: color, size: 26),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
        ]),
      ]),
    ),
  );
}

String _fmtDate(String s) {
  final d = DateTime.parse(s);
  return '${d.day}.${d.month}.${d.year}';
}

// ─────────────────────────────────────────────────────────────────────────────
// Financial tab
// ─────────────────────────────────────────────────────────────────────────────

class _FinancialTabBody extends StatelessWidget {
  final Map<String, dynamic>? data;
  final bool loading;
  final VoidCallback onReload;
  const _FinancialTabBody({required this.data, required this.loading, required this.onReload});

  @override
  Widget build(BuildContext context) {
    if (loading || data == null) {
      return _loadingOrEmpty(loading, onReload, 'Nema podataka za odabrani period.');
    }
    final txs = data!['transactions'] as List;
    final byLoc = data!['byLocation'] as List;
    final totalRevenue = (data!['totalRevenue'] as num).toDouble();
    final txCount = data!['transactionCount'] as int;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: _summaryCard('${totalRevenue.toStringAsFixed(2)} KM', 'Ukupan prihod', AppTheme.success, Icons.payments_outlined)),
          const SizedBox(width: 16),
          Expanded(child: _summaryCard('$txCount', 'Završenih rezervacija', AppTheme.accent, Icons.receipt_long_outlined)),
        ]),
        const SizedBox(height: 24),
        if (byLoc.isNotEmpty) ...[
          const Text('Prihod po lokaciji preuzimanja',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
          const SizedBox(height: 10),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(color: Colors.grey.withValues(alpha: 0.15))),
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(AppTheme.background),
              columns: const [
                DataColumn(label: Text('Lokacija')),
                DataColumn(label: Text('Rezervacija')),
                DataColumn(label: Text('Prihod')),
              ],
              rows: byLoc.map((l) => DataRow(cells: [
                DataCell(Text(l['name'] ?? '-')),
                DataCell(Text('${l['count']}')),
                DataCell(Text('${(l['revenue'] as num).toStringAsFixed(2)} KM',
                    style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.accent))),
              ])).toList(),
            ),
          ),
          const SizedBox(height: 24),
        ],
        const Text('Pregled transakcija',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
        const SizedBox(height: 10),
        if (txs.isEmpty)
          const Text('Nema transakcija.', style: TextStyle(color: AppTheme.textMuted))
        else
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(color: Colors.grey.withValues(alpha: 0.15))),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(AppTheme.background),
                dataRowMinHeight: 38, dataRowMaxHeight: 48,
                columns: const [
                  DataColumn(label: Text('Klijent')),
                  DataColumn(label: Text('Vozilo')),
                  DataColumn(label: Text('Lokacija')),
                  DataColumn(label: Text('Period')),
                  DataColumn(label: Text('Osnova')),
                  DataColumn(label: Text('Dodaci')),
                  DataColumn(label: Text('Ukupno')),
                ],
                rows: txs.map((r) => DataRow(cells: [
                  DataCell(Text(r['clientName'] ?? '-', style: const TextStyle(fontWeight: FontWeight.w500))),
                  DataCell(Text(r['vehicle'] ?? '-')),
                  DataCell(Text(r['pickupLocation'] ?? '-')),
                  DataCell(Text('${_fmtDate(r['startDate'])} — ${_fmtDate(r['endDate'])}')),
                  DataCell(Text('${(r['basePrice'] as num).toStringAsFixed(2)} KM')),
                  DataCell(Text('${(r['extrasPrice'] as num).toStringAsFixed(2)} KM',
                      style: const TextStyle(color: AppTheme.textMuted))),
                  DataCell(Text('${(r['totalPrice'] as num).toStringAsFixed(2)} KM',
                      style: const TextStyle(fontWeight: FontWeight.w700, color: AppTheme.accent))),
                ])).toList(),
              ),
            ),
          ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Vehicle utilization tab
// ─────────────────────────────────────────────────────────────────────────────

class _VehicleTabBody extends StatelessWidget {
  final Map<String, dynamic>? data;
  final bool loading;
  final VoidCallback onReload;
  const _VehicleTabBody({required this.data, required this.loading, required this.onReload});

  @override
  Widget build(BuildContext context) {
    if (loading || data == null) {
      return _loadingOrEmpty(loading, onReload, 'Nema podataka za odabrani period.');
    }
    final byVehicle = data!['byVehicle'] as List;
    final byCategory = data!['byCategory'] as List;
    final periodDays = data!['periodDays'] as int;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _summaryCard('$periodDays dana', 'Trajanje perioda', AppTheme.accent, Icons.date_range_outlined),
        const SizedBox(height: 24),
        const Text('Po kategoriji',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
        const SizedBox(height: 10),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(color: Colors.grey.withValues(alpha: 0.15))),
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(AppTheme.background),
            columns: const [
              DataColumn(label: Text('Kategorija')),
              DataColumn(label: Text('Vozila')),
              DataColumn(label: Text('Rezervacija')),
              DataColumn(label: Text('Prosj. trajanje')),
              DataColumn(label: Text('Prihod')),
            ],
            rows: byCategory.map((c) => DataRow(cells: [
              DataCell(Text(c['name'] ?? '-', style: const TextStyle(fontWeight: FontWeight.w600))),
              DataCell(Text('${c['vehicleCount']}')),
              DataCell(Text('${c['reservationCount']}')),
              DataCell(Text('${c['avgDays']} dana')),
              DataCell(Text('${(c['revenue'] as num).toStringAsFixed(2)} KM',
                  style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.accent))),
            ])).toList(),
          ),
        ),
        const SizedBox(height: 24),
        const Text('Po vozilu',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
        const SizedBox(height: 10),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(color: Colors.grey.withValues(alpha: 0.15))),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(AppTheme.background),
              dataRowMinHeight: 38, dataRowMaxHeight: 48,
              columns: const [
                DataColumn(label: Text('Vozilo')),
                DataColumn(label: Text('Registracija')),
                DataColumn(label: Text('Kategorija')),
                DataColumn(label: Text('Dana u najmu')),
                DataColumn(label: Text('Iskorištenost')),
                DataColumn(label: Text('Rezervacija')),
                DataColumn(label: Text('Prihod')),
              ],
              rows: byVehicle.map((v) {
                final pct = (v['utilizationPct'] as num).toDouble();
                final pctColor = pct >= 60 ? AppTheme.success : pct >= 30 ? Colors.orange : AppTheme.error;
                return DataRow(cells: [
                  DataCell(Text(v['vehicle'] ?? '-', style: const TextStyle(fontWeight: FontWeight.w500))),
                  DataCell(Text(v['licensePlate'] ?? '-')),
                  DataCell(Text(v['category'] ?? '-')),
                  DataCell(Text('${v['daysRented']}')),
                  DataCell(Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: pctColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text('$pct%', style: TextStyle(color: pctColor, fontWeight: FontWeight.w600, fontSize: 12)),
                  )),
                  DataCell(Text('${v['reservationCount']}')),
                  DataCell(Text('${(v['revenue'] as num).toStringAsFixed(2)} KM',
                      style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.accent))),
                ]);
              }).toList(),
            ),
          ),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Client activity tab
// ─────────────────────────────────────────────────────────────────────────────

class _ClientTabBody extends StatelessWidget {
  final Map<String, dynamic>? data;
  final bool loading;
  final VoidCallback onReload;
  const _ClientTabBody({required this.data, required this.loading, required this.onReload});

  @override
  Widget build(BuildContext context) {
    if (loading || data == null) {
      return _loadingOrEmpty(loading, onReload, 'Nema podataka za odabrani period.');
    }
    final byClient = data!['byClient'] as List;
    final totalClients = data!['totalClients'] as int;
    final totalRevenue = (data!['totalRevenue'] as num).toDouble();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: _summaryCard('$totalClients', 'Aktivnih klijenata', Colors.orange, Icons.people_outlined)),
          const SizedBox(width: 16),
          Expanded(child: _summaryCard('${totalRevenue.toStringAsFixed(2)} KM', 'Ukupna potrošnja', AppTheme.success, Icons.payments_outlined)),
        ]),
        const SizedBox(height: 24),
        const Text('Aktivnost po klijentu',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
        const SizedBox(height: 10),
        if (byClient.isEmpty)
          const Text('Nema klijenata.', style: TextStyle(color: AppTheme.textMuted))
        else
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(color: Colors.grey.withValues(alpha: 0.15))),
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(AppTheme.background),
              dataRowMinHeight: 38, dataRowMaxHeight: 48,
              columns: const [
                DataColumn(label: Text('Klijent')),
                DataColumn(label: Text('E-mail')),
                DataColumn(label: Text('Rezervacija')),
                DataColumn(label: Text('Ukupno potrošeno')),
                DataColumn(label: Text('Top kategorija')),
              ],
              rows: byClient.map((c) => DataRow(cells: [
                DataCell(Text(c['name'] ?? '-', style: const TextStyle(fontWeight: FontWeight.w600))),
                DataCell(Text(c['email'] ?? '-', style: const TextStyle(fontSize: 12))),
                DataCell(Text('${c['reservationCount']}')),
                DataCell(Text('${(c['totalSpent'] as num).toStringAsFixed(2)} KM',
                    style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.accent))),
                DataCell(Text(c['topCategory'] ?? '-')),
              ])).toList(),
            ),
          ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Location tab
// ─────────────────────────────────────────────────────────────────────────────

class _LocationTabBody extends StatelessWidget {
  final Map<String, dynamic>? data;
  final bool loading;
  final VoidCallback onReload;
  const _LocationTabBody({required this.data, required this.loading, required this.onReload});

  @override
  Widget build(BuildContext context) {
    if (loading || data == null) {
      return _loadingOrEmpty(loading, onReload, 'Nema podataka za odabrani period.');
    }
    final byLocation = data!['byLocation'] as List;
    final totalRes = data!['totalReservations'] as int;
    final totalRevenue = (data!['totalRevenue'] as num).toDouble();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: _summaryCard('$totalRes', 'Ukupno rezervacija', Colors.purple, Icons.receipt_long_outlined)),
          const SizedBox(width: 16),
          Expanded(child: _summaryCard('${totalRevenue.toStringAsFixed(2)} KM', 'Ukupan prihod', AppTheme.success, Icons.payments_outlined)),
        ]),
        const SizedBox(height: 24),
        const Text('Promet po poslovnici',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
        const SizedBox(height: 10),
        if (byLocation.isEmpty)
          const Text('Nema podataka.', style: TextStyle(color: AppTheme.textMuted))
        else
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(color: Colors.grey.withValues(alpha: 0.15))),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(AppTheme.background),
                dataRowMinHeight: 38, dataRowMaxHeight: 48,
                columns: const [
                  DataColumn(label: Text('Lokacija')),
                  DataColumn(label: Text('Grad')),
                  DataColumn(label: Text('Preuzimanja')),
                  DataColumn(label: Text('Povrati')),
                  DataColumn(label: Text('Prihod')),
                  DataColumn(label: Text('Top vozilo')),
                ],
                rows: byLocation.map((l) => DataRow(cells: [
                  DataCell(Text(l['name'] ?? '-', style: const TextStyle(fontWeight: FontWeight.w600))),
                  DataCell(Text(l['city'] ?? '-')),
                  DataCell(Text('${l['pickupCount']}')),
                  DataCell(Text('${l['dropoffCount']}')),
                  DataCell(Text('${(l['revenue'] as num).toStringAsFixed(2)} KM',
                      style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.accent))),
                  DataCell(Text(l['topVehicle'] ?? '-', style: const TextStyle(fontSize: 12))),
                ])).toList(),
              ),
            ),
          ),
      ]),
    );
  }
}
