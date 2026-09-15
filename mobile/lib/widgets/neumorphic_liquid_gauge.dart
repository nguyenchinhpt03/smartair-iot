import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../utils/dynamic_color_helper.dart';

class NeumorphicLiquidGauge extends StatefulWidget {
  final int aqi;
  const NeumorphicLiquidGauge({super.key, required this.aqi});

  @override
  State<NeumorphicLiquidGauge> createState() => _NeumorphicLiquidGaugeState();
}

class _NeumorphicLiquidGaugeState extends State<NeumorphicLiquidGauge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final aqiColor = DynamicColorHelper.getAqiColor(widget.aqi);
    final aqiLabel = DynamicColorHelper.getAqiLabel(widget.aqi);
    final fillPercentage = (widget.aqi / 300.0).clamp(0.02, 1.0);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: 230,
          height: 230,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFF5F8F7),
            border: Border.all(
              color: aqiColor.withOpacity(0.2),
              width: 2.0,
            ),
            boxShadow: [
              // Neumorphic outer shadows
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                offset: const Offset(8, 8),
                blurRadius: 16,
              ),
              const BoxShadow(
                color: Colors.white,
                offset: Offset(-8, -8),
                blurRadius: 16,
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Container(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
              clipBehavior: Clip.antiAlias, // Clip the waves to circle shape
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Liquid waves CustomPaint
                  CustomPaint(
                    size: const Size(220, 220),
                    painter: _LiquidWavePainter(
                      fillPercentage: fillPercentage,
                      animValue: _controller.value,
                      waveColor: aqiColor.withOpacity(0.35),
                      backWaveColor: aqiColor.withOpacity(0.2),
                    ),
                  ),
                  // AQI text information
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${widget.aqi}',
                        style: TextStyle(
                          fontSize: 62,
                          fontWeight: FontWeight.w900,
                          color: DynamicColorHelper.darken(aqiColor, 0.25),
                          height: 1.0,
                          shadows: [
                            Shadow(
                              color: Colors.white.withOpacity(0.8),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                      ),
                      const Text(
                        'AQI',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: Colors.grey,
                          letterSpacing: 2.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: aqiColor.withOpacity(0.3),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            )
                          ],
                        ),
                        child: Text(
                          aqiLabel,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            color: DynamicColorHelper.darken(aqiColor, 0.25),
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.1,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _LiquidWavePainter extends CustomPainter {
  final double fillPercentage;
  final double animValue;
  final Color waveColor;
  final Color backWaveColor;

  _LiquidWavePainter({
    required this.fillPercentage,
    required this.animValue,
    required this.waveColor,
    required this.backWaveColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;

    // Calculate baseline height of water (fillPercentage is 0.0 to 1.0)
    // Note: y=height is empty, y=0 is full
    final waterLevelY = height - (fillPercentage * height);

    // 1. Draw back wave
    final backPath = Path();
    final backAngle = animValue * 2 * math.pi;
    backPath.moveTo(0, waterLevelY);
    for (double x = 0; x <= width; x++) {
      // Sine wave equation
      final y = waterLevelY + 7 * math.sin((x / width * 2 * math.pi) + backAngle);
      backPath.lineTo(x, y);
    }
    backPath.lineTo(width, height);
    backPath.lineTo(0, height);
    backPath.close();

    final backPaint = Paint()
      ..color = backWaveColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(backPath, backPaint);

    // 2. Draw front wave
    final frontPath = Path();
    final frontAngle = animValue * 2 * math.pi + math.pi; // Offset by pi for organic overlap
    frontPath.moveTo(0, waterLevelY);
    for (double x = 0; x <= width; x++) {
      // Sine wave with slightly different period & speed
      final y = waterLevelY + 8 * math.sin((x / width * 2.5 * math.pi) - frontAngle);
      frontPath.lineTo(x, y);
    }
    frontPath.lineTo(width, height);
    frontPath.lineTo(0, height);
    frontPath.close();

    final frontPaint = Paint()
      ..color = waveColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(frontPath, frontPaint);
  }

  @override
  bool shouldRepaint(covariant _LiquidWavePainter oldDelegate) {
    return oldDelegate.fillPercentage != fillPercentage ||
        oldDelegate.animValue != animValue ||
        oldDelegate.waveColor != waveColor;
  }
}
