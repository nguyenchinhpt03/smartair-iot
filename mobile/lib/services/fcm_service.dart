import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'api_service.dart';

class FcmService {
  static final _messaging = FirebaseMessaging.instance;
  static final StreamController<RemoteMessage> foregroundMessageStream = StreamController<RemoteMessage>.broadcast();

  /// Xin quyền và trả về FCM token hiện tại
  static Future<String?> initialize() async {
    final settings = await _messaging.requestPermission(
      alert: true, badge: true, sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      debugPrint('[FCM] Người dùng từ chối quyền notification');
      return null;
    }

    final token = await _messaging.getToken();
    debugPrint('[FCM] Token: $token');

    // Lắng nghe khi app đang mở (foreground)
    FirebaseMessaging.onMessage.listen((message) {
      debugPrint('[FCM] Foreground message: ${message.notification?.title}');
      foregroundMessageStream.add(message);
    });

    // Lắng nghe khi tap vào notification (app ở background)
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      debugPrint('[FCM] Opened from background: ${message.data}');
    });

    return token;
  }

  /// Cập nhật token lên server khi token thay đổi
  static void listenTokenRefresh(int userId) {
    _messaging.onTokenRefresh.listen((newToken) {
      debugPrint('[FCM] Token refreshed');
      ApiService().updateFcmToken(userId, newToken);
    });
  }

  /// Lấy token hiện tại và gửi lên server
  static Future<void> uploadCurrentToken(int userId) async {
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        debugPrint('[FCM] Uploading current token: $token');
        await ApiService().updateFcmToken(userId, token);
      } else {
        debugPrint('[FCM] Token is null!');
      }
    } catch (e) {
      debugPrint('[FCM] Error getting/uploading token: $e');
    }
  }
}
