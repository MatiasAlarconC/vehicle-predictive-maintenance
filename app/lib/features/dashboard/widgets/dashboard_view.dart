import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:vehicle_predictive_maintenance_app/app/theme/app_theme.dart';
import 'package:vehicle_predictive_maintenance_app/core/models/user_vehicle.dart';
import 'package:vehicle_predictive_maintenance_app/core/providers/auth_provider.dart';
import 'package:vehicle_predictive_maintenance_app/core/providers/diagnostics_provider.dart';
import 'package:vehicle_predictive_maintenance_app/core/providers/vehicle_provider.dart';
import 'package:vehicle_predictive_maintenance_app/features/dashboard/widgets/main_chart.dart';

class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final diagnostics = context.watch<DiagnosticsProvider>();
    final vehicle = context.watch<VehicleProvider>().vehicle;
    final firstName = context.watch<AuthProvider>().firstName;
    final reading = diagnostics.latestReading;
    final health = diagnostics.vehicleHealth;

    final rpm = reading?.rpm ?? 900;
    final temp = reading?.engineTemp ?? 88.0;
    final voltage = reading?.voltage ?? 12.7;
    final anomaly = reading?.isAnomalous ?? false;

    final statusLabel = health >= 85
        ? 'TODO BIEN'
        : health >= 60
            ? 'REVISAR PRONTO'
            : 'ATENCIÓN';
    final statusColor = health >= 85
        ? AppTheme.successColor
        : health >= 60
            ? AppTheme.warningColor
            : AppTheme.dangerColor;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // ── HERO ──────────────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: _HeroSection(
            vehicle: vehicle,
            health: health,
            statusLabel: statusLabel,
            statusColor: statusColor,
            userName: firstName,
          ),
        ),

        // ── CONTENT ───────────────────────────────────────────────────────
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              const SizedBox(height: 20),

              // ── Quick stats horizontal scroll ──────────────────────────
              SizedBox(
                height: 90,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _StatPill(
                      label: 'RPM',
                      value: rpm.toStringAsFixed(0),
                      icon: Icons.settings_input_component_rounded,
                      color: rpm > 4500
                          ? AppTheme.dangerColor
                          : AppTheme.primaryColor,
                      isAlert: rpm > 4500,
                    ),
                    const SizedBox(width: 10),
                    _StatPill(
                      label: 'TEMPERATURA',
                      value: '${temp.toStringAsFixed(0)}°C',
                      icon: Icons.thermostat_rounded,
                      color: temp > 100
                          ? AppTheme.dangerColor
                          : AppTheme.warningColor,
                      isAlert: temp > 100,
                    ),
                    const SizedBox(width: 10),
                    _StatPill(
                      label: 'BATERÍA',
                      value: '${voltage.toStringAsFixed(1)}V',
                      icon: Icons.battery_charging_full_rounded,
                      color: voltage < 12.0
                          ? AppTheme.dangerColor
                          : AppTheme.successColor,
                      isAlert: voltage < 12.0,
                    ),
                    const SizedBox(width: 10),
                    _StatPill(
                      label: 'ESTADO',
                      value: anomaly ? 'ALERTA' : 'ÓPTIMO',
                      icon: anomaly
                          ? Icons.warning_amber_rounded
                          : Icons.verified_rounded,
                      color: anomaly
                          ? AppTheme.dangerColor
                          : AppTheme.successColor,
                      isAlert: anomaly,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ── AI Diagnose button ─────────────────────────────────────
              _DiagnoseButton(onTap: () => context.go('/predict')),

              const SizedBox(height: 20),

              // ── Temperature chart ──────────────────────────────────────
              _ChartCard(diagnostics: diagnostics),

              const SizedBox(height: 100),
            ]),
          ),
        ),
      ],
    );
  }
}

// ── Hero section ──────────────────────────────────────────────────────────────

class _HeroSection extends StatelessWidget {
  final UserVehicle? vehicle;
  final double health;
  final String statusLabel;
  final Color statusColor;
  final String userName;

  const _HeroSection({
    required this.vehicle,
    required this.health,
    required this.statusLabel,
    required this.statusColor,
    required this.userName,
  });

