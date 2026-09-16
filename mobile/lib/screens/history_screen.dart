import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../utils/dynamic_color_helper.dart';

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
  DateTime _selectedDate = DateTime.now();
  List<dynamic> _history24h = [];
  bool _loading24h = true;
  String _metric24h = 'aqi';

  // Tab 7 ngày (Giá trị bình quân của từng ngày)
  List<dynamic> _dailyAvg7d = [];
  bool _loading7d = true;
  String _metric7d = 'aqi_avg';

  static const _metricOptions24h = [
    {'key': 'aqi', 'label': 'AQI'},
    {'key': 'pm25_ugm3', 'label': 'PM2.5'},
    {'key': 'co2_ppm', 'label': 'CO₂'},
    {'key': 'co_ppm', 'label': 'CO'},
    {'key': 'temperature_c', 'label': 'Nhiệt độ'},
    {'key': 'humidity_pct', 'label': 'Độ ẩm'},
  ];

  static const _metricOptions7d = [
    {'key': 'aqi_avg', 'label': 'AQI Bình Quân'},
    {'key': 'pm25_avg', 'label': 'PM2.5 Bình Quân'},
    {'key': 'co2_avg', 'label': 'CO₂ Bình Quân'},
    {'key': 'co_avg', 'label': 'CO Bình Quân'},
    {'key': 'temp_avg', 'label': 'Nhiệt Độ Bình Quân'},
    {'key': 'hum_avg', 'label': 'Độ Ẩm Bình Quân'},
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
    if (mounted) {
      setState(() {
        _history24h = data;
        _loading24h = false;
      });
    }
  }

  // Tải dữ liệu lịch sử 7 ngày: Lấy giá trị bình quân của từng ngày
  Future<void> _load7d() async {
    setState(() => _loading7d = true);
    final data = await ApiService().getHistory7Days(widget.deviceId);
    if (mounted) {
      setState(() {
        _dailyAvg7d = data;
        _loading7d = false;
      });
    }
  }

  List<FlSpot> _spots24h(List<dynamic> data, String key) {
    final spots = <FlSpot>[];
    for (int i = 0; i < data.length; i++) {
      final val = (data[i][key] as num?)?.toDouble();
      if (val != null) spots.add(FlSpot(i.toDouble(), val));
    }
    return spots;
  }

  List<FlSpot> _spots7d(List<dynamic> data, String key) {
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
      const Color(0xFF00E676).withValues(alpha: 0.25),
      const Color(0xFFFFD600).withValues(alpha: 0.25),
      const Color(0xFFFF9100).withValues(alpha: 0.25),
      const Color(0xFFFF1744).withValues(alpha: 0.25),
      const Color(0xFFD500F9).withValues(alpha: 0.25),
    ];

    final List<Color> colors = [
      const Color(0xFF00E676).withValues(alpha: 0.02)
    ];
    final List<double> stops = [0.0];

    for (int i = 0; i < boundaries.length; i++) {
      final y = boundaries[i];
      if (y < maxY) {
        colors.add(boundaryColors[i]);
        stops.add(y / maxY);
      }
    }

    colors.add(const Color(0xFF8D6E63).withValues(alpha: 0.25));
    stops.add(1.0);

    return LinearGradient(
      colors: colors,
      stops: stops,
      begin: Alignment.bottomCenter,
      end: Alignment.topCenter,
    );
  }

  // Biểu đồ 24h (Dữ liệu theo phút)
  Widget _chart24h(List<FlSpot> spots, {required bool isAqi}) {
    if (spots.isEmpty) {
      return const Center(
          child: Text('Không có dữ liệu cho khoảng thời gian này'));
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
              Colors.teal.withValues(alpha: 0.02),
              Colors.blue.withValues(alpha: 0.18),
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
          getDrawingHorizontalLine: (value) =>
              FlLine(color: Colors.grey.shade200, strokeWidth: 1),
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
                  style: TextStyle(
                      fontSize: 9,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.bold),
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
                style: TextStyle(
                    fontSize: 9,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            gradient: lineGradient,
            barWidth: 3.5,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(show: true, gradient: fillGradient),
          ),
        ],
      ),
    );
  }

  // Biểu đồ 7 ngày: Hiển thị đúng 7 mốc ngày với giá trị bình quân của từng ngày
  Widget _chart7d(List<FlSpot> spots, {required bool isAqi}) {
    if (spots.isEmpty) {
      return const Center(child: Text('Đang tải dữ liệu bình quân 7 ngày...'));
    }
    final rawMaxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    final double maxY = (rawMaxY * 1.25).clamp(10.0, double.infinity);

    final lineGradient = isAqi
        ? _getAqiGradient(maxY)
        : const LinearGradient(
            colors: [Color(0xFF00796B), Color(0xFF0288D1)],
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
          );

    final fillGradient = isAqi
        ? _getAqiFillGradient(maxY)
        : LinearGradient(
            colors: [
              Colors.teal.withValues(alpha: 0.05),
              Colors.blue.withValues(alpha: 0.22),
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
          drawVerticalLine: true,
          getDrawingHorizontalLine: (value) =>
              FlLine(color: Colors.grey.shade200, strokeWidth: 1),
          getDrawingVerticalLine: (value) => FlLine(
            color: Colors.grey.shade100,
            strokeWidth: 1,
            dashArray: [4, 4],
          ),
        ),
        borderData: FlBorderData(show: false),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final idx = spot.x.toInt();
                String dateLabel = '';
                String dayName = '';
                if (idx >= 0 && idx < _dailyAvg7d.length) {
                  dateLabel = _dailyAvg7d[idx]['day_label'] ?? '';
                  dayName = _dailyAvg7d[idx]['day_name'] ?? '';
                }
                return LineTooltipItem(
                  '$dayName ($dateLabel)\nBình quân: ${spot.y.toStringAsFixed(1)}',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                );
              }).toList();
            },
          ),
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1.0,
              reservedSize: 36,
              getTitlesWidget: (v, _) {
                final idx = v.toInt();
                if (idx < 0 || idx >= _dailyAvg7d.length) {
                  return const SizedBox.shrink();
                }
                final item = _dailyAvg7d[idx];
                final dayLabel = item['day_label'] as String? ?? '';
                final isToday = (idx == _dailyAvg7d.length - 1);

                return Padding(
                  padding: const EdgeInsets.only(top: 6.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        dayLabel,
                        style: TextStyle(
                          fontSize: 10,
                          color: isToday
                              ? const Color(0xFF00796B)
                              : Colors.grey.shade700,
                          fontWeight:
                              isToday ? FontWeight.bold : FontWeight.w600,
                        ),
                      ),
                      if (isToday)
                        Container(
                          margin: const EdgeInsets.only(top: 2),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00796B),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Nay',
                            style: TextStyle(
                                fontSize: 8,
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              getTitlesWidget: (v, _) => Text(
                v.toInt().toString(),
                style: TextStyle(
                    fontSize: 9,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.25,
            gradient: lineGradient,
            barWidth: 3.5,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) =>
                  FlDotCirclePainter(
                radius: 4.5,
                color: isAqi ? Colors.teal.shade700 : const Color(0xFF00796B),
                strokeWidth: 2.2,
                strokeColor: Colors.white,
              ),
            ),
            belowBarData: BarAreaData(show: true, gradient: fillGradient),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown(List<Map<String, String>> options, String current,
      ValueChanged<String> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: Colors.teal.withValues(alpha: 0.3), width: 1.5),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: current,
          isDense: true,
          icon: const Icon(Icons.arrow_drop_down, color: Colors.teal),
          onChanged: (v) => onChanged(v!),
          items: options
              .map((o) => DropdownMenuItem(
                    value: o['key']!,
                    child: Text(
                      o['label']!,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Color(0xFF263238)),
                    ),
                  ))
              .toList(),
        ),
      ),
    );
  }

  String _getMetricUnit(String metric) {
    if (metric.contains('pm')) return 'µg/m³';
    if (metric.contains('co2')) return 'ppm';
    if (metric.contains('co_')) return 'ppm';
    if (metric.contains('temp')) return '°C';
    if (metric.contains('hum')) return '%';
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final mockAqiForBg = _tabs.index == 0
        ? (_history24h.isNotEmpty
            ? (_history24h.last['aqi'] as num?)?.toInt() ?? 20
            : 20)
        : (_dailyAvg7d.isNotEmpty
            ? (_dailyAvg7d.last['aqi_avg'] as num?)?.toInt() ?? 20
            : 20);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch sử chỉ số & Biểu đồ',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white.withValues(alpha: 0.8),
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
            // ── Tab 1: 24h ───────────────────────────────────────────
            Column(
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: Colors.teal.withValues(alpha: 0.3),
                              width: 1.5),
                        ),
                        child: TextButton.icon(
                          icon: const Icon(Icons.calendar_today,
                              size: 16, color: Colors.teal),
                          label: Text(
                            DateFormat('dd/MM/yyyy').format(_selectedDate),
                            style: const TextStyle(
                                color: Color(0xFF263238),
                                fontWeight: FontWeight.bold,
                                fontSize: 13),
                          ),
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _selectedDate,
                              firstDate: DateTime.now()
                                  .subtract(const Duration(days: 3)),
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
                      _buildDropdown(
                        _metricOptions24h
                            .map(
                                (m) => {'key': m['key']!, 'label': m['label']!})
                            .toList(),
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
                          decoration: DynamicColorHelper.getGlassDecoration(
                              aqi: mockAqiForBg),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                              child: _chart24h(
                                _spots24h(_history24h, _metric24h),
                                isAqi: _metric24h == 'aqi',
                              ),
                            ),
                          ),
                        ),
                ),
              ],
            ),

            // ── Tab 2: 7 ngày (Giá trị bình quân của từng ngày) ───────
            Column(
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.teal.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: Colors.teal.shade200, width: 1.0),
                        ),
                        child: Row(
                          children: const [
                            Icon(Icons.insights, size: 14, color: Colors.teal),
                            SizedBox(width: 4),
                            Text(
                              'Bình quân từng ngày',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF004D40),
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      _buildDropdown(
                        _metricOptions7d
                            .map(
                                (m) => {'key': m['key']!, 'label': m['label']!})
                            .toList(),
                        _metric7d,
                        (v) => setState(() => _metric7d = v),
                      ),
                    ],
                  ),
                ),

                // Biểu đồ 7 điểm bình quân
                SizedBox(
                  height: 240,
                  child: _loading7d
                      ? const Center(child: CircularProgressIndicator())
                      : Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                          decoration: DynamicColorHelper.getGlassDecoration(
                              aqi: mockAqiForBg),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                              child: _chart7d(
                                _spots7d(_dailyAvg7d, _metric7d),
                                isAqi: _metric7d == 'aqi_avg',
                              ),
                            ),
                          ),
                        ),
                ),

                const SizedBox(height: 12),

                // Danh sách thẻ thống kê chi tiết bình quân từng ngày trong 7 ngày
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      const Icon(Icons.date_range,
                          size: 16, color: Color(0xFF004D40)),
                      const SizedBox(width: 6),
                      Text(
                        'Chi tiết bình quân 7 ngày qua:',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),

                Expanded(
                  child: _loading7d
                      ? const SizedBox.shrink()
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                          itemCount: _dailyAvg7d.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 6),
                          itemBuilder: (context, index) {
                            // Hiển thị ngày gần nhất (hôm nay) lên trên cùng
                            final reversedIdx = _dailyAvg7d.length - 1 - index;
                            final item = _dailyAvg7d[reversedIdx];
                            final val =
                                (item[_metric7d] as num?)?.toDouble() ?? 0.0;
                            final isAqi = _metric7d == 'aqi_avg';
                            final dayName = item['day_name'] ?? '';
                            final dayLabel = item['day_label'] ?? '';
                            final tempAvg = item['temp_avg'] ?? 0;
                            final humAvg = item['hum_avg'] ?? 0;

                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.9),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: index == 0
                                      ? Colors.teal.shade400
                                      : Colors.grey.shade200,
                                  width: index == 0 ? 1.4 : 1.0,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.03),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  )
                                ],
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundColor: index == 0
                                        ? const Color(0xFF00796B)
                                        : Colors.grey.shade100,
                                    child: Icon(
                                      index == 0
                                          ? Icons.today
                                          : Icons.calendar_today,
                                      size: 16,
                                      color: index == 0
                                          ? Colors.white
                                          : Colors.grey.shade600,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              '$dayName ($dayLabel)',
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: index == 0
                                                    ? FontWeight.bold
                                                    : FontWeight.w600,
                                                color: index == 0
                                                    ? const Color(0xFF004D40)
                                                    : Colors.black87,
                                              ),
                                            ),
                                            if (index == 0) ...[
                                              const SizedBox(width: 6),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 5,
                                                        vertical: 1),
                                                decoration: BoxDecoration(
                                                  color:
                                                      const Color(0xFF00796B),
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                                child: const Text(
                                                  'Hôm nay',
                                                  style: TextStyle(
                                                      fontSize: 9,
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.bold),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Nhiệt độ: $tempAvg°C • Độ ẩm: $humAvg%',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: isAqi
                                          ? (val <= 25
                                              ? Colors.green.shade50
                                              : (val <= 50
                                                  ? Colors.lightGreen.shade50
                                                  : Colors.amber.shade50))
                                          : Colors.teal.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: isAqi
                                            ? (val <= 25
                                                ? Colors.green.shade300
                                                : Colors.amber.shade300)
                                            : Colors.teal.shade200,
                                        width: 0.8,
                                      ),
                                    ),
                                    child: Text(
                                      isAqi
                                          ? 'AQI ${val.round()}'
                                          : '${val.toStringAsFixed(1)} ${_getMetricUnit(_metric7d)}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: isAqi
                                            ? (val <= 25
                                                ? Colors.green.shade800
                                                : Colors.amber.shade900)
                                            : Colors.teal.shade800,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
