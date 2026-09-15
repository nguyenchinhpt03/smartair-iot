import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../widgets/wifi_provisioning_dialog.dart';
import 'login_screen.dart';

class SettingsScreen extends StatefulWidget {
  final String deviceId;
  final int userId;
  const SettingsScreen(
      {super.key, required this.deviceId, required this.userId});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _ctrl = <String, TextEditingController>{};
  bool _loading = true;
  bool _saving = false;
  bool _fcmEnabled = true;

  final _nameController = TextEditingController();
  String _location = 'indoor';

  static const _fields = [
    {'key': 'aqi', 'label': 'Ngưỡng AQI', 'hint': 'ví dụ: 100'},
    {'key': 'co2_ppm', 'label': 'Ngưỡng CO₂ (ppm)', 'hint': 'ví dụ: 1000'},
    {'key': 'co_ppm', 'label': 'Ngưỡng CO (ppm)', 'hint': 'ví dụ: 9'},
    {'key': 'pm25_ugm3', 'label': 'Ngưỡng PM2.5 (µg/m³)', 'hint': 'ví dụ: 35'},
    {'key': 'nh3_ppm', 'label': 'Ngưỡng NH₃ (ppm)', 'hint': 'ví dụ: 25'},
  ];

  @override
  void initState() {
    super.initState();
    for (final f in _fields) _ctrl[f['key']!] = TextEditingController();
    _loadSettings();
  }

  @override
  void dispose() {
    _nameController.dispose();
    for (final c in _ctrl.values) c.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final api = ApiService();
    final results = await Future.wait([
      api.getAlertSettings(widget.deviceId, widget.userId),
      api.getUserInfo(widget.userId),
      api.getDeviceInfo(widget.deviceId),
    ]);
    final settings = results[0] as Map<String, dynamic>;
    final userInfo = results[1] as Map<String, dynamic>?;
    final deviceInfo = results[2] as Map<String, dynamic>?;

    for (final f in _fields) {
      final val = settings[f['key']!];
      if (val != null) _ctrl[f['key']!]!.text = val.toString();
    }

    if (userInfo != null) {
      _fcmEnabled = userInfo['fcm_enabled'] as bool? ?? true;
    }

    if (deviceInfo != null) {
      _nameController.text = deviceInfo['name'] ?? '';
      _location = deviceInfo['location'] ?? 'indoor';
    }

    if (mounted) setState(() => _loading = false);
  }