  @override
  Widget build(BuildContext context) {
    final carColor = vehicle?.color.color ?? AppTheme.primaryColor;

    return SizedBox(
      height: 300,
      child: Stack(
        children: [
          // Background gradient
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    carColor.withValues(alpha: 0.18),
                    AppTheme.background,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),

          // Radial glow behind car
          Positioned(
            right: -20,
            top: 30,
            child: Container(
              width: 260,
              height: 200,
              decoration: BoxDecoration(
                gradient: RadialGradient(colors: [
                  carColor.withValues(alpha: 0.22),
                  Colors.transparent,
                ]),
              ),
            ),
          ),

          // Car silhouette
          Positioned(
            right: -10,
            bottom: 60,
            child: SizedBox(
              width: 240,
              height: 130,
              child: CustomPaint(
                painter: _HeroCarPainter(
                  bodyColor: carColor,
                  bodyType: vehicle?.bodyType ?? CarBodyType.sedan,
                ),
              ),
            ),
          ),

          // Top bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  children: [
                    // App brand
                    ShaderMask(
                      shaderCallback: (b) =>
                          AppTheme.primaryGradient.createShader(b),
                      child: const Text(
                        'VD',
                        style: TextStyle(
                          fontFamily: 'Rajdhani',
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                    const Spacer(),
                    // Garage link
                    GestureDetector(
                      onTap: () => context.go('/select-vehicle'),
                      child: Row(
                        children: const [
                          Text(
                            'GARAGE',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textSecondary,
                              letterSpacing: 2,
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(Icons.chevron_right_rounded,
                              color: AppTheme.textSecondary, size: 16),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Greeting + status text (left side)
          Positioned(
            left: 20,
            bottom: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hola, $userName',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  statusLabel,
                  style: GoogleFonts.rajdhani(
                    fontSize: 38,
                    fontWeight: FontWeight.w900,
                    color: statusColor,
                    height: 1,
                    shadows: [
                      Shadow(
                        color: statusColor.withValues(alpha: 0.4),
                        blurRadius: 16,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                if (vehicle != null)
                  Text(
                    '${vehicle!.make} ${vehicle!.model} · ${vehicle!.year}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                const SizedBox(height: 8),
                // Health bar
                _HealthBar(value: health),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HealthBar extends StatelessWidget {
  final double value;
  const _HealthBar({required this.value});

  @override
  Widget build(BuildContext context) {
    final pct = (value / 100).clamp(0.0, 1.0);
    final color = value >= 85
        ? AppTheme.successColor
        : value >= 60
            ? AppTheme.warningColor
            : AppTheme.dangerColor;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Salud del vehículo',
              style: const TextStyle(
                  fontSize: 11, color: AppTheme.textSecondary),
            ),
            const SizedBox(width: 8),
            Text(
              '${value.toInt()}%',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          width: 160,
          height: 4,
          decoration: BoxDecoration(
            color: AppTheme.borderColor,
            borderRadius: BorderRadius.circular(2),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: pct,
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.5),
                    blurRadius: 6,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Stat pill ─────────────────────────────────────────────────────────────────

class _StatPill extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool isAlert;

  const _StatPill({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.isAlert = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      width: 120,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isAlert ? color.withValues(alpha: 0.5) : AppTheme.borderColor,
          width: isAlert ? 1.5 : 1,
        ),
        boxShadow:
            isAlert ? AppTheme.glowShadow(color, intensity: 0.15) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 20),
          const Spacer(),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: GoogleFonts.rajdhani(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
                height: 1,
              ),
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 9,
              color: AppTheme.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Diagnose button ───────────────────────────────────────────────────────────

class _DiagnoseButton extends StatelessWidget {
  final VoidCallback onTap;
  const _DiagnoseButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppTheme.glowShadow(AppTheme.primaryColor, intensity: 0.35),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.auto_awesome_rounded,
                color: Colors.black, size: 20),
            const SizedBox(width: 10),
            Text(
              'ANALIZAR CON IA',
              style: GoogleFonts.rajdhani(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Colors.black,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Chart card ────────────────────────────────────────────────────────────────

class _ChartCard extends StatelessWidget {
  final DiagnosticsProvider diagnostics;
  const _ChartCard({required this.diagnostics});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.show_chart_rounded,
                    color: AppTheme.primaryColor, size: 16),
              ),
              const SizedBox(width: 10),
              const Text(
                'TEMPERATURA EN TIEMPO REAL',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textSecondary,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          MainChart(readings: diagnostics.readings),
        ],
      ),
    );
  }
}

// ── Hero car CustomPainter ────────────────────────────────────────────────────

class _HeroCarPainter extends CustomPainter {
  final Color bodyColor;
  final CarBodyType bodyType;

  const _HeroCarPainter({required this.bodyColor, required this.bodyType});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Ground shadow
    final shadowPaint = Paint()
      ..color = bodyColor.withValues(alpha: 0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);
    canvas.drawOval(
        Rect.fromLTWH(w * 0.08, h * 0.84, w * 0.84, h * 0.12), shadowPaint);

    final body = Paint()
      ..color = bodyColor
      ..style = PaintingStyle.fill;

    final highlight = Paint()
      ..color = Colors.white.withValues(alpha: 0.14)
      ..style = PaintingStyle.fill;

    final glassColor = Paint()
      ..color = Colors.lightBlueAccent.withValues(alpha: 0.20)
      ..style = PaintingStyle.fill;

    if (bodyType == CarBodyType.suv) {
      _suv(canvas, w, h, body, highlight, glassColor);
    } else if (bodyType == CarBodyType.coupe) {
      _coupe(canvas, w, h, body, highlight, glassColor);
    } else if (bodyType == CarBodyType.truck) {
      _truck(canvas, w, h, body, highlight, glassColor);
    } else {
      _sedan(canvas, w, h, body, highlight, glassColor);
    }
  }

  void _sedan(Canvas c, double w, double h, Paint body, Paint hi, Paint glass) {
    final path = Path()
      ..moveTo(w * 0.04, h * 0.74)
      ..lineTo(w * 0.04, h * 0.60)
      ..lineTo(w * 0.10, h * 0.56)
      ..cubicTo(w * 0.18, h * 0.53, w * 0.24, h * 0.33, w * 0.33, h * 0.27)
      ..cubicTo(w * 0.44, h * 0.21, w * 0.61, h * 0.21, w * 0.69, h * 0.27)
      ..cubicTo(w * 0.78, h * 0.33, w * 0.84, h * 0.51, w * 0.88, h * 0.56)
      ..lineTo(w * 0.96, h * 0.60)
      ..lineTo(w * 0.96, h * 0.74)
      ..close();
    c.drawPath(path, body);

    // Roof highlight
    final roofHi = Path()
      ..moveTo(w * 0.35, h * 0.28)
      ..cubicTo(w * 0.46, h * 0.22, w * 0.60, h * 0.22, w * 0.67, h * 0.28)
      ..cubicTo(w * 0.63, h * 0.24, w * 0.48, h * 0.24, w * 0.35, h * 0.28)
      ..close();
    c.drawPath(roofHi, hi);

    // Windshield
    final ws = Path()
      ..moveTo(w * 0.27, h * 0.52)
      ..cubicTo(w * 0.28, h * 0.38, w * 0.32, h * 0.29, w * 0.40, h * 0.27)
      ..lineTo(w * 0.49, h * 0.27)
      ..lineTo(w * 0.49, h * 0.52)
      ..close();
    c.drawPath(ws, glass);

    // Rear window
    final rw = Path()
      ..moveTo(w * 0.64, h * 0.27)
      ..cubicTo(w * 0.72, h * 0.29, w * 0.78, h * 0.38, w * 0.79, h * 0.52)
      ..lineTo(w * 0.65, h * 0.52)
      ..lineTo(w * 0.64, h * 0.27)
      ..close();
    c.drawPath(rw, glass);

    _wheels(c, w, h, w * 0.21, w * 0.76);
    _headlights(c, w, h);
  }

  void _suv(Canvas c, double w, double h, Paint body, Paint hi, Paint glass) {
    final path = Path()
      ..moveTo(w * 0.04, h * 0.76)
      ..lineTo(w * 0.04, h * 0.57)
      ..lineTo(w * 0.09, h * 0.53)
      ..lineTo(w * 0.14, h * 0.26)
      ..lineTo(w * 0.86, h * 0.26)
      ..lineTo(w * 0.91, h * 0.53)
      ..lineTo(w * 0.96, h * 0.57)
      ..lineTo(w * 0.96, h * 0.76)
      ..close();
    c.drawPath(path, body);

    final ws = Path()
      ..moveTo(w * 0.16, h * 0.50)
      ..lineTo(w * 0.21, h * 0.30)
      ..lineTo(w * 0.46, h * 0.30)
      ..lineTo(w * 0.46, h * 0.50)
      ..close();
    c.drawPath(ws, glass);

    final rw = Path()
      ..moveTo(w * 0.54, h * 0.30)
      ..lineTo(w * 0.79, h * 0.30)
      ..lineTo(w * 0.84, h * 0.50)
      ..lineTo(w * 0.54, h * 0.50)
      ..close();
    c.drawPath(rw, glass);

    final roofHi = Path()
      ..moveTo(w * 0.15, h * 0.27)
      ..lineTo(w * 0.85, h * 0.27)
      ..lineTo(w * 0.84, h * 0.30)
      ..lineTo(w * 0.16, h * 0.30)
      ..close();
    c.drawPath(roofHi, hi);

    _wheels(c, w, h, w * 0.21, w * 0.77);
    _headlights(c, w, h);
  }

  void _coupe(Canvas c, double w, double h, Paint body, Paint hi, Paint glass) {
    final path = Path()
      ..moveTo(w * 0.03, h * 0.74)
      ..lineTo(w * 0.03, h * 0.63)
      ..lineTo(w * 0.12, h * 0.58)
      ..cubicTo(w * 0.20, h * 0.55, w * 0.26, h * 0.24, w * 0.38, h * 0.20)
      ..cubicTo(w * 0.52, h * 0.16, w * 0.68, h * 0.18, w * 0.74, h * 0.26)
      ..cubicTo(w * 0.84, h * 0.38, w * 0.90, h * 0.54, w * 0.92, h * 0.58)
      ..lineTo(w * 0.97, h * 0.63)
      ..lineTo(w * 0.97, h * 0.74)
      ..close();
    c.drawPath(path, body);

    final ws = Path()
      ..moveTo(w * 0.28, h * 0.50)
      ..cubicTo(w * 0.30, h * 0.35, w * 0.36, h * 0.24, w * 0.46, h * 0.22)
      ..lineTo(w * 0.52, h * 0.22)
      ..lineTo(w * 0.52, h * 0.50)
      ..close();
    c.drawPath(ws, glass);

    final rw = Path()
      ..moveTo(w * 0.60, h * 0.22)
      ..cubicTo(w * 0.70, h * 0.22, w * 0.77, h * 0.34, w * 0.79, h * 0.50)
      ..lineTo(w * 0.60, h * 0.50)
      ..close();
    c.drawPath(rw, glass);

    _wheels(c, w, h, w * 0.22, w * 0.77);
    _headlights(c, w, h);
  }

  void _truck(Canvas c, double w, double h, Paint body, Paint hi, Paint glass) {
    final cab = Path()
      ..moveTo(w * 0.03, h * 0.76)
      ..lineTo(w * 0.03, h * 0.56)
      ..lineTo(w * 0.10, h * 0.52)
      ..lineTo(w * 0.13, h * 0.26)
      ..lineTo(w * 0.52, h * 0.26)
      ..lineTo(w * 0.55, h * 0.52)
      ..lineTo(w * 0.55, h * 0.76)
      ..close();
    c.drawPath(cab, body);

    final bed = Path()
      ..moveTo(w * 0.55, h * 0.52)
      ..lineTo(w * 0.96, h * 0.52)
      ..lineTo(w * 0.96, h * 0.76)
      ..lineTo(w * 0.55, h * 0.76)
      ..close();
    c.drawPath(bed, body);

    // bed highlight
    c.drawRect(Rect.fromLTWH(w * 0.57, h * 0.52, w * 0.37, h * 0.04), hi);

    final ws = Path()
      ..moveTo(w * 0.14, h * 0.50)
      ..lineTo(w * 0.17, h * 0.30)
      ..lineTo(w * 0.48, h * 0.30)
      ..lineTo(w * 0.48, h * 0.50)
      ..close();
    c.drawPath(ws, glass);

    _wheels(c, w, h, w * 0.22, w * 0.78);
    _headlights(c, w, h);
  }

  void _wheels(Canvas c, double w, double h, double x1, double x2) {
    for (final x in [x1, x2]) {
      // Tire
      c.drawCircle(Offset(x, h * 0.80), w * 0.095,
          Paint()..color = const Color(0xFF111520));
      // Rim outer
      c.drawCircle(Offset(x, h * 0.80), w * 0.060,
          Paint()..color = const Color(0xFF6B7280));
      // Rim inner
      c.drawCircle(Offset(x, h * 0.80), w * 0.030,
          Paint()..color = const Color(0xFF111520));
      // Hub
      c.drawCircle(Offset(x, h * 0.80), w * 0.012,
          Paint()..color = const Color(0xFF9CA3AF));
    }
  }

  void _headlights(Canvas c, double w, double h) {
    final light = Paint()
      ..color = Colors.white.withValues(alpha: 0.8)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    c.drawRect(Rect.fromLTWH(w * 0.90, h * 0.62, w * 0.05, h * 0.06), light);
  }

  @override
  bool shouldRepaint(_HeroCarPainter old) =>
      old.bodyColor != bodyColor || old.bodyType != bodyType;
}

// ── Rotating indicator (used in diagnostics) ─────────────────────────────────

class RotatingArcIndicator extends StatefulWidget {
  final double size;
  final Color color;
  const RotatingArcIndicator(
      {super.key, this.size = 32, required this.color});

  @override
  State<RotatingArcIndicator> createState() => _RotatingArcIndicatorState();
}

class _RotatingArcIndicatorState extends State<RotatingArcIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 1))
      ..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) => Transform.rotate(
          angle: _ctrl.value * 2 * math.pi,
          child: SizedBox(
            width: widget.size,
            height: widget.size,
            child: CustomPaint(
              painter: _ArcPainter(color: widget.color),
            ),
          ),
        ),
      );
}

class _ArcPainter extends CustomPainter {
  final Color color;
  const _ArcPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromLTWH(0, 0, size.width, size.height),
      -math.pi / 2,
      math.pi * 1.5,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_ArcPainter old) => old.color != color;
}
