import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class WifiProvisioningDialog extends StatefulWidget {
  final String deviceId;
  final String? initialIp;
  final String? currentSsid;

  const WifiProvisioningDialog({
    super.key,
    required this.deviceId,
    this.initialIp,
    this.currentSsid,
  });

  @override
  State<WifiProvisioningDialog> createState() => _WifiProvisioningDialogState();
}

class _WifiProvisioningDialogState extends State<WifiProvisioningDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final _ssidCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _ipCtrl = TextEditingController();

  bool _obscurePass = true;
  bool _isSending = false;
  bool _isScanning = false;
  String? _statusMessage;
  bool _isSuccess = false;
  String? _scanSource;
  String? _currentConnectedSsid;

  // Danh sách các mạng Wi-Fi thực tế quét được từ ESP32
  List<Map<String, dynamic>> _wifiList = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    if (widget.currentSsid != null && widget.currentSsid!.isNotEmpty) {
      _currentConnectedSsid = widget.currentSsid;
      _ssidCtrl.text = widget.currentSsid!;
    }
    if (widget.initialIp != null && widget.initialIp!.isNotEmpty) {
      _ipCtrl.text = widget.initialIp!;
    }
    _initDataAndScan();
  }

  Future<void> _initDataAndScan() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedSsid = prefs.getString('device_wifi_ssid_${widget.deviceId}');
      final savedIp = prefs.getString('device_ip_${widget.deviceId}');

      if (_ssidCtrl.text.isEmpty && savedSsid != null && savedSsid.isNotEmpty) {
        _ssidCtrl.text = savedSsid;
        _currentConnectedSsid ??= savedSsid;
      }
      if (_ipCtrl.text.isEmpty && savedIp != null && savedIp.isNotEmpty) {
        _ipCtrl.text = savedIp;
      }

      // Lấy thông tin real-time mới nhất từ Backend (bao gồm wifi_ssid và dev_ip của ESP32)
      final realtime = await ApiService().getRealtimeReading(widget.deviceId);
      if (realtime != null && mounted) {
        final serverSsid = realtime['wifi_ssid'] as String?;
        final serverIp = realtime['dev_ip'] as String? ?? realtime['ip_address'] as String?;
        if (serverSsid != null && serverSsid.isNotEmpty) {
          _currentConnectedSsid = serverSsid;
          if (_ssidCtrl.text.isEmpty) {
            _ssidCtrl.text = serverSsid;
          }
        }
        if (serverIp != null && serverIp.isNotEmpty && _ipCtrl.text.isEmpty) {
          _ipCtrl.text = serverIp;
        }
      }
    } catch (_) {}

    if (mounted) {
      _scanAvailableWifi();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _ssidCtrl.dispose();
    _passCtrl.dispose();
    _ipCtrl.dispose();
    super.dispose();
  }

  String _getRssiLabel(int rssi) {
    if (rssi >= -60) return 'Rất mạnh';
    if (rssi >= -72) return 'Mạnh';
    if (rssi >= -84) return 'Trung bình';
    return 'Yếu';
  }

  IconData _getRssiIcon(int rssi) {
    if (rssi >= -65) return Icons.wifi;
    if (rssi >= -80) return Icons.network_wifi;
    return Icons.wifi_1_bar;
  }

  // Quét danh sách Wi-Fi thực tế từ ESP32 (qua IP nội bộ hoặc Hotspot 192.168.4.1)
  Future<void> _scanAvailableWifi() async {
    if (_isScanning) return;

    setState(() {
      _isScanning = true;
      _statusMessage = null;
      _scanSource = null;
    });

    List<Map<String, dynamic>> scannedList = [];
    String? matchedSource;

    // Danh sách các địa chỉ IP của ESP32 để kết nối
    final candidateIps = <String>[];
    final customIp = _ipCtrl.text.trim();
    if (customIp.isNotEmpty) {
      candidateIps.add(customIp);
    }
    if (!candidateIps.contains('192.168.4.1')) {
      candidateIps.add('192.168.4.1');
    }

    // Thử gửi lệnh quét tới từng IP của ESP32
    for (final ip in candidateIps) {
      // 1. Thử endpoint JSON trực tiếp: http://<ip>/wifi-scan (do ESP32 firmware xử lý)
      try {
        final res = await http
            .get(Uri.parse('http://$ip/wifi-scan'))
            .timeout(const Duration(seconds: 4));

        if (res.statusCode == 200 && res.body.trim().startsWith('[')) {
          final dynamic decoded = jsonDecode(res.body);
          if (decoded is List) {
            for (final item in decoded) {
              if (item is Map<String, dynamic>) {
                final ssid = (item['ssid'] ?? '').toString().trim();
                if (ssid.isEmpty) continue;
                final rssi = (item['rssi'] as num?)?.toInt() ?? -70;
                final isSecure = item['secure'] == true;
                final isCurrent = (ssid == _currentConnectedSsid);

                // Tránh trùng lặp SSID
                if (!scannedList.any((e) => e['ssid'] == ssid)) {
                  scannedList.add({
                    'ssid': ssid,
                    'rssi': rssi,
                    'signal': _getRssiLabel(rssi),
                    'isSecure': isSecure,
                    'isConnected': isCurrent,
                  });
                }
              }
            }
            if (scannedList.isNotEmpty) {
              matchedSource = 'Sóng thực tế từ ESP32 ($ip)';
              break;
            }
          }
        }
      } catch (_) {}

      // 2. Thử endpoint WiFiManager AP mode: http://<ip>/wifi (HTML parsing)
      if (scannedList.isEmpty) {
        try {
          final res = await http
              .get(Uri.parse('http://$ip/wifi'))
              .timeout(const Duration(seconds: 4));

          if (res.statusCode == 200) {
            final matches = RegExp(r"<div><a[^>]*>([^<]+)</a>")
                .allMatches(res.body)
                .map((m) => (m.group(1) ?? '').trim())
                .where((s) => s.isNotEmpty)
                .toSet();

            for (final ssid in matches) {
              if (!scannedList.any((e) => e['ssid'] == ssid)) {
                scannedList.add({
                  'ssid': ssid,
                  'rssi': -65,
                  'signal': 'Tốt',
                  'isSecure': true,
                  'isConnected': ssid == _currentConnectedSsid,
                });
              }
            }
            if (scannedList.isNotEmpty) {
              matchedSource = 'WiFiManager AP ($ip)';
              break;
            }
          }
        } catch (_) {}
      }
    }

    // Nếu tìm thấy mạng từ ESP32:
    if (scannedList.isNotEmpty) {
      // Đưa mạng đang kết nối lên đầu, còn lại sắp theo độ mạnh sóng RSSI
      scannedList.sort((a, b) {
        if (a['isConnected'] == true) return -1;
        if (b['isConnected'] == true) return 1;
        return (b['rssi'] as int? ?? -100).compareTo(a['rssi'] as int? ?? -100);
      });
    } else {
      // NẾU KHÔNG KẾT NỐI ĐƯỢC TỚI ESP32 QUA IP:
      // Xóa bỏ hoàn toàn mạng giả lập! Chỉ hiển thị mạng thực tế ESP32 đang sử dụng (nếu đã lưu từ server)
      if (_currentConnectedSsid != null && _currentConnectedSsid!.isNotEmpty) {
        scannedList.add({
          'ssid': _currentConnectedSsid!,
          'rssi': -50,
          'signal': 'Đang kết nối',
          'isSecure': true,
          'isConnected': true,
        });
        matchedSource = 'Dữ liệu thiết bị ghi nhận gần nhất';
      }
    }

    if (mounted) {
      setState(() {
        _wifiList = scannedList;
        _isScanning = false;
        _scanSource = matchedSource;
      });
    }
  }

  // Gửi thông tin Wi-Fi đến ESP32
  Future<void> _sendWifiToEsp() async {
    final ssid = _ssidCtrl.text.trim();
    final pass = _passCtrl.text.trim();

    if (ssid.isEmpty) {
      setState(() {
        _statusMessage = 'Vui lòng chọn hoặc nhập tên Wi-Fi!';
        _isSuccess = false;
      });
      return;
    }

    setState(() {
      _isSending = true;
      _statusMessage = 'Đang chuyển giao cấu hình đến ESP32...';
      _isSuccess = false;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('device_wifi_ssid_${widget.deviceId}', ssid);
      if (_ipCtrl.text.trim().isNotEmpty) {
        await prefs.setString(
            'device_ip_${widget.deviceId}', _ipCtrl.text.trim());
      }
    } catch (_) {}

    final candidateIps = <String>[];
    final customIp = _ipCtrl.text.trim();
    if (customIp.isNotEmpty) candidateIps.add(customIp);
    if (!candidateIps.contains('192.168.4.1')) candidateIps.add('192.168.4.1');

    bool sentSuccessfully = false;

    for (final ip in candidateIps) {
      // Thử endpoint /wifi-save của WebServer
      try {
        final res = await http.post(
          Uri.parse('http://$ip/wifi-save'),
          headers: {'Content-Type': 'application/x-www-form-urlencoded'},
          body: {'s': ssid, 'p': pass, 'ssid': ssid, 'password': pass},
        ).timeout(const Duration(seconds: 5));

        if (res.statusCode == 200 || res.statusCode == 302) {
          sentSuccessfully = true;
          break;
        }
      } catch (_) {}

      // Thử endpoint /wifisave của WiFiManager
      try {
        final res = await http.post(
          Uri.parse('http://$ip/wifisave'),
          headers: {'Content-Type': 'application/x-www-form-urlencoded'},
          body: {'s': ssid, 'p': pass},
        ).timeout(const Duration(seconds: 5));

        if (res.statusCode == 200 || res.statusCode == 302) {
          sentSuccessfully = true;
          break;
        }
      } catch (_) {}
    }

    if (mounted) {
      setState(() {
        _isSending = false;
        if (sentSuccessfully) {
          _isSuccess = true;
          _statusMessage =
              '🎉 Cấu hình thành công! ESP32 đang lưu và kết nối vào "$ssid".';
        } else {
          _isSuccess = false;
          _statusMessage = '⚠️ Chưa nhận được phản hồi trực tiếp từ ESP32.\n'
              '👉 Hãy chuyển Wi-Fi điện thoại sang mạng "SmartAir-Setup" (hoặc đảm bảo điện thoại cùng mạng Wi-Fi với ESP32) rồi bấm Lưu lại nhé!';
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 8,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 440),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: Colors.white,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header gradient cao cấp
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF00796B), Color(0xFF004D40)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.wifi_find,
                        color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Quản Lý Wi-Fi Thiết Bị ESP32',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Thiết bị: ${widget.deviceId} • Sóng thực tế xung quanh',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close,
                        color: Colors.white70, size: 22),
                    onPressed: () => Navigator.pop(context),
                  )
                ],
              ),
            ),

            // Tab bar
            TabBar(
              controller: _tabController,
              labelColor: const Color(0xFF00796B),
              unselectedLabelColor: Colors.grey.shade600,
              indicatorColor: const Color(0xFF00796B),
              indicatorWeight: 3,
              labelStyle:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              tabs: const [
                Tab(
                    icon: Icon(Icons.network_check, size: 18),
                    text: 'Mạng Gần ESP32'),
                Tab(
                    icon: Icon(Icons.touch_app, size: 18),
                    text: 'Cách Nối Mới (Hotspot)'),
              ],
            ),

            // Tab View
            SizedBox(
              height: 440,
              child: TabBarView(
                controller: _tabController,
                children: [
                  // TAB 1: Danh sách Wi-Fi & Form kết nối
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Wi-Fi xung quanh ESP32:',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        color: Colors.black87),
                                  ),
                                  if (_scanSource != null)
                                    Text(
                                      _scanSource!,
                                      style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.teal.shade700,
                                          fontStyle: FontStyle.italic),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                ],
                              ),
                            ),
                            InkWell(
                              onTap: _isScanning ? null : _scanAvailableWifi,
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.teal.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                      color: Colors.teal.shade200, width: 0.8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _isScanning
                                        ? const SizedBox(
                                            width: 12,
                                            height: 12,
                                            child: CircularProgressIndicator(
                                                strokeWidth: 2))
                                        : const Icon(Icons.refresh,
                                            size: 14, color: Colors.teal),
                                    const SizedBox(width: 4),
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        _isScanning
                                            ? 'Đang dò sóng...'
                                            : 'Quét lại',
                                        maxLines: 1,
                                        style: const TextStyle(
                                            fontSize: 11,
                                            color: Colors.teal,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Danh sách cuộn chọn Wi-Fi
                        Container(
                          height: 125,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: _isScanning
                              ? Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            color: Colors.teal),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'ESP32 đang quét sóng 2.4GHz lân cận...',
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey.shade700),
                                      ),
                                    ],
                                  ),
                                )
                              : _wifiList.isEmpty
                                  ? Center(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.wifi_off,
                                                color: Colors.grey.shade400,
                                                size: 26),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Chưa nhận được danh sách sóng từ ESP32.\nHãy kết nối vào "SmartAir-Setup" hoặc nhập tên Wi-Fi bên dưới.',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.grey.shade600),
                                            ),
                                          ],
                                        ),
                                      ),
                                    )
                                  : ListView.separated(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 2),
                                      itemCount: _wifiList.length,
                                      separatorBuilder: (_, __) => Divider(
                                          height: 1,
                                          color: Colors.grey.shade200),
                                      itemBuilder: (context, index) {
                                        final item = _wifiList[index];
                                        final isSelected =
                                            _ssidCtrl.text == item['ssid'];
                                        final isConnected =
                                            item['isConnected'] == true;
                                        final rssi = item['rssi'] as int? ?? -70;

                                        return ListTile(
                                          dense: true,
                                          visualDensity: VisualDensity.compact,
                                          leading: Icon(
                                            _getRssiIcon(rssi),
                                            size: 18,
                                            color: isConnected
                                                ? Colors.green.shade700
                                                : (isSelected
                                                    ? Colors.teal
                                                    : Colors.grey.shade600),
                                          ),
                                          title: Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  item['ssid'] as String,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: (isSelected ||
                                                            isConnected)
                                                        ? FontWeight.bold
                                                        : FontWeight.normal,
                                                    color: isConnected
                                                        ? Colors.green.shade900
                                                        : (isSelected
                                                            ? Colors
                                                                .teal.shade900
                                                            : Colors.black87),
                                                  ),
                                                ),
                                              ),
                                              if (isConnected) ...[
                                                const SizedBox(width: 4),
                                                Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 5,
                                                      vertical: 1),
                                                  decoration: BoxDecoration(
                                                    color:
                                                        Colors.green.shade100,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            4),
                                                  ),
                                                  child: Text(
                                                    'Đang kết nối',
                                                    style: TextStyle(
                                                        fontSize: 9,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Colors
                                                            .green.shade800),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                          trailing: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              if (item['isSecure'] == true)
                                                const Icon(Icons.lock,
                                                    size: 12,
                                                    color: Colors.grey),
                                              const SizedBox(width: 4),
                                              Text(
                                                item['signal'] as String? ?? '',
                                                style: TextStyle(
                                                    fontSize: 10,
                                                    color:
                                                        Colors.grey.shade600),
                                              ),
                                            ],
                                          ),
                                          selected: isSelected,
                                          selectedTileColor:
                                              Colors.teal.shade50,
                                          onTap: () {
                                            setState(() {
                                              _ssidCtrl.text =
                                                  item['ssid'] as String;
                                            });
                                          },
                                        );
                                      },
                                    ),
                        ),
                        const SizedBox(height: 10),

                        // Ô tên Wi-Fi
                        TextField(
                          controller: _ssidCtrl,
                          decoration: InputDecoration(
                            labelText: 'Tên Wi-Fi (SSID)',
                            hintText: 'Bấm mạng ở trên hoặc tự nhập tên',
                            prefixIcon: const Icon(Icons.wifi,
                                size: 18, color: Colors.teal),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10)),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 8),
                            isDense: true,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Ô mật khẩu
                        TextField(
                          controller: _passCtrl,
                          obscureText: _obscurePass,
                          decoration: InputDecoration(
                            labelText: 'Mật khẩu Wi-Fi',
                            prefixIcon: const Icon(Icons.lock_outline,
                                size: 18, color: Colors.teal),
                            suffixIcon: IconButton(
                              icon: Icon(
                                  _obscurePass
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  size: 16),
                              onPressed: () =>
                                  setState(() => _obscurePass = !_obscurePass),
                            ),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10)),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 8),
                            isDense: true,
                          ),
                        ),
                        const SizedBox(height: 8),

                        if (_statusMessage != null) ...[
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: _isSuccess
                                  ? Colors.green.shade50
                                  : Colors.red.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: _isSuccess
                                      ? Colors.green.shade300
                                      : Colors.red.shade300),
                            ),
                            child: Text(
                              _statusMessage!,
                              style: TextStyle(
                                fontSize: 11,
                                color: _isSuccess
                                    ? Colors.green.shade800
                                    : Colors.red.shade800,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],

                        const Spacer(),

                        // Nút Gửi cấu hình bảo vệ chữ với FittedBox
                        SizedBox(
                          width: double.infinity,
                          height: 42,
                          child: ElevatedButton.icon(
                            onPressed: _isSending ? null : _sendWifiToEsp,
                            icon: _isSending
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white))
                                : const Icon(Icons.send_rounded, size: 18),
                            label: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                _isSending
                                    ? 'ĐANG GỬI CẤU HÌNH ĐẾN ESP32...'
                                    : 'LƯU & KẾT NỐI CHO ESP32',
                                maxLines: 1,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00796B),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // TAB 2: Hướng dẫn kết nối khi chưa có Wi-Fi
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.teal.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.teal.shade200),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.hub_outlined,
                                  color: Colors.teal, size: 22),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Cơ chế kết nối trực tiếp (Hotspot) giữa App và bo mạch ESP32.',
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF004D40)),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildStepCard(
                          step: '1',
                          title: 'Cắm nguồn ESP32',
                          desc:
                              'Khi đổi vị trí mới hoặc mất Wi-Fi cũ, mạch tự động phát Wi-Fi AP tên: "SmartAir-Setup".',
                          icon: Icons.power,
                        ),
                        const SizedBox(height: 8),
                        _buildStepCard(
                          step: '2',
                          title: 'Bắt Wi-Fi "SmartAir-Setup"',
                          desc:
                              'Vào Cài đặt Wi-Fi trên điện thoại, kết nối vào mạng "SmartAir-Setup" (không cần mật khẩu).',
                          icon: Icons.wifi_tethering,
                        ),
                        const SizedBox(height: 8),
                        _buildStepCard(
                          step: '3',
                          title: 'Chọn Wi-Fi & Bấm Lưu',
                          desc:
                              'Trở lại màn hình này, bấm "Quét lại" để thấy toàn bộ các Wi-Fi quanh ESP32, chọn mạng nhà bạn và bấm Lưu.',
                          icon: Icons.check_circle_outline,
                        ),
                        const SizedBox(height: 12),

                        // Cấu hình nâng cao IP
                        Theme(
                          data: Theme.of(context)
                              .copyWith(dividerColor: Colors.transparent),
                          child: ExpansionTile(
                            tilePadding: EdgeInsets.zero,
                            title: Text(
                              'Cấu hình IP nâng cao (tùy chọn)',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade700),
                            ),
                            children: [
                              TextField(
                                controller: _ipCtrl,
                                decoration: InputDecoration(
                                  labelText: 'Địa chỉ IP của ESP32',
                                  hintText: '192.168.1.47 hoặc 192.168.4.1',
                                  prefixIcon: const Icon(Icons.settings_ethernet,
                                      size: 16),
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8)),
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 6),
                                  isDense: true,
                                ),
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepCard(
      {required String step,
      required String title,
      required String desc,
      required IconData icon}) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 11,
            backgroundColor: const Color(0xFF00796B),
            child: Text(step,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 14, color: Colors.teal.shade800),
                    const SizedBox(width: 4),
                    Text(title,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: Colors.black87)),
                  ],
                ),
                const SizedBox(height: 2),
                Text(desc,
                    style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade700,
                        height: 1.3)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
