import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/daily_summary.dart';

class ReportScreen extends StatefulWidget {
  final String deviceId;
  const ReportScreen({super.key, required this.deviceId});
  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  List<DailySummary> _reports = [];
  bool               _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await ApiService().getDailyReports(widget.deviceId);
    if (mounted) {
      setState(() {
        _reports = data.map((j) => DailySummary.fromJson(j as Map<String, dynamic>)).toList();
        _loading = false;
      });
    }
  }

  Color _levelColor(String? level) {
    switch (level) {
      case 'good':                return const Color(0xFF00E676); // Green
      case 'moderate':            return const Color(0xFFFFD600); // Yellow
      case 'unhealthy_sensitive': return const Color(0xFFFF9100); // Orange
      case 'unhealthy':           return const Color(0xFFFF1744); // Red
      case 'very_unhealthy':      return const Color(0xFFD500F9); // Purple
      case 'hazardous':           return const Color(0xFF8D6E63); // Brown
      default:                    return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Báo cáo chất lượng không khí')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _reports.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.analytics_outlined, size: 72, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text(
                        'Chưa có báo cáo AI hàng ngày.\n(Hệ thống tự tạo vào lúc 23:59 mỗi đêm)',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 14, height: 1.4),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _reports.length,
                    itemBuilder: (context, i) {
                      final r = _reports[i];
                      final color = _levelColor(r.pollutionLevel);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        elevation: 0,
                        child: ExpansionTile(
                          shape: const Border(),
                          iconColor: Colors.grey.shade600,
                          collapsedIconColor: Colors.grey.shade400,
                          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.08),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.calendar_today, color: color, size: 20),
                          ),
                          title: Text(
                            r.dateLabel,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF263238)),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Row(
                              children: [
                                Text(
                                  'AQI TB: ${r.aqiAvg ?? '—'}',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey),
                                ),
                                const SizedBox(width: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: color.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    r.pollutionLevelVn,
                                    style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Divider(),
                                  const SizedBox(height: 10),
                                  
                                  // Stats Row
                                  _statsRow(r),
                                  const SizedBox(height: 16),

                                  // AI Summary
                                  if (r.aiSummary != null && r.aiSummary!.isNotEmpty) ...[
                                    _section('Nhận định trợ lý AI', r.aiSummary!, Icons.auto_awesome, const Color(0xFF00796B)),
                                    const SizedBox(height: 12),
                                  ],

                                  // AI Advice
                                  if (r.aiAdvice != null && r.aiAdvice!.isNotEmpty) ...[
                                    _section('Khuyên nghị hành động', r.aiAdvice!, Icons.lightbulb_outline, Colors.orange.shade800),
                                    const SizedBox(height: 12),
                                  ],

                                  // Anomaly warnings
                                  if (r.anomalyCount > 0)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                      decoration: BoxDecoration(
                                        color: Colors.red.shade50,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: Colors.red.shade100),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(Icons.warning_amber_rounded, size: 18, color: Colors.red.shade700),
                                          const SizedBox(width: 8),
                                          Text(
                                            'AI phát hiện ${r.anomalyCount} điểm biến động chỉ số dị thường!',
                                            style: TextStyle(color: Colors.red.shade700, fontSize: 12, fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  Widget _statsRow(DailySummary r) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statItem('AQI Max', r.aqiMax?.toString() ?? '—', Colors.red.shade700),
          _statItem('AQI Min', r.aqiMin?.toString() ?? '—', Colors.green.shade700),
          _statItem('PM2.5 TB', r.pm25Avg != null ? '${r.pm25Avg!.toStringAsFixed(1)}' : '—', const Color(0xFF00796B)),
          _statItem('Khí chính', r.mainPollutant ?? 'Không', Colors.indigo.shade700),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: color),
        ),
      ],
    );
  }

  Widget _section(String title, String content, IconData icon, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.04),
        border: Border.all(color: color.withOpacity(0.12), width: 1.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 13, letterSpacing: 0.1),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(height: 1.45, color: Colors.grey.shade800, fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
