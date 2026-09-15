import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../utils/dynamic_color_helper.dart';
import 'dart:ui';

class HistoryScreen extends StatefulWidget {
  final String deviceId;
  const HistoryScreen({super.key, required this.deviceId});
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  // Tab 24h
  DateTime         _selectedDate = DateTime.now();
  List<dynamic>    _history24h   = [];
  bool             _loading24h   = true;
  String           _metric24h    = 'aqi';

  // Tab 7 ngày
  List<dynamic>    _hourly7d     = [];
  bool             _loading7d    = true;
  String           _metric7d     = 'aqi_avg';

  static const _metricOptions24h = [
    {'key': 'aqi',          'label': 'AQI'},
    {'key': 'pm25_ugm3',    'label': 'PM2.5'},
    {'key': 'co2_ppm',      'label': 'CO₂'},
    {'key': 'co_ppm',       'label': 'CO'},
    {'key': 'temperature_c','label': 'Nhiệt độ'},
    {'key': 'humidity_pct', 'label': 'Độ ẩm'},
  ];

  static const _metricOptions7d = [
    {'key': 'aqi_avg',   'label': 'AQI'},
    {'key': 'pm25_avg',  'label': 'PM2.5'},
    {'key': 'co2_avg',   'label': 'CO₂'},
    {'key': 'co_avg',    'label': 'CO'},
    {'key': 'temp_avg',  'label': 'Nhiệt độ'},
    {'key': 'hum_avg',   'label': 'Độ ẩm'},
  ];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _load24h();
    _load7d();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load24h() async {
    setState(() => _loading24h = true);
    final date = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final data = await ApiService().getHistory(widget.deviceId, date: date);
    if (mounted) setState(() { _history24h = data; _loading24h = false; });
  }

  Future<void> _load7d() async {
    setState(() => _loading7d = true);
    final data = await ApiService().getHourly(widget.deviceId, days: 7);
    if (mounted) setState(() { _hourly7d = data; _loading7d = false; });
  }

  List<FlSpot> _spots(List<dynamic> data, String key) {
    final spots = <FlSpot>[];
    for (int i = 0; i < data.length; i++) {
      final val = (data[i][key] as num?)?.toDouble();
      if (val != null) spots.add(FlSpot(i.toDouble(), val));
    }
    return spots;
  }

  Gradient _getAqiGradient(double maxY) {
    final boundaries = [50.0, 100.0, 150.0, 200.0, 300.0];
    final boundaryColors = [
      const Color(0xFF00E676), // Emerald Green
      const Color(0xFFFFD600), // Soft Yellow / Amber
      const Color(0xFFFF9100), // Vivid Orange
      const Color(0xFFFF1744), // Deep Red / Crimson
      const Color(0xFFD500F9), // Electric Purple
    ];

    final List<Color> colors = [const Color(0xFF00E676)];
    final List<double> stops = [0.0];

    for (int i = 0; i < boundaries.length; i++) {
      final y = boundaries[i];
      if (y < maxY) {
        colors.add(boundaryColors[i]);
        stops.add(y / maxY);
      }
    }

    colors.add(const Color(0xFF8D6E63));
    stops.add(1.0);

    return LinearGradient(
      colors: colors,
      stops: stops,
      begin: Alignment.bottomCenter,
      end: Alignment.topCenter,
    );
  }

  Gradient _getAqiFillGradient(double maxY) {
    final boundaries = [50.0, 100.0, 150.0, 200.0, 300.0];
    final boundaryColors = [
      const Color(0xFF00E676).withOpacity(0.25),
      const Color(0xFFFFD600).withOpacity(0.25),
      const Color(0xFFFF9100).withOpacity(0.25),
      const Color(0xFFFF1744).withOpacity(0.25),
      const Color(0xFFD500F9).withOpacity(0.25),
    ];

    final List<Color> colors = [const Color(0xFF00E676).withOpacity(0.02)];
    final List<double> stops = [0.0];

    for (int i = 0; i < boundaries.length; i++) {
      final y = boundaries[i];
      if (y < maxY) {
        colors.add(boundaryColors[i]);
        stops.add(y / maxY);
      }
    }

    colors.add(const Color(0xFF8D6E63).withOpacity(0.25));
    stops.add(1.0);

    return LinearGradient(
      colors: colors,
      stops: stops,
      begin: Alignment.bottomCenter,
      end: Alignment.topCenter,
    );
  }

