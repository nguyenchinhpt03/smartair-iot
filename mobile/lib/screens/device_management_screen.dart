import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../widgets/wifi_provisioning_dialog.dart';

class DeviceManagementScreen extends StatefulWidget {
  final int userId;
  final String activeDeviceId;
  const DeviceManagementScreen(
      {super.key, required this.userId, required this.activeDeviceId});

  @override
  State<DeviceManagementScreen> createState() => _DeviceManagementScreenState();
}

class _DeviceManagementScreenState extends State<DeviceManagementScreen> {
  List<dynamic> _devices = [];
  bool _loading = true;
  String _activeDeviceId = '';

  @override
  void initState() {
    super.initState();
    _activeDeviceId = widget.activeDeviceId;
    _loadDevices();
  }

  Future<void> _loadDevices() async {
    setState(() => _loading = true);
    final list = await ApiService().getUserDevices(widget.userId);
    final prefs = await SharedPreferences.getInstance();

    // Đồng bộ IP từ backend vào SharedPreferences để đảm bảo nhất quán
    for (final dev in list) {
      final devId = dev['device_id'] as String;
      final devIp = dev['ip_address'] as String?;
      if (devIp != null && devIp.trim().isNotEmpty) {
        await prefs.setString('device_ip_$devId', devIp);
      } else {
        await prefs.remove('device_ip_$devId');
      }
    }

    if (mounted) {
      setState(() {
        _devices = list;
        _loading = false;
      });
    }
  }