  Future<void> _toggleFcm(bool value) async {
    setState(() {
      _fcmEnabled = value;
    });
    final ok = await ApiService().updateFcmEnabled(widget.userId, value);
    if (!ok && mounted) {
      // Revert if failed
      setState(() {
        _fcmEnabled = !value;
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Không thể cập nhật trạng thái thông báo đẩy'),
        backgroundColor: Colors.red,
      ));
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final devName = _nameController.text.trim();
    final devOk = await ApiService().updateDevice(
      deviceId: widget.deviceId,
      name: devName.isEmpty ? 'SmartAir Device' : devName,
      location: _location,
    );

    final settings = <String, dynamic>{};
    for (final f in _fields) {
      final text = _ctrl[f['key']!]!.text.trim();
      if (text.isNotEmpty) settings[f['key']!] = double.parse(text);
    }

    final ok = await ApiService()
        .updateAlertSettings(widget.deviceId, widget.userId, settings);
    if (!mounted) return;

    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text((ok && devOk)
          ? 'Đã lưu cài đặt'
          : 'Lưu thất bại — kiểm tra kết nối mạng'),
      backgroundColor: (ok && devOk) ? Colors.green : Colors.red,
    ));
  }

  Future<void> _shareDevice() async {
    setState(() => _saving = true);
    final res = await ApiService().generateShareCode(widget.deviceId);
    setState(() => _saving = false);

    if (res == null || !res.containsKey('temp_password')) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Không thể lấy mật khẩu tạm thời lúc này.'),
          backgroundColor: Colors.red,
        ));
      }
      return;
    }

    final tempPassword = res['temp_password'] as String;

    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: const [
              Icon(Icons.share, color: Colors.indigo),
              SizedBox(width: 8),
              Text('Chia sẻ thiết bị',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                  'Để người khác truy cập thiết bị này, hãy gửi cho họ thông tin sau:'),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.indigo.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.indigo.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Mã thiết bị: ${widget.deviceId}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 6),
                    Text('Mật khẩu tạm: $tempPassword',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.indigo)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Lưu ý: Mật khẩu tạm này chỉ dùng được 1 lần. Sau khi đăng nhập thành công, người được chia sẻ sẽ tự tạo tài khoản riêng của họ.',
                style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 11,
                    fontStyle: FontStyle.italic),
              ),
            ],
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Đóng'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Đăng xuất'),
        content: const Text('Bạn muốn quét QR thiết bị khác?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Huỷ')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Đăng xuất')),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cài đặt ngưỡng cảnh báo')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Device info
                  ListTile(
                    leading: const Icon(Icons.sensors),
                    title: Text('Thiết bị: ${widget.deviceId}'),
                    subtitle: Text('User ID: ${widget.userId}'),
                    tileColor: Colors.teal.shade50,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  const SizedBox(height: 12),

                  // ── QUẢN LÝ WI-FI THIẾT BỊ ──────────────────────────
                  Card(
                    elevation: 0,
                    color: Colors.teal.shade50,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.teal.shade200, width: 1),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.network_wifi,
                                  color: Colors.teal.shade700, size: 22),
                              const SizedBox(width: 8),
                              Text(
                                'Quản Lý Wi-Fi Thiết Bị',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: Colors.teal.shade800,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Kết nối Wi-Fi mới, đổi mạng khi chuyển địa điểm — ngay trong App, không cần vào trình duyệt.',
                            style: TextStyle(
                                fontSize: 12, color: Colors.teal.shade700),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.wifi_find),
                              label: const FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text('Mở Trình Quản Lý Wi-Fi',
                                    maxLines: 1),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.teal,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (_) => WifiProvisioningDialog(
                                      deviceId: widget.deviceId),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Cấu hình Tên & Vị trí đặt
                  const Text('Thông tin thiết bị:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Tên thiết bị',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.edit_note),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty)
                        return 'Tên thiết bị không được để trống';
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    value: _location,
                    decoration: const InputDecoration(
                      labelText: 'Vị trí đặt',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.location_on),
                    ),
                    items: const [
                      DropdownMenuItem(
                          value: 'indoor', child: Text('Trong nhà (Indoor)')),
                      DropdownMenuItem(
                          value: 'outdoor',
                          child: Text('Ngoài trời (Outdoor)')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _location = val;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 16),

                  SwitchListTile(
                    title: const Text('Nhận thông báo cảnh báo (FCM)'),
                    subtitle: const Text(
                        'Tắt để ngưng nhận tất cả cảnh báo đẩy trên điện thoại'),
                    value: _fcmEnabled,
                    onChanged: _toggleFcm,
                    secondary: const Icon(Icons.notifications_active),
                    contentPadding: EdgeInsets.zero,
                  ),
                  const Divider(),
                  const SizedBox(height: 16),

                  const Text('Gửi push notification khi vượt ngưỡng:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),

                  // Threshold fields
                  ..._fields.map((f) => Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: TextFormField(
                          controller: _ctrl[f['key']!],
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          decoration: InputDecoration(
                            labelText: f['label'],
                            hintText: f['hint'],
                            border: const OutlineInputBorder(),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () => _ctrl[f['key']!]!.clear(),
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) return null;
                            if (double.tryParse(v) == null)
                              return 'Giá trị không hợp lệ';
                            if (double.parse(v) <= 0) return 'Phải lớn hơn 0';
                            return null;
                          },
                        ),
                      )),
                  const SizedBox(height: 8),

                  // Lưu
                  FilledButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: _saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.save),
                    label: const Text('Lưu cài đặt'),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _saving ? null : _shareDevice,
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.indigo.shade700,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.share),
                    label: const Text('Chia sẻ thiết bị'),
                  ),
                  const SizedBox(height: 32),
                  const Divider(),
                  const SizedBox(height: 8),

                  // Đăng xuất
                  OutlinedButton.icon(
                    onPressed: _logout,
                    icon: const Icon(Icons.logout, color: Colors.red),
                    label: const Text('Đăng xuất / Đổi thiết bị',
                        style: TextStyle(color: Colors.red)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
