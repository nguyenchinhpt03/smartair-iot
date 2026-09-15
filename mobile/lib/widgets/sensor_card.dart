import 'package:flutter/material.dart';
import 'dart:ui';

class SensorCard extends StatefulWidget {
  final String label;
  final String value;
  final String unit;
  final IconData icon;
  final Color? color;
  final bool isExceeded;

  const SensorCard({
    super.key,
    required this.label,
    required this.value,
    required this.unit,
    this.icon = Icons.sensors,
    this.color,
    this.isExceeded = false,
  });

  @override
  State<SensorCard> createState() => _SensorCardState();
}

class _SensorCardState extends State<SensorCard> with SingleTickerProviderStateMixin {
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -3.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -3.0, end: 3.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 3.0, end: -3.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -3.0, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(
      parent: _shakeController,
      curve: Curves.easeInOut,
    ));

    if (widget.isExceeded) {
      _shakeController.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant SensorCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isExceeded && !oldWidget.isExceeded) {
      _shakeController.repeat();
    } else if (!widget.isExceeded && oldWidget.isExceeded) {
      _shakeController.stop();
      _shakeController.reset();
    }
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = widget.isExceeded
        ? Colors.red
        : (widget.color ?? const Color(0xFF00796B));

    final cardBgColor = widget.isExceeded
        ? Colors.red.shade50.withOpacity(0.75)
        : Colors.white.withOpacity(0.55);

    final borderColor = widget.isExceeded
        ? Colors.red.shade400
        : baseColor.withOpacity(0.25);

    return AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_shakeAnimation.value, 0.0),
          child: Container(
            decoration: BoxDecoration(
              color: cardBgColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: borderColor,
                width: widget.isExceeded ? 2.0 : 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: baseColor.withOpacity(widget.isExceeded ? 0.25 : 0.08),
                  offset: const Offset(3, 3), // Neo-Brutalism shadow
                  blurRadius: widget.isExceeded ? 8 : 0,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), // Glassmorphism
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    children: [
                      // Circular animated-like icon container
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: baseColor.withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: widget.isExceeded
                            ? Icon(widget.icon, color: Colors.red.shade700, size: 22)
                            : Icon(widget.icon, color: baseColor, size: 22),
                      ),
                      const SizedBox(width: 10),
                      // Sensor readings text
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              widget.label,
                              style: TextStyle(
                                fontSize: 10.5,
                                color: widget.isExceeded
                                    ? Colors.red.shade800
                                    : Colors.grey.shade600,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.1,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  widget.value,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    color: widget.isExceeded
                                        ? Colors.red.shade900
                                        : const Color(0xFF263238),
                                  ),
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  widget.unit,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: widget.isExceeded
                                        ? Colors.red.shade700
                                        : Colors.grey.shade500,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
