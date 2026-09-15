import 'dart:math' as math;
import 'package:flutter/material.dart';

class AqiGauge extends StatelessWidget {
  final int aqi;
  const AqiGauge({super.key, required this.aqi});

  Color get _color {
    if (aqi <= 50)  return const Color(0xFF00E676);  // Bright Green
    if (aqi <= 100) return const Color(0xFFFFD600);  // Bright Yellow
    if (aqi <= 150) return const Color(0xFFFF9100);  // Bright Orange
    if (aqi <= 200) return const Color(0xFFFF1744);  // Bright Red
    if (aqi <= 300) return const Color(0xFFD500F9);  // Bright Purple
    return const Color(0xFF8D6E63);                  // Brownish
  }

  String get _label {
    if (aqi <= 50)  return 'Không khí Tốt';
    if (aqi <= 100) return 'Trung bình';
    if (aqi <= 150) return 'Kém (Nhạy cảm)';
    if (aqi <= 200) return 'Có hại';
    if (aqi <= 300) return 'Rất có hại';
    return 'Nguy hiểm!';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      height: 220,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 16,
            spreadRadius: 4,
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Radial gauge arc
          CustomPaint(
            size: const Size(200, 200),
            painter: AqiGaugePainter(aqi: aqi, color: _color),
          ),
          // Inner content
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$aqi',
                style: TextStyle(
                  fontSize: 58,
                  fontWeight: FontWeight.w900,
                  color: _color,
                  height: 1.0,
                  shadows: [
                    Shadow(
                      color: _color.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
              const Text(
                'AQI',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Colors.grey,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                decoration: BoxDecoration(
                  color: _color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: _color,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class AqiGaugePainter extends CustomPainter {
  final int aqi;
  final Color color;

  AqiGaugePainter({required this.aqi, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 12;

    // Background Arc (3/4 Circle: from 135 deg to 45 deg)
    final bgPaint = Paint()
      ..color = Colors.grey.shade100
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    const startAngle = 3 * math.pi / 4;
    const sweepAngle = 3 * math.pi / 2;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      bgPaint,
    );

    // Active progress arc
    final double pct = (aqi / 300.0).clamp(0.0, 1.0);
    final progressSweep = sweepAngle * pct;

    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;

    // Outer glow for the gauge line
    final glowPaint = Paint()
      ..color = color.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20
      ..strokeCap = StrokeCap.round;

    if (pct > 0.0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        progressSweep,
        false,
        glowPaint,
      );
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        progressSweep,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant AqiGaugePainter oldDelegate) {
    return oldDelegate.aqi != aqi || oldDelegate.color != color;
  }
}
