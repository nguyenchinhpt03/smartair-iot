import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Thay YOUR_VPS_IP bằng IP thật của VPS khi deploy
  static const String _base = 'http://10.0.2.2:3000/api';
  static const Duration _timeout = Duration(seconds: 10);
  static const Duration _aiTimeout = Duration(seconds: 20);

  // Helper để lấy Base URL động dựa trên SharedPreferences hoặc IP thiết bị
  Future<String> _getBaseUrl([String? deviceId]) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final customServer = prefs.getString('custom_server_url');
      if (customServer != null && customServer.trim().isNotEmpty) {
        String ip = customServer.trim();
        if (!ip.startsWith('http://') && !ip.startsWith('https://')) {
          ip = 'http://$ip';
        }
        if (!ip.endsWith('/api')) {
          ip = '$ip/api';
        }
        return ip;
      }
      if (deviceId != null) {
        final customIp = prefs.getString('device_ip_$deviceId');
        if (customIp != null && customIp.trim().isNotEmpty) {
          String ip = customIp.trim();
          if (!ip.startsWith('http://') && !ip.startsWith('https://')) {
            if (!ip.contains(':')) {
              ip = '$ip:3000';
            }
            ip = 'http://$ip';
          }
          return '$ip/api';
        }
      }
    } catch (_) {}
    return _base;
  }

  // ── Lớp 1: Dữ liệu real-time mới nhất ──────────────────────────
  Future<Map<String, dynamic>?> getRealtimeReading(String deviceId) async {
    try {
      final base = await _getBaseUrl(deviceId);
      final res = await http
          .get(Uri.parse('$base/realtime/$deviceId'))
          .timeout(_timeout);
      if (res.statusCode == 200) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  // ── Lớp 2: Lịch sử thô theo ngày (biểu đồ 24h) ─────────────────
  Future<List<dynamic>> getHistory(String deviceId,
      {required String date}) async {
    try {
      final base = await _getBaseUrl(deviceId);
      final res = await http
          .get(Uri.parse('$base/history/$deviceId?date=$date'))
          .timeout(_timeout);
      if (res.statusCode == 200) return jsonDecode(res.body) as List;
    } catch (_) {}
    return [];
  }

  // ── Lớp 3: Trung bình theo giờ (biểu đồ 7 ngày) ─────────────────
  Future<List<dynamic>> getHourly(String deviceId, {int days = 7}) async {
    try {
      final base = await _getBaseUrl(deviceId);
      final res = await http
          .get(Uri.parse('$base/hourly/$deviceId?days=$days'))
          .timeout(_timeout);
      if (res.statusCode == 200) return jsonDecode(res.body) as List;
    } catch (_) {}
    return [];
  }

  // ── Lớp 4: Báo cáo AI ngày ──────────────────────────────────────
  Future<List<dynamic>> getDailyReports(String deviceId) async {
    try {
      final base = await _getBaseUrl(deviceId);
      final res =
          await http.get(Uri.parse('$base/daily/$deviceId')).timeout(_timeout);
      if (res.statusCode == 200) return jsonDecode(res.body) as List;
    } catch (_) {}
    return [];
  }

  // ── Chatbox AI ───────────────────────────────────────────────────
  Future<String> chat(String deviceId, String question) async {
    try {
      final base = await _getBaseUrl(deviceId);
      final res = await http
          .post(
            Uri.parse('$base/chat'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'device_id': deviceId, 'question': question}),
          )
          .timeout(_aiTimeout);
      if (res.statusCode == 200) {
        return (jsonDecode(res.body) as Map)['answer'] as String;
      }
    } catch (_) {}
    return 'Không thể kết nối AI. Vui lòng thử lại.';
  }

  // ── Đăng ký thiết bị qua QR ──────────────────────────────────────
  Future<Map<String, dynamic>?> registerDevice({
    required String qrCode,
    String email = '',
    String fcmToken = '',
    int? userId,
  }) async {
    try {
      final base = await _getBaseUrl();
      final res = await http
          .post(
            Uri.parse('$base/device/register'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'qr_code': qrCode,
              'user_email': email,
              'fcm_token': fcmToken,
              if (userId != null) 'user_id': userId,
            }),
          )
          .timeout(_timeout);
      if (res.statusCode == 200) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  // ── Đăng nhập tài khoản ──────────────────────────────────────────
  Future<Map<String, dynamic>?> login({
    required String username,
    required String password,
  }) async {
    try {
      final base = await _getBaseUrl();
      final res = await http
          .post(
            Uri.parse('$base/auth/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'username': username,
              'password': password,
            }),
          )
          .timeout(_timeout);
      if (res.statusCode == 200) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      } else {
        final body = jsonDecode(res.body) as Map;
        return {'error': body['error'] ?? 'Đăng nhập thất bại'};
      }
    } catch (_) {}
    return {'error': 'Không thể kết nối tới máy chủ'};
  }

  // ── Đăng ký tài khoản ───────────────────────────────────────────
  Future<Map<String, dynamic>?> register({
    required String username,
    required String password,
    String email = '',
  }) async {
    try {
      final base = await _getBaseUrl();
      final res = await http
          .post(
            Uri.parse('$base/auth/register'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'username': username,
              'password': password,
              'email': email,
            }),
          )
          .timeout(_timeout);
      if (res.statusCode == 200) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      } else {
        final body = jsonDecode(res.body) as Map;
        return {'error': body['error'] ?? 'Đăng ký thất bại'};
      }
    } catch (_) {}
    return {'error': 'Không thể kết nối tới máy chủ'};
  }

  // ── Lấy ngưỡng cảnh báo ──────────────────────────────────────────
  Future<Map<String, dynamic>> getAlertSettings(
      String deviceId, int userId) async {
    try {
      final base = await _getBaseUrl(deviceId);
      final res = await http
          .get(Uri.parse('$base/alert-settings/$deviceId?user_id=$userId'))
          .timeout(_timeout);
      if (res.statusCode == 200) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return {};
  }

  // ── Cập nhật ngưỡng cảnh báo ─────────────────────────────────────
  Future<bool> updateAlertSettings(
      String deviceId, int userId, Map<String, dynamic> settings) async {
    try {
      final base = await _getBaseUrl(deviceId);
      final res = await http
          .put(
            Uri.parse('$base/alert-settings/$deviceId'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'user_id': userId, ...settings}),
          )
          .timeout(_timeout);
      return res.statusCode == 200;
    } catch (_) {}
    return false;
  }

  // ── Cập nhật FCM token ────────────────────────────────────────────
  Future<void> updateFcmToken(int userId, String fcmToken) async {
    try {
      await http
          .put(
            Uri.parse('$_base/user/fcm-token'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'user_id': userId, 'fcm_token': fcmToken}),
          )
          .timeout(_timeout);
    } catch (_) {}
  }

  // ── Lấy thông tin user (bao gồm fcm_enabled) ──────────────────────
  Future<Map<String, dynamic>?> getUserInfo(int userId) async {
    try {
      final res =
          await http.get(Uri.parse('$_base/user/$userId')).timeout(_timeout);
      if (res.statusCode == 200) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  // ── Lấy thông tin thiết bị ───────────────────────────────────────
  Future<Map<String, dynamic>?> getDeviceInfo(String deviceId) async {
    try {
      final res = await http
          .get(Uri.parse('$_base/device/$deviceId'))
          .timeout(_timeout);
      if (res.statusCode == 200) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  // ── Bật/tắt thông báo đẩy (FCM) ──────────────────────────────────
  Future<bool> updateFcmEnabled(int userId, bool enabled) async {
    try {
      final res = await http
          .put(
            Uri.parse('$_base/user/fcm-enabled'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'user_id': userId, 'fcm_enabled': enabled}),
          )
          .timeout(_timeout);
      return res.statusCode == 200;
    } catch (_) {}
    return false;
  }

  // ── Lấy lịch sử thông báo đã nhận ────────────────────────────────
  Future<List<dynamic>> getNotifications(int userId) async {
    try {
      final res = await http
          .get(Uri.parse('$_base/user/notifications/$userId'))
          .timeout(_timeout);
      if (res.statusCode == 200) {
        return jsonDecode(res.body) as List;
      }
    } catch (_) {}
    return [];
  }

  // ── Thiết bị: Sinh mật khẩu tạm để chia sẻ ────────────────────────
  Future<Map<String, dynamic>?> generateShareCode(String deviceId) async {
    try {
      final res = await http
          .post(Uri.parse('$_base/device/$deviceId/share'))
          .timeout(_timeout);
      if (res.statusCode == 200) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  // ── Thiết bị: Liên kết SĐT & Đổi mật khẩu mới (Setup Owner/Share) ──
  Future<Map<String, dynamic>?> setupDeviceOwner({
    required String deviceId,
    required String phone,
    required String password,
  }) async {
    try {
      final res = await http
          .post(
            Uri.parse('$_base/device/setup-owner'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'device_id': deviceId,
              'phone': phone,
              'password': password,
            }),
          )
          .timeout(_timeout);
      if (res.statusCode == 200) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      } else {
        final body = jsonDecode(res.body) as Map;
        return {'error': body['error'] ?? 'Thiết lập thất bại'};
      }
    } catch (_) {}
    return {'error': 'Không thể kết nối tới máy chủ'};
  }

  // ── Thiết bị: Lấy danh sách thiết bị của User ─────────────────────
  Future<List<dynamic>> getUserDevices(int userId) async {
    try {
      final res = await http
          .get(Uri.parse('$_base/devices/user/$userId'))
          .timeout(_timeout);
      if (res.statusCode == 200) {
        return jsonDecode(res.body) as List;
      }
    } catch (_) {}
    return [];
  }

  // ── Thiết bị: Thêm thiết bị thủ công ──────────────────────────────
  Future<Map<String, dynamic>?> addDevice({
    required String deviceId,
    required String name,
    required String location,
    String? ipAddress,
    required int userId,
  }) async {
    try {
      final res = await http
          .post(
            Uri.parse('$_base/device/add'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'device_id': deviceId,
              'name': name,
              'location': location,
              'ip_address': ipAddress,
              'user_id': userId,
            }),
          )
          .timeout(_timeout);
      if (res.statusCode == 200) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      } else {
        final body = jsonDecode(res.body) as Map;
        return {'error': body['error'] ?? 'Thêm thiết bị thất bại'};
      }
    } catch (_) {}
    return {'error': 'Không thể kết nối tới máy chủ'};
  }

  // ── Thiết bị: Cập nhật thiết bị ───────────────────────────────────
  Future<bool> updateDevice({
    required String deviceId,
    String? name,
    String? location,
    String? ipAddress,
  }) async {
    try {
      final res = await http
          .put(
            Uri.parse('$_base/device/$deviceId'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              if (name != null) 'name': name,
              if (location != null) 'location': location,
              if (ipAddress != null) 'ip_address': ipAddress,
            }),
          )
          .timeout(_timeout);
      return res.statusCode == 200;
    } catch (_) {}
    return false;
  }

  // ── Thiết bị: Hủy liên kết thiết bị ──────────────────────────────
  Future<bool> unlinkDevice({
    required String deviceId,
    required int userId,
  }) async {
    try {
      final res = await http
          .delete(Uri.parse('$_base/device/$deviceId/user/$userId'))
          .timeout(_timeout);
      return res.statusCode == 200;
    } catch (_) {}
    return false;
  }
}
