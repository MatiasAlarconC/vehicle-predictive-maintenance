import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:vehicle_predictive_maintenance_app/app/theme/app_theme.dart';

class GaugeWidget extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final String unit;

  const GaugeWidget({
    super.key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    final normalized = ((value - min) / (max - min)).clamp(0.0, 1.0);
    final color = normalized > 0.75
        ? AppTheme.dangerColor
        : normalized > 0.45
            ? AppTheme.warningColor
            : AppTheme.successColor;

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 700),
      tween: Tween<double>(begin: 0, end: normalized),
      builder: (context, animatedValue, _) {
        return Column(
          children: [
            SizedBox(
              width: 112,
              height: 112,
              child: CustomPaint(
                painter: _GaugePainter(progress: animatedValue, color: color),
                child: Center(
                  child: Text(
                    '${value.toStringAsFixed(0)}\n$unit',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(label),
          ],
        );
      },
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double progress;
  final Color color;

  _GaugePainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    const start = math.pi * 0.75;
    const sweep = math.pi * 1.5;

    final bg = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fg = Paint()
      ..color = color
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect.deflate(8), start, sweep, false, bg);
    canvas.drawArc(rect.deflate(8), start, sweep * progress, false, fg);
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
