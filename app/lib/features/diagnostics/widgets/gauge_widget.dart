import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vehicle_predictive_maintenance_app/app/theme/app_theme.dart';

/// Gauge circular estilo cuadro de instrumentos automotriz premium.
class GaugeWidget extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final String unit;
  final Color? overrideColor;

  const GaugeWidget({
    super.key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.unit,
    this.overrideColor,
  });

  Color _colorFor(double normalized) {
    if (overrideColor != null) return overrideColor!;
    if (normalized > 0.8) return AppTheme.dangerColor;
    if (normalized > 0.6) return AppTheme.warningColor;
    return AppTheme.textSecondary;
  }

  @override
  Widget build(BuildContext context) {
    final normalized = ((value - min) / (max - min)).clamp(0.0, 1.0);

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
      tween: Tween<double>(begin: 0, end: normalized),
      builder: (context, animatedNorm, _) {
        final color = _colorFor(animatedNorm);
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 100,
              height: 100,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Glow
                  CustomPaint(
                    size: const Size(100, 100),
                    painter: _GaugeGlowPainter(
                        progress: animatedNorm, color: color),
                  ),
                  // Arco
                  CustomPaint(
                    size: const Size(100, 100),
                    painter: _GaugeArcPainter(
                        progress: animatedNorm, color: color),
                  ),
                  // Valor central
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        value.toStringAsFixed(0),
                        style: GoogleFonts.rajdhani(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: color,
                          height: 1,
                        ),
                      ),
                      Text(
                        unit,
                        style: TextStyle(
                          fontSize: 9,
                          color: AppTheme.textSecondary,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.5,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _GaugeArcPainter extends CustomPainter {
  final double progress;
  final Color color;

  _GaugeArcPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;
    const startAngle = math.pi * 0.75;
    const sweepAngle = math.pi * 1.5;

    // Track
    final trackPaint = Paint()
      ..color = AppTheme.borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      trackPaint,
    );

    // Progreso
    if (progress > 0) {
      final progressPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle * progress,
        false,
        progressPaint,
      );
    }

    // Tick marks pequeños
    final tickPaint = Paint()
      ..color = AppTheme.textSecondary.withValues(alpha: 0.2)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i <= 8; i++) {
      final angle = startAngle + sweepAngle * (i / 8);
      final outerR = radius + 4;
      final innerR = radius;
      canvas.drawLine(
        Offset(center.dx + innerR * math.cos(angle),
            center.dy + innerR * math.sin(angle)),
        Offset(center.dx + outerR * math.cos(angle),
            center.dy + outerR * math.sin(angle)),
        tickPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _GaugeArcPainter old) =>
      old.progress != progress || old.color != color;
}

class _GaugeGlowPainter extends CustomPainter {
  final double progress;
  final Color color;

  _GaugeGlowPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;
    const startAngle = math.pi * 0.75;
    const sweepAngle = math.pi * 1.5;

    final endAngle = startAngle + sweepAngle * progress;
    final tipX = center.dx + radius * math.cos(endAngle);
    final tipY = center.dy + radius * math.sin(endAngle);

    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.7)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    canvas.drawCircle(Offset(tipX, tipY), 5, glowPaint);
  }

  @override
  bool shouldRepaint(covariant _GaugeGlowPainter old) =>
      old.progress != progress || old.color != color;
}
