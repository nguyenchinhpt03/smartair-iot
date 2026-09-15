import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../widgets/neumorphic_liquid_gauge.dart';
import '../widgets/sensor_card.dart';
import '../utils/dynamic_color_helper.dart';
import 'detail_screen.dart';
import 'history_screen.dart';
import 'report_screen.dart';
import 'chat_screen.dart';
import 'eco_tourism_screen.dart';
import 'settings_screen.dart';
import 'notifications_screen.dart';
import 'device_management_screen.dart';
import '../widgets/wifi_provisioning_dialog.dart';
import '../services/fcm_service.dart';
import 'dart:ui';
import 'dart:math' as math;

class DashboardScreen extends StatefulWidget {
  final String deviceId;
  final int userId;
  const DashboardScreen(
      {super.key, required this.deviceId, required this.userId});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic> _data = {};
  Map<String, dynamic> _alertSettings = {};
  bool _loading = true;
  bool _offline = false;
  Timer? _timer;
  DateTime? _lastUpdate;
  List<dynamic> _userDevices = [];
  String _currentDeviceId = '';
  int _unreadNotificationsCount = 0;
  String? _wifiSsid;
  StreamSubscription<dynamic>? _fcmSubscription;

  // Gamification (Plant) State
  int _greenPoints = 40;
  int _treeLevel = 1;
  DateTime? _lastWateredTime;
  static const int _wateringCooldownSeconds = 60; // Giới hạn tưới mỗi 60 giây

