import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../services/api_service.dart';
import '../services/fcm_service.dart';
import 'setup_account_screen.dart';
import '../widgets/main_shell.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // State điều khiển chế độ đăng nhập
  bool _useQrScan = false; // true: quét QR thiết bị, false: đăng nhập tài khoản
  bool _isRegister =
      false; // true: đang ở form đăng ký, false: đang ở form đăng nhập
  bool _loading = false;
  String? _error;

  // Luồng liên kết thiết bị sau khi đăng nhập tài khoản trống
  bool _linkDeviceMode = false;
  int? _loggedInUserId;

  // Controllers cho Form tài khoản
  final _usernameController = TextEditingController(text: 'demo');
  final _passwordController = TextEditingController(text: '123456');
  final _emailController = TextEditingController();
  final _manualCodeController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _emailController.dispose();
    _manualCodeController.dispose();
    super.dispose();
  }

  // ── Luồng 1: Xử lý khi Quét QR ─────────────────────────────────────
  Future<void> _onDetectQR(BarcodeCapture capture) async {
    if (_loading) return;
    final code = capture.barcodes.firstOrNull?.rawValue;
    if (code == null || code.isEmpty) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    final fcmToken = await FirebaseMessaging.instance.getToken() ?? '';

    if (_linkDeviceMode && _loggedInUserId != null) {
      // 1A. Người dùng đã đăng nhập tài khoản, quét QR để LIÊN KẾT thiết bị
      final result = await ApiService().registerDevice(
        qrCode: code,
        userId: _loggedInUserId,
        fcmToken: fcmToken,
      );

      if (!mounted) return;

      if (result == null) {
        setState(() {
          _error =
              'Không thể liên kết thiết bị. Mã QR không hợp lệ hoặc thiết bị không tồn tại.';
          _loading = false;
        });
        return;
      }

      final deviceId = result['device']['device_id'] as String;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('device_id', deviceId);
      await prefs.setInt('user_id', _loggedInUserId!);

      FcmService.listenTokenRefresh(_loggedInUserId!);

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              MainShell(deviceId: deviceId, userId: _loggedInUserId!),
        ),
      );
    } else {
      // 1B. Quét QR đăng nhập nhanh (luồng cũ - tự động tạo user/thiết bị)
      final result = await ApiService().registerDevice(
        qrCode: code,
        fcmToken: fcmToken,
      );

      if (!mounted) return;

      if (result == null) {
        setState(() {
          _error =
              'QR không hợp lệ hoặc thiết bị chưa được đăng ký trên hệ thống.';
          _loading = false;
        });
        return;
      }

      final deviceId = result['device']['device_id'] as String;
      setState(() {
        _loading = false;
        _error = null;
      });

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SetupAccountScreen(deviceId: deviceId),
        ),
      );
    }
  }

  Future<void> _onManualCodeSubmit(String code) async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    final fcmToken = await FirebaseMessaging.instance.getToken() ?? '';

    if (_linkDeviceMode && _loggedInUserId != null) {
      final result = await ApiService().registerDevice(
        qrCode: code,
        userId: _loggedInUserId,
        fcmToken: fcmToken,
      );

      if (!mounted) return;

      if (result == null) {
        setState(() {
          _error = 'Không thể liên kết thiết bị. Mã thiết bị không tồn tại.';
          _loading = false;
        });
        return;
      }

      final deviceId = result['device']['device_id'] as String;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('device_id', deviceId);
      await prefs.setInt('user_id', _loggedInUserId!);

      FcmService.listenTokenRefresh(_loggedInUserId!);
      FcmService.uploadCurrentToken(_loggedInUserId!);

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              MainShell(deviceId: deviceId, userId: _loggedInUserId!),
        ),
      );
    } else {
      final result = await ApiService().registerDevice(
        qrCode: code,
        fcmToken: fcmToken,
      );

      if (!mounted) return;

      if (result == null) {
        setState(() {
          _error = 'Mã thiết bị chưa được đăng ký trên hệ thống.';
          _loading = false;
        });
        return;
      }

      final deviceId = result['device']['device_id'] as String;
      setState(() {
        _loading = false;
        _error = null;
      });

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SetupAccountScreen(deviceId: deviceId),
        ),
      );
    }
  }

  // ── Luồng 2: Xử lý Đăng nhập / Đăng ký bằng tài khoản ───────────────
  Future<void> _onSubmitAccount() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();
    final email = _emailController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      setState(() {
        _error = 'Vui lòng nhập đầy đủ tài khoản và mật khẩu.';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    if (_isRegister) {
      // Đăng ký
      final res = await ApiService().register(
        username: username,
        password: password,
        email: email,
      );

      if (!mounted) return;

      if (res == null || res.containsKey('error')) {
        setState(() {
          _error = res?['error'] ?? 'Đăng ký không thành công.';
          _loading = false;
        });
        return;
      }

      // Đăng ký thành công -> Yêu cầu liên kết thiết bị ngay
      setState(() {
        _loading = false;
        _linkDeviceMode = true;
        _loggedInUserId = res['user_id'] as int;
        _error = null;
      });
    } else {
      // Đăng nhập
      final res = await ApiService().login(
        username: username,
        password: password,
      );

      if (!mounted) return;

      if (res == null || res.containsKey('error')) {
        setState(() {
          _error = res?['error'] ?? 'Đăng nhập không thành công.';
          _loading = false;
        });
        return;
      }

      if (res.containsKey('is_temp_login') && res['is_temp_login'] == true) {
        final deviceId = res['device_id'] as String;
        setState(() {
          _loading = false;
          _error = null;
        });
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SetupAccountScreen(deviceId: deviceId),
          ),
        );
        return;
      }

      final userId = res['user_id'] as int;

      if (res['device'] != null) {
        // Có thiết bị liên kết -> Vào thẳng MainShell
        final deviceId = res['device']['device_id'] as String;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('device_id', deviceId);
        await prefs.setInt('user_id', userId);

        FcmService.listenTokenRefresh(userId);
        FcmService.uploadCurrentToken(userId);

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => MainShell(deviceId: deviceId, userId: userId),
          ),
        );
      } else {
        // Tài khoản trống thiết bị -> Yêu cầu liên kết thiết bị bằng quét QR
        setState(() {
          _loading = false;
          _linkDeviceMode = true;
          _loggedInUserId = userId;
          _error = null;
        });
      }
    }
  }

  Future<void> _showServerConfigDialog() async {
    final prefs = await SharedPreferences.getInstance();
    final currentUrl =
        prefs.getString('custom_server_url') ?? 'http://10.0.2.2:3000';
    final ctrl = TextEditingController(text: currentUrl);

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.dns_rounded, color: Color(0xFF00796B)),
            SizedBox(width: 8),
            Text('Địa chỉ Server',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Nhập IP máy tính (mạng LAN) hoặc link Server Online (Render / Cloudflare):',
              style: TextStyle(fontSize: 12.5, color: Colors.black54),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              decoration: const InputDecoration(
                hintText: 'vd: http://192.168.1.251:3000',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newUrl = ctrl.text.trim();
              if (newUrl.isNotEmpty) {
                await prefs.setString('custom_server_url', newUrl);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Đã lưu địa chỉ server: $newUrl')),
                  );
                }
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00796B)),
            child: const Text('Lưu', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Giao diện quét QR (dùng cho Quét QR nhanh HOẶC khi cần liên kết thiết bị)
    if (_useQrScan || _linkDeviceMode) {
      return Scaffold(
        appBar: AppBar(
          title: Text(_linkDeviceMode
              ? 'Liên kết thiết bị SmartAir'
              : 'Quét QR đăng nhập'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              setState(() {
                _linkDeviceMode = false;
                _useQrScan = false;
                _error = null;
              });
            },
          ),
        ),
        body: Column(
          children: [
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  MobileScanner(onDetect: _onDetectQR),
                  Center(
                    child: Container(
                      width: 220,
                      height: 220,
                      decoration: BoxDecoration(
                        border: Border.all(
                            color: theme.colorScheme.primary, width: 3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  if (_loading)
                    Container(
                      color: Colors.black54,
                      child: const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_error != null) ...[
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: Colors.red, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                    ],
                    Text(
                      _linkDeviceMode
                          ? 'Tài khoản chưa có thiết bị.\nVui lòng quét mã QR in trên vỏ thiết bị SmartAir để liên kết.'
                          : 'Quét mã QR in trên thiết bị SmartAir để tự động đăng nhập nhanh.',
                      textAlign: TextAlign.center,
                      style:
                          TextStyle(color: Colors.grey.shade600, height: 1.5),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _manualCodeController,
                            style: const TextStyle(fontSize: 13),
                            decoration: const InputDecoration(
                              hintText: 'Nhập mã thiết bị (vd: SA-001)',
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                              isDense: true,
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            final code = _manualCodeController.text.trim();
                            if (code.isNotEmpty) {
                              _onManualCodeSubmit(code);
                            }
                          },
                          child:
                              Text(_linkDeviceMode ? 'Liên kết' : 'Xác nhận'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            )
          ],
        ),
      );
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFE0F2F1), // Soft teal light
              Color(0xFFB2DFDB), // Medium teal light
              Color(0xFFF5F8F7), // Neutral background
            ],
            stops: [0.0, 0.3, 0.7],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  icon:
                      const Icon(Icons.dns_outlined, color: Color(0xFF00796B)),
                  tooltip: 'Cài đặt địa chỉ Server',
                  onPressed: _showServerConfigDialog,
                ),
              ),
              Center(
                child: SingleChildScrollView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Logo Brand header
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.3),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.air,
                            size: 64, color: Color(0xFF00796B)),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'SmartAir',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF004D40),
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Giám sát chất lượng không khí thông minh',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 36),

                      // Glassmorphism login Form card
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.5),
                              width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 24,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                _isRegister ? 'ĐĂNG KÝ MỚI' : 'ĐĂNG NHẬP',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF004D40),
                                  letterSpacing: 1.0,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 24),

                              // Username
                              TextField(
                                controller: _usernameController,
                                decoration: const InputDecoration(
                                  labelText: 'Số điện thoại / Mã thiết bị',
                                  prefixIcon: Icon(Icons.person_outline),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Email for registration
                              if (_isRegister) ...[
                                TextField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  decoration: const InputDecoration(
                                    labelText: 'Email (Tùy chọn)',
                                    prefixIcon: Icon(Icons.mail_outline),
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],

                              // Password
                              TextField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                decoration: InputDecoration(
                                  labelText: 'Mật khẩu',
                                  prefixIcon: const Icon(Icons.lock_outline),
                                  suffixIcon: IconButton(
                                    icon: Icon(_obscurePassword
                                        ? Icons.visibility_off
                                        : Icons.visibility),
                                    onPressed: () => setState(() =>
                                        _obscurePassword = !_obscurePassword),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),

                              if (_error != null) ...[
                                Text(
                                  _error!,
                                  style: const TextStyle(
                                      color: Colors.red,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
                              ],

                              // Submit Button with Gradient
                              Container(
                                height: 52,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF00796B),
                                      Color(0xFF004D40)
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF00796B)
                                          .withValues(alpha: 0.3),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton(
                                  onPressed: _loading ? null : _onSubmitAccount,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                  ),
                                  child: _loading
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2),
                                        )
                                      : Text(
                                          _isRegister
                                              ? 'ĐĂNG KÝ & LIÊN KẾT'
                                              : 'ĐĂNG NHẬP',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                ),
                              ),

                              const SizedBox(height: 16),

                              // Toggle Sign In / Register
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _isRegister = !_isRegister;
                                    _error = null;
                                  });
                                },
                                child: Text(
                                  _isRegister
                                      ? 'Đã có tài khoản? Đăng nhập ngay'
                                      : 'Chưa có tài khoản? Đăng ký tại đây',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Color(0xFF00796B),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Divider OR
                      Row(
                        children: [
                          Expanded(
                              child: Divider(
                                  color: Colors.grey.shade300, thickness: 1)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'HOẶC',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.1,
                              ),
                            ),
                          ),
                          Expanded(
                              child: Divider(
                                  color: Colors.grey.shade300, thickness: 1)),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Scan QR Quick Login
                      OutlinedButton.icon(
                        onPressed: () => setState(() => _useQrScan = true),
                        icon: const Icon(Icons.qr_code_scanner, size: 20),
                        label: const Text('QUÉT NHANH QR THIẾT BỊ',
                            style: TextStyle(
                                fontSize: 14, fontWeight: FontWeight.bold)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF00796B),
                          side: const BorderSide(
                              color: Color(0xFF00796B), width: 1.5),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