  Widget _chart(List<FlSpot> spots, {required String xLabel, required bool isAqi}) {
    if (spots.isEmpty) {
      return const Center(child: Text('Không có dữ liệu cho khoảng thời gian này'));
    }
    final rawMaxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    final double maxY = (rawMaxY * 1.25).clamp(10.0, double.infinity);

    final lineGradient = isAqi
        ? _getAqiGradient(maxY)
        : const LinearGradient(
            colors: [Colors.teal, Colors.blue],
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
          );

    final fillGradient = isAqi
        ? _getAqiFillGradient(maxY)
        : LinearGradient(
            colors: [
              Colors.teal.withOpacity(0.02),
              Colors.blue.withOpacity(0.18),
            ],
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
          );

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: maxY,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey.shade200,
              strokeWidth: 1,
            );
          },
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: (spots.length / 5).clamp(1, double.infinity).toDouble(),
              getTitlesWidget: (v, _) => Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  v.toInt().toString(),
                  style: TextStyle(fontSize: 9, color: Colors.grey.shade600, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 34,
              getTitlesWidget: (v, _) => Text(
                v.toInt().toString(),
                style: TextStyle(fontSize: 9, color: Colors.grey.shade600, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:   const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            gradient: lineGradient,
            barWidth: 3.5,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: fillGradient,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown(
      List<Map<String, String>> options, String current, ValueChanged<String> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.teal.withOpacity(0.3), width: 1.5),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: current,
          isDense: true,
          icon: const Icon(Icons.arrow_drop_down, color: Colors.teal),
          onChanged: (v) => onChanged(v!),
          items: options.map((o) => DropdownMenuItem(
            value: o['key']!,
            child: Text(
              o['label']!,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF263238)),
            ),
          )).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mockAqiForBg = _tabs.index == 0
        ? (_history24h.isNotEmpty ? (_history24h.last['aqi'] as num?)?.toInt() ?? 20 : 20)
        : (_hourly7d.isNotEmpty ? (_hourly7d.last['aqi_avg'] as num?)?.toInt() ?? 20 : 20);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch sử chỉ số & Biểu đồ', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white.withOpacity(0.8),
        bottom: TabBar(
          controller: _tabs,
          labelColor: Colors.teal.shade900,
          unselectedLabelColor: Colors.grey.shade600,
          indicatorColor: Colors.teal,
          indicatorWeight: 3,
          tabs: const [Tab(text: '24 giờ'), Tab(text: '7 ngày')],
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: DynamicColorHelper.getBackgroundGradient(mockAqiForBg),
            stops: const [0.0, 0.6],
          ),
        ),
        child: TabBarView(
          controller: _tabs,
          children: [
            // ── Tab 24h ──────────────────────────────────────────────
            Column(children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    // Chọn ngày
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.85),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.teal.withOpacity(0.3), width: 1.5),
                      ),
                      child: TextButton.icon(
                        icon: const Icon(Icons.calendar_today, size: 16, color: Colors.teal),
                        label: Text(
                          DateFormat('dd/MM/yyyy').format(_selectedDate),
                          style: const TextStyle(color: Color(0xFF263238), fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _selectedDate,
                            firstDate: DateTime.now().subtract(const Duration(days: 3)),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) {
                            setState(() => _selectedDate = picked);
                            _load24h();
                          }
                        },
                      ),
                    ),
                    const Spacer(),
                    // Chọn chỉ số
                    _buildDropdown(
                      _metricOptions24h.map((m) => {'key': m['key']!, 'label': m['label']!}).toList(),
                      _metric24h,
                      (v) => setState(() => _metric24h = v),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _loading24h
                    ? const Center(child: CircularProgressIndicator())
                    : Container(
                        margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        padding: const EdgeInsets.all(16),
                        decoration: DynamicColorHelper.getGlassDecoration(aqi: mockAqiForBg),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: _chart(
                              _spots(_history24h, _metric24h),
                              xLabel: 'Số phút gần đây',
                              isAqi: _metric24h == 'aqi',
                            ),
                          ),
                        ),
                      ),
              ),
            ]),

            // ── Tab 7 ngày ───────────────────────────────────────────
            Column(children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _buildDropdown(
                      _metricOptions7d.map((m) => {'key': m['key']!, 'label': m['label']!}).toList(),
                      _metric7d,
                      (v) => setState(() => _metric7d = v),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _loading7d
                    ? const Center(child: CircularProgressIndicator())
                    : Container(
                        margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        padding: const EdgeInsets.all(16),
                        decoration: DynamicColorHelper.getGlassDecoration(aqi: mockAqiForBg),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: _chart(
                              _spots(_hourly7d, _metric7d),
                              xLabel: 'Số giờ gần đây',
                              isAqi: _metric7d == 'aqi_avg',
                            ),
                          ),
                        ),
                      ),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}
