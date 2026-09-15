import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';

class NotificationsScreen extends StatefulWidget {
  final int userId;
  const NotificationsScreen({super.key, required this.userId});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<dynamic> _notifications = [];
  bool          _loading       = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await ApiService().getNotifications(widget.userId);
    if (mounted) {
      setState(() {
        _notifications = list;
        _loading       = false;
      });
    }
  }

  IconData _getIcon(String metric) {
    if (metric == 'anomaly') return Icons.auto_awesome;
    switch (metric) {
      case 'aqi': return Icons.air;
      case 'co2_ppm': return Icons.cloud_outlined;
      case 'co_ppm': return Icons.warning_amber_outlined;
      case 'pm25_ugm3': return Icons.grain;
      default: return Icons.notifications_active_outlined;
    }
  }

  Color _getColor(String metric) {
    if (metric == 'anomaly') return Colors.purple.shade700;
    switch (metric) {
      case 'aqi': return const Color(0xFF00796B);
      case 'co2_ppm': return Colors.blue.shade700;
      case 'co_ppm': return Colors.red.shade700;
      case 'pm25_ugm3': return Colors.orange.shade800;
      default: return const Color(0xFF00796B);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch sử thông báo & Cảnh báo'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _notifications.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.notifications_off_outlined, size: 72, color: Colors.grey.shade300),
                          const SizedBox(height: 16),
                          Text(
                            'Hộp thư thông báo trống.',
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 15, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: _load,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Tải lại'),
                          )
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      itemCount: _notifications.length,
                      itemBuilder: (context, index) {
                        final notif = _notifications[index];
                        final sentAt = notif['sent_at'] != null
                            ? DateTime.parse(notif['sent_at'] as String).toLocal()
                            : DateTime.now();
                        final dateStr = DateFormat('HH:mm — dd/MM/yyyy').format(sentAt);
                        final metric = notif['metric'] as String? ?? '';
                        final message = notif['message'] as String? ?? '';
                        final icon = _getIcon(metric);
                        final color = _getColor(metric);
                        final isLast = index == _notifications.length - 1;

                        return IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Timeline vertical line & dot column
                              Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: color.withOpacity(0.08),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: color.withOpacity(0.2), width: 1.5),
                                    ),
                                    child: Icon(icon, color: color, size: 18),
                                  ),
                                  Expanded(
                                    child: Container(
                                      width: isLast ? 0 : 2,
                                      color: Colors.grey.shade300,
                                      margin: const EdgeInsets.symmetric(vertical: 4),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 14),
                              // Warning Message Card
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: Card(
                                    margin: EdgeInsets.zero,
                                    elevation: 0,
                                    child: Padding(
                                      padding: const EdgeInsets.all(14),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                decoration: BoxDecoration(
                                                  color: color.withOpacity(0.12),
                                                  borderRadius: BorderRadius.circular(10),
                                                ),
                                                child: Text(
                                                  metric == 'anomaly' ? 'Cảnh báo AI' : 'Cảnh báo chỉ số',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: color,
                                                    fontSize: 10,
                                                  ),
                                                ),
                                              ),
                                              Text(
                                                dateStr,
                                                style: TextStyle(
                                                  color: Colors.grey.shade400,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 10.5,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            message,
                                            style: const TextStyle(
                                              fontSize: 13.5,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF263238),
                                              height: 1.35,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
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
}
