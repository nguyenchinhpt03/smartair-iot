import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/api_service.dart';
import '../utils/dynamic_color_helper.dart';
import 'dart:ui';

class DetailScreen extends StatefulWidget {
  final String deviceId;
  const DetailScreen({super.key, required this.deviceId});
  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  Map<String, dynamic>? _current;
  List<dynamic>         _history = [];
  bool                  _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final api   = ApiService();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final results = await Future.wait([
      api.getRealtimeReading(widget.deviceId),
      api.getHistory(widget.deviceId, date: today),
    ]);
    if (mounted) {
      setState(() {
        _current = results[0] as Map<String, dynamic>?;
        _history = results[1] as List;
        _loading = false;
      });
    }
  }

  static const _metrics = [
    {'key': 'co2_ppm',       'label': 'Khí CO₂',         'unit': 'ppm',    'safe': 1000.0},
    {'key': 'nh3_ppm',       'label': 'Khí NH₃',         'unit': 'ppm',    'safe': 25.0},
    {'key': 'benzene_ppm',   'label': 'Khí Benzene',     'unit': 'ppm',    'safe': 1.7},
    {'key': 'co_ppm',        'label': 'Khí CO',          'unit': 'ppm',    'safe': 9.0},
    {'key': 'pm1_ugm3',      'label': 'Bụi mịn PM1.0',   'unit': 'µg/m³',  'safe': 15.0},
    {'key': 'pm25_ugm3',     'label': 'Bụi mịn PM2.5',   'unit': 'µg/m³',  'safe': 35.0},
    {'key': 'pm10_ugm3',     'label': 'Bụi PM10',        'unit': 'µg/m³',  'safe': 45.0},
    {'key': 'temperature_c', 'label': 'Nhiệt độ',       'unit': '°C',     'safe': 30.0},
    {'key': 'humidity_pct',  'label': 'Độ ẩm',          'unit': '%',      'safe': 70.0},
    {'key': 'pressure_hpa',  'label': 'Áp suất',        'unit': 'hPa',    'safe': 1030.0},
  ];

  Color _statusColor(double? value, double safe) {
    if (value == null) return Colors.grey;
    return value > safe ? const Color(0xFFFF1744) : const Color(0xFF00E676);
  }

  IconData _getIcon(String key) {
    switch (key) {
      case 'co2_ppm': return Icons.cloud_outlined;
      case 'nh3_ppm': return Icons.science_outlined;
      case 'benzene_ppm': return Icons.biotech_outlined;
      case 'co_ppm': return Icons.warning_amber_outlined;
      case 'pm1_ugm3': return Icons.blur_on;
      case 'pm25_ugm3': return Icons.grain;
      case 'pm10_ugm3': return Icons.texture;
      case 'temperature_c': return Icons.thermostat_outlined;
      case 'humidity_pct': return Icons.water_drop_outlined;
      case 'pressure_hpa': return Icons.compress_outlined;
      default: return Icons.sensors;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final aqi = (_current?['aqi'] as num?)?.toInt() ?? 25;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết chỉ số cảm biến', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white.withOpacity(0.85),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: DynamicColorHelper.getBackgroundGradient(aqi),
            stops: const [0.0, 0.65],
          ),
        ),
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            children: [
              // List of cards for metrics
              ..._metrics.map((m) {
                final raw   = _current?[m['key'] as String];
                final value = (raw as num?)?.toDouble();
                final safe  = m['safe'] as double;
                final color = _statusColor(value, safe);
                final isWarning = value != null && value > safe;
                
                final display = value != null
                    ? '${value.toStringAsFixed(m['unit'] == 'ppm' && value < 1 ? 3 : 1)}'
                    : '—';
                    
                final double ratio = value != null ? (value / safe).clamp(0.0, 1.0) : 0.0;
                final icon = _getIcon(m['key'] as String);

                final cardDecoration = isWarning
                    ? BoxDecoration(
                        color: Colors.red.shade50.withOpacity(0.75),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.red.shade400, width: 2.0),
                        boxShadow: [
                          BoxShadow(color: Colors.red.withOpacity(0.15), offset: const Offset(4, 4), blurRadius: 0),
                        ],
                      )
                    : DynamicColorHelper.getGlassDecoration(aqi: aqi);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    decoration: cardDecoration,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: value == null ? null : () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => _MetricChartScreen(
                                  title:     m['label'] as String,
                                  metricKey: m['key']   as String,
                                  unit:      m['unit']  as String,
                                  data:      _history,
                                  safeLevel: safe,
                                  aqi:       aqi,
                                ),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: color.withOpacity(0.12),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(icon, color: color, size: 22),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              m['label'] as String,
                                              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFF263238)),
                                            ),
                                            const SizedBox(height: 3),
                                            Text(
                                              'Ngưỡng an toàn: ${safe.toStringAsFixed(safe < 5 ? 1 : 0)} ${m['unit']}',
                                              style: TextStyle(fontSize: 11, color: Colors.grey.shade700, fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Row(
                                            crossAxisAlignment: CrossAxisAlignment.baseline,
                                            textBaseline: TextBaseline.alphabetic,
                                            children: [
                                              Text(
                                                display,
                                                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: color),
                                              ),
                                              const SizedBox(width: 2),
                                              Text(
                                                m['unit'] as String,
                                                style: TextStyle(fontSize: 10, color: Colors.grey.shade500, fontWeight: FontWeight.bold),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: color.withOpacity(0.15),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              value == null ? 'Ngoại tuyến' : (isWarning ? 'Vượt ngưỡng' : 'An toàn'),
                                              style: TextStyle(color: DynamicColorHelper.darken(color, 0.2), fontSize: 9, fontWeight: FontWeight.bold),
                                            ),
                                          )
                                        ],
                                      )
                                    ],
                                  ),
                                  if (value != null) ...[
                                    const SizedBox(height: 14),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: ratio,
                                        minHeight: 6,
                                        color: color,
                                        backgroundColor: Colors.white.withOpacity(0.5),
                                      ),
                                    )
                                  ]
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),

              // Nhận xét AI cuối ngày
              FutureBuilder(
                future: ApiService().getDailyReports(widget.deviceId),
                builder: (ctx, snap) {
                  final reports = snap.data ?? [];
                  if (reports.isEmpty) return const SizedBox.shrink();
                  final today = reports.first;
                  final summary = today['ai_summary'] as String?;
                  if (summary == null || summary.isEmpty) return const SizedBox.shrink();
                  return Container(
                    margin: const EdgeInsets.only(top: 8, bottom: 24),
                    decoration: DynamicColorHelper.getGlassDecoration(aqi: aqi),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.auto_awesome, color: Colors.teal, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Nhận xét trợ lý AI hôm nay',
                                    style: TextStyle(fontWeight: FontWeight.w900, color: Colors.teal.shade900, fontSize: 14),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                summary,
                                style: TextStyle(height: 1.45, color: Colors.grey.shade900, fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Màn hình biểu đồ 24h cho 1 chỉ số ────────────────────────────
class _MetricChartScreen extends StatelessWidget {
  final String title, metricKey, unit;
  final List<dynamic> data;
  final double safeLevel;
  final int aqi;

  const _MetricChartScreen({
    required this.title,
    required this.metricKey,
    required this.unit,
    required this.data,
    required this.safeLevel,
    required this.aqi,
  });

  @override
  Widget build(BuildContext context) {
    final spots = <FlSpot>[];
    for (int i = 0; i < data.length; i++) {
      final val = (data[i][metricKey] as num?)?.toDouble();
      if (val != null) spots.add(FlSpot(i.toDouble(), val));
    }

    final maxY = spots.isEmpty
        ? safeLevel * 1.5
        : (spots.map((s) => s.y).reduce((a, b) => a > b ? a : b) * 1.25);

    return Scaffold(
      appBar: AppBar(
        title: Text('$title — Lịch sử 24h', style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white.withOpacity(0.85),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: DynamicColorHelper.getBackgroundGradient(aqi),
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: const [0.0, 0.6],
          ),
        ),
        child: spots.isEmpty
            ? const Center(child: Text('Chưa có dữ liệu cho hôm nay'))
            : Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  children: [
                    // Min / Max / Avg stats card (Glassmorphism)
                    Container(
                      decoration: DynamicColorHelper.getGlassDecoration(aqi: aqi),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _stat('Tối thiểu', spots.map((s) => s.y).reduce((a, b) => a < b ? a : b)),
                                _stat('Tối đa', spots.map((s) => s.y).reduce((a, b) => a > b ? a : b)),
                                _stat('Trung bình', spots.map((s) => s.y).reduce((a, b) => a + b) / spots.length),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Chart card (Glassmorphism)
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                        decoration: DynamicColorHelper.getGlassDecoration(aqi: aqi),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: LineChart(
                              LineChartData(
                                minY: 0,
                                maxY: maxY,
                                gridData: FlGridData(
                                  show: true,
                                  getDrawingHorizontalLine: (v) => FlLine(color: Colors.grey.shade200, strokeWidth: 1),
                                  getDrawingVerticalLine: (v) => FlLine(color: Colors.grey.shade200, strokeWidth: 1),
                                ),
                                titlesData: FlTitlesData(
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      interval: (spots.length / 6).clamp(1.0, 100.0).toDouble(),
                                      getTitlesWidget: (v, _) => Padding(
                                        padding: const EdgeInsets.only(top: 8),
                                        child: Text(
                                          '${v.toInt()}ph',
                                          style: const TextStyle(fontSize: 9, color: Colors.black87, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ),
                                  ),
                                  leftTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 42,
                                      getTitlesWidget: (v, _) => Text(
                                        v.toStringAsFixed(v < 1 ? 2 : 0),
                                        style: const TextStyle(fontSize: 9, color: Colors.black87, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                  rightTitles:  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                  topTitles:    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                ),
                                borderData: FlBorderData(show: false),
                                lineBarsData: [
                                  LineChartBarData(
                                    spots: spots,
                                    isCurved: true,
                                    color: const Color(0xFF00796B),
                                    barWidth: 3.5,
                                    belowBarData: BarAreaData(
                                      show: true,
                                      color: const Color(0xFF00796B).withOpacity(0.12),
                                    ),
                                    dotData: const FlDotData(show: false),
                                  ),
                                ],
                                // Safety threshold line
                                extraLinesData: ExtraLinesData(
                                  horizontalLines: [
                                    HorizontalLine(
                                      y: safeLevel,
                                      color: Colors.red.withOpacity(0.65),
                                      strokeWidth: 2,
                                      dashArray: [6, 4],
                                      label: HorizontalLineLabel(
                                        show: true,
                                        style: const TextStyle(color: Colors.red, fontSize: 9, fontWeight: FontWeight.w900),
                                        labelResolver: (_) => 'Ngưỡng an toàn: $safeLevel $unit',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _stat(String label, double value) => Column(
    children: [
      Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade700, fontWeight: FontWeight.bold)),
      const SizedBox(height: 6),
      Text(
        value.toStringAsFixed(value < 1 ? 3 : 1),
        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: Color(0xFF263238)),
      ),
      const SizedBox(height: 2),
      Text(unit, style: TextStyle(fontSize: 10, color: Colors.grey.shade500, fontWeight: FontWeight.bold)),
    ],
  );
}
