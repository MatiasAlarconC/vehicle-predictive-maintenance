import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vehicle_predictive_maintenance_app/app/theme/app_theme.dart';

/// Medidor circular de salud estilo dashboard automotriz premium.
class HealthMeterWidget extends StatelessWidget {
  final double value; // 0–100

  const HealthMeterWidget({super.key, required this.value});

  Color _colorFor(double v) {
    if (v > 70) return AppTheme.successColor;
    if (v >= 40) return AppTheme.warningColor;
    return AppTheme.dangerColor;
  }

  String _labelFor(double v) {
    if (v > 70) return 'ÓPTIMO';
    if (v >= 40) return 'PRECAUCIÓN';
    return 'CRÍTICO';
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value),
      duration: const Duration(milliseconds: 1200),
      curve: Curves.easeOutCubic,
      builder: (context, animatedValue, _) {
        final color = _colorFor(animatedValue);
        return Column(
          children: [
            SizedBox(
              width: 220,
              height: 220,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Círculo de glow exterior
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _HealthGlowPainter(
                          progress: animatedValue / 100, color: color),
                    ),
                  ),
                  // Arco principal
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _HealthArcPainter(
                          progress: animatedValue / 100, color: color),
                    ),
                  ),
                  // Centro
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${animatedValue.toStringAsFixed(0)}',
                        style: GoogleFonts.rajdhani(
                          fontSize: 56,
                          fontWeight: FontWeight.w800,
                          color: color,
                          height: 1,
                        ),
                      ),
                      Text(
                        '%',
                        style: GoogleFonts.rajdhani(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: color.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'VEHICLE HEALTH',
                        style: TextStyle(
                          fontSize: 10,
                          letterSpacing: 2,
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: color.withValues(alpha: 0.3), width: 1),
                        ),
                        child: Text(
                          _labelFor(animatedValue),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: color,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _HealthArcPainter extends CustomPainter {
  final double progress;
  final Color color;

  _HealthArcPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 16;
    const startAngle = math.pi * 0.65;
    const sweepAngle = math.pi * 1.7;

    // Track background
    final trackPaint = Paint()
      ..color = AppTheme.borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      trackPaint,
    );

    // Track de progreso con gradiente
    if (progress > 0) {
      final rect = Rect.fromCircle(center: center, radius: radius);
      final shader = SweepGradient(
        startAngle: startAngle,
        endAngle: startAngle + sweepAngle * progress,
        colors: [
          color.withValues(alpha: 0.5),
          color,
        ],
      ).createShader(rect);

      final progressPaint = Paint()
        ..shader = shader
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        rect,
        startAngle,
        sweepAngle * progress,
        false,
        progressPaint,
      );
    }

    // Tick marks
    final tickPaint = Paint()
      ..color = AppTheme.textSecondary.withValues(alpha: 0.2)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i <= 10; i++) {
      final angle = startAngle + sweepAngle * (i / 10);
      final outerR = radius + 8;
      final innerR = radius + 3;
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
  bool shouldRepaint(covariant _HealthArcPainter old) =>
      old.progress != progress || old.color != color;
}

class _HealthGlowPainter extends CustomPainter {
  final double progress;
  final Color color;

  _HealthGlowPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 16;
    const startAngle = math.pi * 0.65;
    const sweepAngle = math.pi * 1.7;

    // Calcula el extremo del arco de progreso
    final endAngle = startAngle + sweepAngle * progress;
    final tipX = center.dx + radius * math.cos(endAngle);
    final tipY = center.dy + radius * math.sin(endAngle);

    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.6)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);

    canvas.drawCircle(Offset(tipX, tipY), 8, glowPaint);
  }

  @override
  bool shouldRepaint(covariant _HealthGlowPainter old) =>
      old.progress != progress || old.color != color;
}