  Future<void> _selectDevice(String deviceId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('device_id', deviceId);
    setState(() {
      _activeDeviceId = deviceId;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Đã chuyển sang thiết bị: $deviceId'),
            backgroundColor: Colors.teal),
      );
    }
    // Trả về true để màn hình chính biết cần load lại
    Navigator.pop(context, true);
  }

  Future<void> _showAddDeviceDialog() async {
    final idCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final ipCtrl = TextEditingController();
    String location = 'indoor';
    String? dialogError;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Thêm thiết bị mới',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Color(0xFF004D40))),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: idCtrl,
                      decoration: const InputDecoration(
                          labelText: 'Mã thiết bị (Device ID)',
                          hintText: 'Ví dụ: SA-001'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                          labelText: 'Tên thiết bị',
                          hintText: 'Ví dụ: Phòng khách'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: location,
                      decoration:
                          const InputDecoration(labelText: 'Vị trí đặt'),
                      items: const [
                        DropdownMenuItem(
                            value: 'indoor', child: Text('Trong nhà (Indoor)')),
                        DropdownMenuItem(
                            value: 'outdoor',
                            child: Text('Ngoài trời (Outdoor)')),
                      ],
                      onChanged: (val) {
                        if (val != null) setDialogState(() => location = val);
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: ipCtrl,
                      decoration: const InputDecoration(
                          labelText: 'Địa chỉ IP (Tùy chọn)',
                          hintText: 'Ví dụ: 192.168.1.100'),
                    ),
                    if (dialogError != null) ...[
                      const SizedBox(height: 12),
                      Text(dialogError!,
                          style:
                              const TextStyle(color: Colors.red, fontSize: 13)),
                    ]
                  ],
                ),
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Hủy')),
                FilledButton(
                  onPressed: () async {
                    final id = idCtrl.text.trim();
                    final name = nameCtrl.text.trim();
                    final ip = ipCtrl.text.trim();

                    if (id.isEmpty) {
                      setDialogState(() =>
                          dialogError = 'Mã thiết bị không được để trống.');
                      return;
                    }

                    final res = await ApiService().addDevice(
                      deviceId: id,
                      name: name.isEmpty ? 'SmartAir Device' : name,
                      location: location,
                      ipAddress: ip.isEmpty ? null : ip,
                      userId: widget.userId,
                    );

                    if (res == null || res.containsKey('error')) {
                      setDialogState(() =>
                          dialogError = res?['error'] ?? 'Lỗi không xác định.');
                    } else {
                      // Lưu IP vào SharedPreferences
                      final prefs = await SharedPreferences.getInstance();
                      if (ip.isNotEmpty) {
                        await prefs.setString('device_ip_$id', ip);
                      } else {
                        await prefs.remove('device_ip_$id');
                      }
                      if (context.mounted) Navigator.pop(context);
                      _loadDevices();
                    }
                  },
                  child: const Text('Thêm'),
                )
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showEditDeviceDialog(Map<String, dynamic> device) async {
    final devId = device['device_id'] as String;
    final nameCtrl = TextEditingController(text: device['name'] ?? '');
    final ipCtrl = TextEditingController(text: device['ip_address'] ?? '');
    String location = device['location'] ?? 'indoor';
    String? dialogError;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Sửa thiết bị: $devId',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: Color(0xFF004D40))),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameCtrl,
                      decoration:
                          const InputDecoration(labelText: 'Tên thiết bị'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: location,
                      decoration:
                          const InputDecoration(labelText: 'Vị trí đặt'),
                      items: const [
                        DropdownMenuItem(
                            value: 'indoor', child: Text('Trong nhà (Indoor)')),
                        DropdownMenuItem(
                            value: 'outdoor',
                            child: Text('Ngoài trời (Outdoor)')),
                      ],
                      onChanged: (val) {
                        if (val != null) setDialogState(() => location = val);
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: ipCtrl,
                      decoration: const InputDecoration(
                          labelText: 'Địa chỉ IP (Tùy chọn)',
                          hintText: 'Ví dụ: 192.168.1.100'),
                    ),
                    if (dialogError != null) ...[
                      const SizedBox(height: 12),
                      Text(dialogError!,
                          style:
                              const TextStyle(color: Colors.red, fontSize: 13)),
                    ]
                  ],
                ),
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Hủy')),
                FilledButton(
                  onPressed: () async {
                    final name = nameCtrl.text.trim();
                    final ip = ipCtrl.text.trim();

                    final ok = await ApiService().updateDevice(
                      deviceId: devId,
                      name: name,
                      location: location,
                      ipAddress:
                          ip.isEmpty ? '' : ip, // Gửi chuỗi rỗng để xóa trên db
                    );

                    if (!ok) {
                      setDialogState(() =>
                          dialogError = 'Lưu thất bại. Vui lòng thử lại.');
                    } else {
                      // Cập nhật SharedPreferences
                      final prefs = await SharedPreferences.getInstance();
                      if (ip.isNotEmpty) {
                        await prefs.setString('device_ip_$devId', ip);
                      } else {
                        await prefs.remove('device_ip_$devId');
                      }
                      if (context.mounted) Navigator.pop(context);
                      _loadDevices();
                    }
                  },
                  child: const Text('Lưu'),
                )
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _unlinkDevice(String deviceId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hủy liên kết'),
        content: Text(
            'Bạn có chắc chắn muốn hủy liên kết thiết bị $deviceId khỏi tài khoản này?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hủy')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hủy liên kết'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    final ok = await ApiService()
        .unlinkDevice(deviceId: deviceId, userId: widget.userId);
    if (ok) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('device_ip_$deviceId');

      // Nếu thiết bị bị xóa trùng với thiết bị đang active, chọn thiết bị khác làm active
      if (deviceId == _activeDeviceId) {
        _devices.removeWhere((d) => d['device_id'] == deviceId);
        if (_devices.isNotEmpty) {
          final nextActive = _devices.first['device_id'] as String;
          await prefs.setString('device_id', nextActive);
          _activeDeviceId = nextActive;
        } else {
          await prefs.remove('device_id');
          _activeDeviceId = '';
        }
      }
      _loadDevices();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Hủy liên kết thất bại'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý thiết bị'),
        actions: [
          IconButton(
              icon: const Icon(Icons.add), onPressed: _showAddDeviceDialog),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadDevices,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _devices.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.sensors_off,
                            size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        const Text('Không có thiết bị nào.',
                            style: TextStyle(color: Colors.grey, fontSize: 16)),
                        const SizedBox(height: 12),
                        FilledButton(
                            onPressed: _showAddDeviceDialog,
                            child: const Text('Thêm thiết bị')),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _devices.length,
                    itemBuilder: (context, index) {
                      final dev = _devices[index];
                      final devId = dev['device_id'] as String;
                      final isActive = devId == _activeDeviceId;
                      final isOnline = dev['is_online'] as bool? ?? false;
                      final name = dev['name'] as String? ?? 'SmartAir Device';
                      final ip =
                          dev['ip_address'] as String? ?? 'Chưa cấu hình';
                      final location = dev['location'] == 'outdoor'
                          ? 'Ngoài trời'
                          : 'Trong nhà';

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: isActive ? 2 : 0,
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: isActive
                                ? const Color(0xFF00796B)
                                : Colors.grey.shade200,
                            width: isActive ? 1.5 : 1,
                          ),
                        ),
                        child: InkWell(
                          onTap: () => _selectDevice(devId),
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                            child: Row(
                              children: [
                                // Trạng thái online (Icon Container)
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: isOnline
                                        ? const Color(0xFFE8F5E9)
                                        : Colors.grey.shade100,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isOnline
                                          ? const Color(0xFFA5D6A7)
                                          : Colors.grey.shade300,
                                      width: 1,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.sensors,
                                    color: isOnline
                                        ? const Color(0xFF2E7D32)
                                        : Colors.grey.shade600,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 12),

                                // Chi tiết thiết bị
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Flexible(
                                            child: Text(
                                              name,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15,
                                                color: Color(0xFF263238),
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          if (isActive) ...[
                                            const SizedBox(width: 6),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 2),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFE0F2F1),
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              child: const Text(
                                                'Hiện tại',
                                                style: TextStyle(
                                                    color: Color(0xFF00796B),
                                                    fontSize: 9,
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'ID: $devId • Vị trí: $location',
                                        style: TextStyle(
                                            color: Colors.grey.shade600,
                                            fontSize: 11),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(Icons.network_ping,
                                              size: 12,
                                              color: Colors.teal.shade700),
                                          const SizedBox(width: 4),
                                          Flexible(
                                            child: Text(
                                              'IP: $ip',
                                              style: TextStyle(
                                                  color: Colors.teal.shade700,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),

                                // Thao tác (Compact)
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.wifi,
                                          color: Colors.teal, size: 20),
                                      padding: const EdgeInsets.all(6),
                                      constraints: const BoxConstraints(),
                                      tooltip: 'Cài đặt Wi-Fi',
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (_) =>
                                              WifiProvisioningDialog(
                                                  deviceId: devId),
                                        );
                                      },
                                    ),
                                    const SizedBox(width: 4),
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined,
                                          color: Colors.blue, size: 18),
                                      padding: const EdgeInsets.all(6),
                                      constraints: const BoxConstraints(),
                                      tooltip: 'Sửa thông tin',
                                      onPressed: () =>
                                          _showEditDeviceDialog(dev),
                                    ),
                                    const SizedBox(width: 6),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline,
                                          color: Colors.red, size: 18),
                                      padding: const EdgeInsets.all(6),
                                      constraints: const BoxConstraints(),
                                      tooltip: 'Xóa thiết bị',
                                      onPressed: () => _unlinkDevice(devId),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
