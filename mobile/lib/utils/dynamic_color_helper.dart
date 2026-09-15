import 'package:flutter/material.dart';

class DynamicColorHelper {
  /// Lấy mã màu đơn sắc chủ đạo đại diện cho mức AQI
  static Color getAqiColor(int aqi) {
    if (aqi <= 50)  return const Color(0xFF00E676); // Emerald Green
    if (aqi <= 100) return const Color(0xFFFFD600); // Soft Yellow / Amber
    if (aqi <= 150) return const Color(0xFFFF9100); // Vivid Orange
    if (aqi <= 200) return const Color(0xFFFF1744); // Deep Red / Crimson
    if (aqi <= 300) return const Color(0xFFD500F9); // Electric Purple
    return const Color(0xFF37474F);                 // Charcoal Gray / Black
  }

  /// Lấy nhãn chất lượng không khí tiếng Việt
  static String getAqiLabel(int aqi) {
    if (aqi <= 50)  return 'Tốt';
    if (aqi <= 100) return 'Trung bình';
    if (aqi <= 150) return 'Kém (Nhạy cảm)';
    if (aqi <= 200) return 'Có hại';
    if (aqi <= 300) return 'Rất có hại';
    return 'Nguy hiểm!';
  }

  /// Lấy danh sách màu Gradient nền ứng với giá trị AQI
  static List<Color> getBackgroundGradient(int aqi) {
    if (aqi <= 50) {
      return [
        const Color(0xFFE0F7FA), // Mint Light
        const Color(0xFFE8F5E9), // Emerald Light
      ];
    }
    if (aqi <= 100) {
      return [
        const Color(0xFFFFFDE7), // Soft Yellow Light
        const Color(0xFFFFF3E0), // Soft Amber Light
      ];
    }
    if (aqi <= 150) {
      return [
        const Color(0xFFFFF3E0), // Soft Amber Light
        const Color(0xFFFFE0B2), // Soft Orange Light
      ];
    }
    if (aqi <= 200) {
      return [
        const Color(0xFFFFEBEE), // Soft Red Light
        const Color(0xFFFFCDD2), // Crimson Light
      ];
    }
    if (aqi <= 300) {
      return [
        const Color(0xFFF3E5F5), // Soft Purple Light
        const Color(0xFFE1BEE7), // Violet Light
      ];
    }
    return [
      const Color(0xFFECEFF1), // Charcoal Light
      const Color(0xFFCFD8DC), // Toxic Gray Light
    ];
  }

  /// Hộp trang trí Glassmorphism (Kính mờ) kết hợp Neo-Brutalism (đường nét đậm, bóng đổ khối cứng)
  static BoxDecoration getGlassDecoration({
    required int aqi,
    Color? customBorderColor,
    double borderRadius = 16.0,
  }) {
    final baseColor = getAqiColor(aqi);
    return BoxDecoration(
      color: Colors.white.withOpacity(0.55),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: customBorderColor ?? baseColor.withOpacity(0.3),
        width: 1.5,
      ),
      boxShadow: [
        BoxShadow(
          color: baseColor.withOpacity(0.12),
          offset: const Offset(4, 4), // Bóng đổ khối cứng (Neo-Brutalism)
          blurRadius: 0,
        ),
        BoxShadow(
          color: Colors.white.withOpacity(0.2),
          offset: const Offset(-2, -2),
          blurRadius: 4,
          spreadRadius: 1,
        ),
      ],
    );
  }

  /// Làm đậm màu sắc (giảm độ sáng HSL)
  static Color darken(Color color, [double amount = 0.15]) {
    final hsl = HSLColor.fromColor(color);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }

  /// Làm nhạt màu sắc (tăng độ sáng HSL)
  static Color lighten(Color color, [double amount = 0.15]) {
    final hsl = HSLColor.fromColor(color);
    final hslLight = hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0));
    return hslLight.toColor();
  }
}