  @override
  void initState() {
    super.initState();
    _currentDeviceId = widget.deviceId;
    _load();
    _loadUserDevices();
    _loadPlantState();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _load());
    _fcmSubscription =
        FcmService.foregroundMessageStream.stream.listen((message) {
      _loadUnreadNotificationsCount();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _fcmSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadPlantState() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _greenPoints = prefs.getInt('green_points_${widget.userId}') ?? 40;
        _treeLevel = prefs.getInt('tree_level_${widget.userId}') ?? 1;
        final lastTimeMs = prefs.getInt('last_watered_${widget.userId}');
        if (lastTimeMs != null) {
          _lastWateredTime = DateTime.fromMillisecondsSinceEpoch(lastTimeMs);
        }
      });
    }
  }

  Future<void> _savePlantState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('green_points_${widget.userId}', _greenPoints);
    await prefs.setInt('tree_level_${widget.userId}', _treeLevel);
    if (_lastWateredTime != null) {
      await prefs.setInt('last_watered_${widget.userId}',
          _lastWateredTime!.millisecondsSinceEpoch);
    }
  }

  Future<void> _loadUserDevices() async {
    final list = await ApiService().getUserDevices(widget.userId);
    if (mounted) {
      setState(() {
        _userDevices = list;
      });
    }
  }

  Future<void> _switchDevice(String deviceId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('device_id', deviceId);
    setState(() {
      _currentDeviceId = deviceId;
      _loading = true;
    });
    _load();
  }

  Future<void> _load() async {
    final result = await ApiService().getRealtimeReading(_currentDeviceId);
    _loadUnreadNotificationsCount();

    Map<String, dynamic> settings = {};
    try {
      final fetchedSettings =
          await ApiService().getAlertSettings(_currentDeviceId, widget.userId);
      if (fetchedSettings != null) {
        settings = fetchedSettings;
      }
    } catch (_) {}

    String? wifi = result?['wifi_ssid'] as String?;
    if (wifi == null || wifi.isEmpty) {
      try {
        final prefs = await SharedPreferences.getInstance();
        wifi = prefs.getString('device_wifi_ssid_$_currentDeviceId');
      } catch (_) {}
    }

    if (mounted) {
      setState(() {
        _loading = false;
        _offline = result == null;
        _data = result ?? _data;
        _alertSettings = settings;
        _wifiSsid = wifi ?? _wifiSsid;
        _lastUpdate = result != null ? DateTime.now() : _lastUpdate;
      });
    }
  }

  Future<void> _loadUnreadNotificationsCount() async {
    try {
      final notifs = await ApiService().getNotifications(widget.userId);
      final prefs = await SharedPreferences.getInstance();
      final lastReadMs =
          prefs.getInt('last_read_notifications_timestamp_${widget.userId}') ??
              0;

      int count = 0;
      for (final n in notifs) {
        final sentAtStr = n['sent_at'] as String?;
        if (sentAtStr != null) {
          final sentAt = DateTime.parse(sentAtStr).millisecondsSinceEpoch;
          if (sentAt > lastReadMs) {
            count++;
          }
        }
      }

      if (mounted) {
        setState(() {
          _unreadNotificationsCount = count;
        });
      }
    } catch (_) {}
  }

  Future<void> _markNotificationsAsRead() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(
        'last_read_notifications_timestamp_${widget.userId}',
        DateTime.now().millisecondsSinceEpoch,
      );
      if (mounted) {
        setState(() {
          _unreadNotificationsCount = 0;
        });
      }
    } catch (_) {}
  }

  // Quick QR Scan dialog simulated with glowing laser line
  void _showQuickScanDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return _QuickScanDialog(
          userId: widget.userId,
          onSuccess: (newDevId) {
            _switchDevice(newDevId);
            _loadUserDevices();
          },
        );
      },
    );
  }

  // share card showing instagram-style air details
  void _showShareableAirCard(int aqi) {
    final aqiColor = DynamicColorHelper.getAqiColor(aqi);
    final aqiLabel = DynamicColorHelper.getAqiLabel(aqi);

    // AI quotes based on quality
    String quote =
        "Không khí trong lành, hãy hít thở sâu và mở rộng cửa sổ đón gió nhé!";
    if (aqi > 200) {
      quote =
          "Mức nguy hại cực cao! Hãy đóng kín các cửa sổ và bật máy lọc ở công suất lớn nhất.";
    } else if (aqi > 100) {
      quote =
          "Mật độ ô nhiễm tăng cao. Hãy chú ý sức khỏe hô hấp và bật máy lọc trong nhà.";
    } else if (aqi > 50) {
      quote =
          "Chất lượng không khí ở mức chấp nhận được. Tránh hoạt động mạnh ngoài trời kéo dài.";
    }

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Story card content
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: LinearGradient(
                    colors: [
                      aqiColor.withOpacity(0.85),
                      DynamicColorHelper.darken(aqiColor, 0.25)
                          .withOpacity(0.95),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: aqiColor.withOpacity(0.4),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.bubble_chart,
                                color: Colors.white, size: 28),
                            SizedBox(width: 8),
                            Text(
                              'SmartAir Monitor',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  letterSpacing: 0.5),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text('LIVE',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 35),
                    const Text('Chất lượng không khí tại nơi tôi sống:',
                        style: TextStyle(color: Colors.white70, fontSize: 14)),
                    const SizedBox(height: 10),
                    Container(
                      width: 130,
                      height: 130,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '$aqi',
                            style: TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.w900,
                                color:
                                    DynamicColorHelper.darken(aqiColor, 0.25),
                                height: 1.0),
                          ),
                          const Text('AQI',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      aqiLabel,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 24),
                    // Speech bubble from Claude
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white30),
                      ),
                      child: Text(
                        '"$quote"',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontStyle: FontStyle.italic,
                            height: 1.4),
                      ),
                    ),
                    const SizedBox(height: 35),
                    // QR Code simulation
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: CustomPaint(
                            painter: _MockQrPainter(),
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Quét mã QR',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12)),
                            SizedBox(height: 2),
                            Text('Để tải app SmartAir miễn phí',
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 10)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              // Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black87,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 12),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Đã lưu hình ảnh vào thư viện!'),
                        backgroundColor: Colors.green,
                      ));
                    },
                    icon: const Icon(Icons.download),
                    label: const Text('Tải ảnh xuống',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 12),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content:
                            Text('Đã chia sẻ lên Instagram Story thành công!'),
                        backgroundColor: Colors.indigo,
                      ));
                    },
                    icon: const Icon(Icons.share),
                    label: const Text('Chia sẻ ngay',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              )
            ],
          ),
        );
      },
    );
  }

  Widget _navCard(String title, String desc, IconData icon, Color color,
      Widget screen, int aqi) {
    final border = DynamicColorHelper.getGlassDecoration(aqi: aqi);
    return Container(
      decoration: border,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => Navigator.push(
                  context, MaterialPageRoute(builder: (_) => screen)),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: color, size: 20),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      title,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF263238)),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      desc,
                      style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final aqi = (_data['aqi'] as num?)?.toInt() ?? 0;
    final pm25 = (_data['pm25_ugm3'] as num?)?.toDouble() ?? 0.0;
    final pm10 = (_data['pm10_ugm3'] as num?)?.toDouble() ?? 0.0;
    final co2 = (_data['co2_ppm'] as num?)?.toDouble() ?? 0.0;
    final co = (_data['co_ppm'] as num?)?.toDouble() ?? 0.0;
    final nh3 = (_data['nh3_ppm'] as num?)?.toDouble() ?? 0.0;
    final benzene = (_data['benzene_ppm'] as num?)?.toDouble() ?? 0.0;
    final temp = (_data['temperature_c'] as num?)?.toDouble() ?? 0.0;
    final hum = (_data['humidity_pct'] as num?)?.toDouble() ?? 0.0;

    final locationStr = _data['location'] as String? ?? 'Trong nhà';
    final isOnline = !_offline;

    // Threshold Alert checks
    final limitPm25 = (_alertSettings['pm25_ugm3'] as num?)?.toDouble() ?? 35.0;
    final limitCo2 = (_alertSettings['co2_ppm'] as num?)?.toDouble() ?? 1000.0;
    final limitCo = (_alertSettings['co_ppm'] as num?)?.toDouble() ?? 9.0;
    final limitAqi = (_alertSettings['aqi'] as num?)?.toDouble() ?? 100.0;
    final limitNh3 = (_alertSettings['nh3_ppm'] as num?)?.toDouble() ?? 25.0;

    final isPm25Exceeded = pm25 > limitPm25;
    final isCo2Exceeded = co2 > limitCo2;
    final isCoExceeded = co > limitCo;
    final isNh3Exceeded = nh3 > limitNh3;
    final isPm10Exceeded = pm10 > 75.0;
    final isBenzeneExceeded = benzene > 0.01;

    final primaryAqiColor = DynamicColorHelper.getAqiColor(aqi);

    // Tree level indicators
    String treeEmoji = '🌱';
    String treeName = 'Hạt mầm xanh';
    if (_treeLevel == 2) {
      treeEmoji = '🌿';
      treeName = 'Chồi non đầy sống';
    } else if (_treeLevel >= 3) {
      treeEmoji = '🌳';
      treeName = 'Cây đại thụ vững chãi';
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white.withOpacity(0.8),
        elevation: 0,
        flexibleSpace: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(color: Colors.transparent),
          ),
        ),
        title: PopupMenuButton<String>(
          initialValue: _currentDeviceId,
          onSelected: _switchDevice,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: primaryAqiColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _currentDeviceId.isNotEmpty
                      ? _currentDeviceId
                      : 'Chọn thiết bị',
                  style: TextStyle(
                      color: DynamicColorHelper.darken(primaryAqiColor, 0.25),
                      fontWeight: FontWeight.bold,
                      fontSize: 15),
                ),
                Icon(Icons.arrow_drop_down,
                    color: DynamicColorHelper.darken(primaryAqiColor, 0.25),
                    size: 22),
              ],
            ),
          ),
          itemBuilder: (context) {
            return _userDevices.map<PopupMenuItem<String>>((dev) {
              final devId = dev['device_id'] as String;
              final name = dev['name'] as String? ?? 'Device';
              return PopupMenuItem<String>(
                value: devId,
                child: Text('$name ($devId)'),
              );
            }).toList();
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.wifi, color: Colors.teal),
            tooltip: 'Cài đặt Wi-Fi cho thiết bị',
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) =>
                    WifiProvisioningDialog(deviceId: _currentDeviceId),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.qr_code_scanner, color: Colors.black87),
            tooltip: 'Quét QR Nhanh',
            onPressed: _showQuickScanDialog,
          ),
          IconButton(
            icon: const Icon(Icons.devices_other, color: Colors.black87),
            tooltip: 'Quản lý thiết bị',
            onPressed: () async {
              final reload = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DeviceManagementScreen(
                    userId: widget.userId,
                    activeDeviceId: _currentDeviceId,
                  ),
                ),
              );
              if (reload == true) {
                final prefs = await SharedPreferences.getInstance();
                final activeId = prefs.getString('device_id');
                if (activeId != null && activeId != _currentDeviceId) {
                  setState(() {
                    _currentDeviceId = activeId;
                    _loading = true;
                  });
                }
                _load();
                _loadUserDevices();
              }
            },
          ),
          Badge(
            label: Text('$_unreadNotificationsCount'),
            isLabelVisible: _unreadNotificationsCount > 0,
            child: IconButton(
              icon: const Icon(Icons.notifications, color: Colors.black87),
              onPressed: () async {
                await _markNotificationsAsRead();
                if (!mounted) return;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => NotificationsScreen(userId: widget.userId),
                  ),
                ).then((_) {
                  _load();
                });
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.black87),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SettingsScreen(
                    deviceId: _currentDeviceId, userId: widget.userId),
              ),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: DynamicColorHelper.getBackgroundGradient(aqi),
            stops: const [0.0, 0.55],
          ),
        ),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _load,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Column(
                    children: [
                      // Device Status Card (Glassmorphic)
                      Container(
                        decoration:
                            DynamicColorHelper.getGlassDecoration(aqi: aqi),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 12),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: primaryAqiColor.withOpacity(0.12),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(Icons.sensors,
                                        color: primaryAqiColor, size: 22),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Mã thiết bị: $_currentDeviceId',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w900,
                                              fontSize: 14,
                                              color: Color(0xFF263238)),
                                        ),
                                        const SizedBox(height: 3),
                                        Row(
                                          children: [
                                            Container(
                                              width: 8,
                                              height: 8,
                                              decoration: BoxDecoration(
                                                color: isOnline
                                                    ? Colors.green
                                                    : Colors.grey,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              isOnline
                                                  ? 'Đang hoạt động'
                                                  : 'Ngoại tuyến',
                                              style: TextStyle(
                                                color: isOnline
                                                    ? Colors.green.shade800
                                                    : Colors.grey.shade700,
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            const Icon(
                                                Icons.location_on_outlined,
                                                size: 14,
                                                color: Colors.grey),
                                            const SizedBox(width: 2),
                                            Text(
                                              locationStr,
                                              style: const TextStyle(
                                                  color: Colors.black54,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 5),
                                        InkWell(
                                          onTap: () {
                                            showDialog(
                                              context: context,
                                              builder: (_) =>
                                                  WifiProvisioningDialog(
                                                      deviceId: _currentDeviceId),
                                            ).then((_) => _load());
                                          },
                                          borderRadius:
                                              BorderRadius.circular(6),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.wifi,
                                                size: 13,
                                                color: isOnline
                                                    ? const Color(0xFF00796B)
                                                    : Colors.grey.shade600,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                'Wi-Fi: ',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.grey.shade700,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              Flexible(
                                                child: Text(
                                                  _wifiSsid != null &&
                                                          _wifiSsid!.isNotEmpty
                                                      ? _wifiSsid!
                                                      : (isOnline
                                                          ? 'Đã kết nối'
                                                          : 'Chưa cấu hình'),
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                    color: isOnline
                                                        ? const Color(0xFF00796B)
                                                        : Colors.grey.shade700,
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              Icon(
                                                Icons.settings_outlined,
                                                size: 11,
                                                color: Colors.teal.shade300,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (_lastUpdate != null)
                                    Text(
                                      '${_lastUpdate!.hour.toString().padLeft(2, '0')}:${_lastUpdate!.minute.toString().padLeft(2, '0')}',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                          fontWeight: FontWeight.bold),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Neumorphic Wave Liquid Gauge Center Box
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Center(child: NeumorphicLiquidGauge(aqi: aqi)),
                          Positioned(
                            right: 15,
                            bottom: 10,
                            child: CircleAvatar(
                              backgroundColor: Colors.white,
                              child: IconButton(
                                icon: Icon(Icons.ios_share,
                                    color: primaryAqiColor, size: 20),
                                tooltip: 'Chia sẻ chỉ số',
                                onPressed: () => _showShareableAirCard(aqi),
                              ),
                            ),
                          )
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Grid Header
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '8 Chỉ Số Cảm Biến Liên Tục',
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF263238)),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Sensor Grid
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        childAspectRatio: 2.1,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        children: [
                          SensorCard(
                              label: 'Bụi mịn PM2.5',
                              value: pm25.toStringAsFixed(1),
                              unit: 'µg/m³',
                              icon: Icons.blur_on,
                              color: Colors.amber,
                              isExceeded: isPm25Exceeded),
                          SensorCard(
                              label: 'Bụi mịn PM10',
                              value: pm10.toStringAsFixed(1),
                              unit: 'µg/m³',
                              icon: Icons.lens_blur,
                              color: Colors.orange,
                              isExceeded: isPm10Exceeded),
                          SensorCard(
                              label: 'Khí CO₂',
                              value: co2.toStringAsFixed(0),
                              unit: 'ppm',
                              icon: Icons.cloud,
                              color: Colors.deepOrange,
                              isExceeded: isCo2Exceeded),
                          SensorCard(
                              label: 'Khí độc CO',
                              value: co.toStringAsFixed(1),
                              unit: 'ppm',
                              icon: Icons.warning,
                              color: Colors.red,
                              isExceeded: isCoExceeded),
                          SensorCard(
                              label: 'Khí NH₃',
                              value: nh3.toStringAsFixed(1),
                              unit: 'ppm',
                              icon: Icons.opacity,
                              color: Colors.blue,
                              isExceeded: isNh3Exceeded),
                          SensorCard(
                              label: 'Khí Benzene',
                              value: benzene.toStringAsFixed(3),
                              unit: 'ppm',
                              icon: Icons.science,
                              color: Colors.purple,
                              isExceeded: isBenzeneExceeded),
                          SensorCard(
                              label: 'Nhiệt độ',
                              value: temp.toStringAsFixed(1),
                              unit: '°C',
                              icon: Icons.thermostat,
                              color: Colors.teal),
                          SensorCard(
                              label: 'Độ ẩm',
                              value: hum.toStringAsFixed(1),
                              unit: '%',
                              icon: Icons.water_drop,
                              color: Colors.blueAccent),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Gamification - Plant Care Box
                      Container(
                        decoration:
                            DynamicColorHelper.getGlassDecoration(aqi: aqi),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Padding(
                              padding: const EdgeInsets.all(14.0),
                              child: Row(
                                children: [
                                  // Tree graphic area
                                  Container(
                                    width: 65,
                                    height: 65,
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade50,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          color: Colors.green.shade200,
                                          width: 2),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      treeEmoji,
                                      style: const TextStyle(fontSize: 36),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          treeName,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w900,
                                              fontSize: 14,
                                              color: Colors.green),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          'Green Point: $_greenPoints / ${_treeLevel * 100}',
                                          style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey.shade700,
                                              fontWeight: FontWeight.bold),
                                        ),
                                        const SizedBox(height: 6),
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(4),
                                          child: LinearProgressIndicator(
                                            value: _greenPoints /
                                                (_treeLevel * 100),
                                            backgroundColor:
                                                Colors.green.shade100,
                                            valueColor:
                                                const AlwaysStoppedAnimation(
                                                    Colors.green),
                                            minHeight: 6,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 8),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10)),
                                    ),
                                    onPressed: () {
                                      final now = DateTime.now();
                                      if (_lastWateredTime != null) {
                                        final diff = now
                                            .difference(_lastWateredTime!)
                                            .inSeconds;
                                        if (diff < _wateringCooldownSeconds) {
                                          final remaining =
                                              _wateringCooldownSeconds - diff;
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(SnackBar(
                                            content: Text(
                                                '⏳ Cây vẫn đủ ẩm! Vui lòng đợi ' +
                                                    remaining.toString() +
                                                    ' giây nữa để tưới tiếp nhé. 🌱'),
                                            backgroundColor:
                                                Colors.orange.shade800,
                                            duration:
                                                const Duration(seconds: 2),
                                          ));
                                          return;
                                        }
                                      }
                                      setState(() {
                                        _lastWateredTime = now;
                                        _greenPoints += 15;
                                        if (_greenPoints >= _treeLevel * 100) {
                                          _greenPoints -= _treeLevel * 100;
                                          _treeLevel += 1;
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(SnackBar(
                                            content: Text(
                                                'Chúc mừng! Cây của bạn đã tiến hóa lên cấp độ $_treeLevel! 🎉'),
                                            backgroundColor:
                                                Colors.green.shade700,
                                          ));
                                        } else {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(const SnackBar(
                                            content: Text(
                                                'Đã tưới nước! Điểm Xanh +15! 🌱'),
                                            backgroundColor: Colors.green,
                                            duration: Duration(seconds: 1),
                                          ));
                                        }
                                        _savePlantState();
                                      });
                                    },
                                    child: const Text('Tưới nước',
                                        style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Navigation grid header
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Tính Năng Hệ Thống & AI',
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF263238)),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Navigation grid
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        childAspectRatio: 1.45,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        children: [
                          _navCard(
                              'Chi tiết',
                              'Thông số chi tiết cảm biến',
                              Icons.grid_view,
                              const Color(0xFF00796B),
                              DetailScreen(deviceId: _currentDeviceId),
                              aqi),
                          _navCard(
                              'Lịch sử',
                              'Biểu đồ 24h & 7 ngày',
                              Icons.show_chart,
                              Colors.blue.shade800,
                              HistoryScreen(deviceId: _currentDeviceId),
                              aqi),
                          _navCard(
                              'Báo cáo AI',
                              'Nhận xét phân tích AI',
                              Icons.analytics_outlined,
                              Colors.indigo.shade800,
                              ReportScreen(deviceId: _currentDeviceId),
                              aqi),
                          _navCard(
                              'Trợ lý AI',
                              'Tư vấn sức khoẻ 24/7',
                              Icons.chat_bubble_outline,
                              Colors.purple.shade800,
                              ChatScreen(deviceId: _currentDeviceId),
                              aqi),
                          _navCard(
                              'Du lịch Xanh',
                              'Điểm đến sạch cuối tuần',
                              Icons.forest_outlined,
                              Colors.green.shade800,
                              const EcoTourismScreen(),
                              aqi),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const SizedBox(height: 90),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}

// Simulated scan dialog with laser animation
class _QuickScanDialog extends StatefulWidget {
  final int userId;
  final ValueChanged<String> onSuccess;
  const _QuickScanDialog({required this.userId, required this.onSuccess});

  @override
  State<_QuickScanDialog> createState() => _QuickScanDialogState();
}

class _QuickScanDialogState extends State<_QuickScanDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  final _idCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  String _location = 'indoor';
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animController.dispose();
    _idCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final devId = _idCtrl.text.trim();
    final name = _nameCtrl.text.trim();
    if (devId.isEmpty) {
      setState(() => _error = "Vui lòng nhập mã thiết bị!");
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    final res = await ApiService().addDevice(
      deviceId: devId,
      name: name.isEmpty ? 'SmartAir QR Device' : name,
      location: _location,
      userId: widget.userId,
    );

    if (res == null || res.containsKey('error')) {
      setState(() {
        _loading = false;
        _error = res?['error'] ?? 'Lỗi không xác định khi liên kết.';
      });
    } else {
      widget.onSuccess(devId);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Đã liên kết thành công thiết bị: $devId!'),
          backgroundColor: Colors.green,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.qr_code_scanner, color: Colors.teal),
          SizedBox(width: 8),
          Text('Quét Mã Kết Nối QR',
              style: TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Viewfinder laser scanner simulation
            Container(
              width: 200,
              height: 140,
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade400, width: 2),
              ),
              child: AnimatedBuilder(
                animation: _animController,
                builder: (context, child) {
                  return Stack(
                    children: [
                      // Viewfinder border indicators
                      Align(
                        alignment: Alignment.center,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white38, width: 2),
                          ),
                        ),
                      ),
                      // Animated scanning line
                      Positioned(
                        top: _animController.value * 130 + 5,
                        left: 10,
                        right: 10,
                        child: Container(
                          height: 3,
                          decoration: BoxDecoration(
                            color: Colors.redAccent,
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.redAccent.withOpacity(0.8),
                                  blurRadius: 6,
                                  spreadRadius: 1)
                            ],
                          ),
                        ),
                      ),
                      const Align(
                        alignment: Alignment.bottomCenter,
                        child: Padding(
                          padding: EdgeInsets.only(bottom: 8.0),
                          child: Text(
                            'Đang định vị mã QR...',
                            style:
                                TextStyle(color: Colors.white70, fontSize: 10),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Để kết nối thiết bị SmartAir mới:',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.black54),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _idCtrl,
              decoration: const InputDecoration(
                labelText: 'Mã thiết bị (Device ID)',
                hintText: 'Ví dụ: SA-004',
                prefixIcon: Icon(Icons.qr_code),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Tên thiết bị (Tùy chọn)',
                hintText: 'Ví dụ: Phòng ngủ',
                prefixIcon: Icon(Icons.edit),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: _location,
              decoration: const InputDecoration(
                  labelText: 'Vị trí đặt', border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(
                    value: 'indoor', child: Text('Trong nhà (Indoor)')),
                DropdownMenuItem(
                    value: 'outdoor', child: Text('Ngoài trời (Outdoor)')),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _location = val);
              },
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!,
                  style: const TextStyle(
                      color: Colors.red,
                      fontSize: 12,
                      fontWeight: FontWeight.bold)),
            ]
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        FilledButton(
          onPressed: _loading ? null : _submit,
          child: _loading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2))
              : const Text('Kết nối'),
        ),
      ],
    );
  }
}

// Custom Painter to draw a simulated QR code layout
class _MockQrPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    // Outer corner finder patterns
    _drawFinderPattern(canvas, const Offset(0, 0), size.width * 0.28, paint);
    _drawFinderPattern(
        canvas, Offset(size.width * 0.72, 0), size.width * 0.28, paint);
    _drawFinderPattern(
        canvas, Offset(0, size.height * 0.72), size.width * 0.28, paint);

    // Some simulated noise blocks
    final rand = math.Random(42);
    final blockWidth = size.width / 12;
    for (int i = 0; i < 12; i++) {
      for (int j = 0; j < 12; j++) {
        // Skip finder areas
        if ((i < 4 && j < 4) || (i > 7 && j < 4) || (i < 4 && j > 7)) continue;
        if (rand.nextBool()) {
          canvas.drawRect(
            Rect.fromLTWH(i * blockWidth, j * blockWidth, blockWidth - 0.5,
                blockWidth - 0.5),
            paint,
          );
        }
      }
    }
  }

  void _drawFinderPattern(
      Canvas canvas, Offset offset, double size, Paint paint) {
    // Outer square
    canvas.drawRect(Rect.fromLTWH(offset.dx, offset.dy, size, size), paint);
    // Inner white square
    final whitePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawRect(
        Rect.fromLTWH(offset.dx + size / 6, offset.dy + size / 6, size * 2 / 3,
            size * 2 / 3),
        whitePaint);
    // Inner black square
    canvas.drawRect(
        Rect.fromLTWH(offset.dx + size * 2 / 6, offset.dy + size * 2 / 6,
            size * 2 / 6, size * 2 / 6),
        paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
