import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:vehicle_predictive_maintenance_app/app/theme/app_theme.dart';
import 'package:vehicle_predictive_maintenance_app/app/widgets/vera_components.dart';
import 'package:vehicle_predictive_maintenance_app/core/enums/app_enums.dart';
import 'package:vehicle_predictive_maintenance_app/core/providers/app_provider.dart';
import 'package:vehicle_predictive_maintenance_app/core/providers/diagnostics_provider.dart';
import 'package:vehicle_predictive_maintenance_app/features/diagnostics/widgets/realtime_chart_widget.dart';

class DiagnosticsScreen extends StatelessWidget {
  const DiagnosticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appProvider = context.watch<AppProvider>();
    final diagnostics = context.watch<DiagnosticsProvider>();
    final reading = diagnostics.latestReading;
    final isDemo = appProvider.appMode == AppMode.demo;

    final rpm     = reading?.rpm          ?? 900;
    final temp    = reading?.engineTemp   ?? 88.0;
    final speed   = reading?.speed        ?? 0;
    final voltage = reading?.voltage      ?? 12.7;
    final engineLoad = reading?.engineLoad ?? 35.0;
    final maf     = reading?.maf          ?? 8.0;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(children: [

          // ── Top bar ──────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppTheme.borderColor))),
            child: Row(children: [
              const VeraMark(size: 14),
              const SizedBox(width: 8),
              Text('VERA', style: vMono(color: AppTheme.textPrimary, size: 9.5, letterSpacing: 0.18)),
              Text(' · obd-ii', style: vMono(size: 9.5, color: AppTheme.textFaint, letterSpacing: 0.18)),
              const Spacer(),
              Container(
                width: 5, height: 5,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDemo ? AppTheme.warningColor : AppTheme.primaryColor,
                ),
              ),
              const SizedBox(width: 5),
              Text(isDemo ? 'demo' : 'live', style: vMono(size: 9.5, color: AppTheme.textFaint)),
            ]),
          ),

          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                // Demo notice (minimal)
                if (isDemo) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.warningColor.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(children: [
                      Container(width: 4, height: 4, decoration: BoxDecoration(
                          shape: BoxShape.circle, color: AppTheme.warningColor)),
                      const SizedBox(width: 8),
                      Text('Modo demo — datos simulados',
                          style: vMono(size: 10, color: AppTheme.warningColor, letterSpacing: 0.1)),
                    ]),
                  ),
                  const SizedBox(height: 20),
                ],

                // ── Section: Lecturas primarias ────────────────────────
                Text('Lecturas', style: GoogleFonts.spaceGrotesk(
                    fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                Text('OBD-II en vivo',
                    style: vMono(size: 9, color: AppTheme.textFaint, letterSpacing: 0.1)),
                const SizedBox(height: 14),

                // 3 main gauges
                Row(children: [
                  Expanded(child: _Gauge(
                    label: 'RPM',
                    value: rpm,
                    min: 0, max: 6000,
                    unit: 'rpm',
                    alertThreshold: 4500,
                  )),
                  const SizedBox(width: 8),
                  Expanded(child: _Gauge(
                    label: 'Temperatura',
                    value: temp,
                    min: 60, max: 120,
                    unit: '°C',
                    alertThreshold: 100,
                  )),
                  const SizedBox(width: 8),
                  Expanded(child: _Gauge(
                    label: 'Velocidad',
                    value: speed.toDouble(),
                    min: 0, max: 200,
                    unit: 'km/h',
                  )),
                ]),

                const SizedBox(height: 8),

                // 3 secondary tiles
                Row(children: [
                  Expanded(child: _SecondaryTile(
                    label: 'Carga motor',
                    value: '${engineLoad.toInt()}%',
                  )),
                  const SizedBox(width: 8),
                  Expanded(child: _SecondaryTile(
                    label: 'Voltaje',
                    value: '${voltage.toStringAsFixed(1)} V',
                    alert: voltage < 12.0,
                  )),
                  const SizedBox(width: 8),
                  Expanded(child: _SecondaryTile(
                    label: 'MAF',
                    value: '${maf.toStringAsFixed(1)}',
                    unit: 'g/s',
                  )),
                ]),

                const SizedBox(height: 28),

                // ── Section: Gráfico ───────────────────────────────────
                Row(children: [
                  Text('Gráfico', style: GoogleFonts.spaceGrotesk(
                      fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                  const Spacer(),
                  const VeraLiveDot(),
                  const SizedBox(width: 5),
                  Text('live', style: vMono(size: 9, color: AppTheme.textFaint)),
                ]),
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    color: AppTheme.surface,
                    padding: const EdgeInsets.all(16),
                    child: RealtimeChartWidget(readings: diagnostics.readings),
                  ),
                ),

                const SizedBox(height: 28),

                // ── Section: Canales ───────────────────────────────────
                Text('Todos los canales',
                    style: GoogleFonts.spaceGrotesk(
                        fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(children: [
                    _DataRow(label: 'RPM', value: '${rpm.toInt()} rpm'),
                    _DataRow(label: 'Temp. motor', value: '${temp.toInt()} °C',
                        valueColor: temp > 100 ? AppTheme.dangerColor : null),
                    _DataRow(label: 'Velocidad', value: '${speed.toInt()} km/h'),
                    _DataRow(label: 'Voltaje batería', value: '${voltage.toStringAsFixed(2)} V',
                        valueColor: voltage < 12.0 ? AppTheme.warningColor : null),
                    _DataRow(label: 'Carga motor', value: '${engineLoad.toInt()} %'),
                    _DataRow(label: 'Flujo aire (MAF)', value: '${maf.toStringAsFixed(1)} g/s'),
                    _DataRow(label: 'Modo', value: isDemo ? 'Demo' : 'OBD-II live', last: true),
                  ]),
                ),

                const SizedBox(height: 24),

                // ── CTA ────────────────────────────────────────────────
                GestureDetector(
                  onTap: () => context.go('/predict'),
                  child: Container(
                    height: 54,
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white, width: 1),
                    ),
                    child: Center(
                      child: Text('ANALIZAR',
                          style: vMono(size: 13, weight: FontWeight.w700, color: Colors.white, letterSpacing: 0.12)),
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}

// ─── Gauge tile ───────────────────────────────────────────────────────────────

class _Gauge extends StatelessWidget {
  final String label;
  final double value, min, max;
  final String unit;
  final double? alertThreshold;

  const _Gauge({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.unit,
    this.alertThreshold,
  });

  @override
  Widget build(BuildContext context) {
    final pct = ((value - min) / (max - min)).clamp(0.0, 1.0);
    final isAlert = alertThreshold != null && value > alertThreshold!;
    final color = isAlert ? AppTheme.dangerColor : AppTheme.textSecondary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      decoration: BoxDecoration(
        color: isAlert
            ? AppTheme.dangerColor.withValues(alpha: 0.06)
            : AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(label, style: vMono(size: 8.5, color: AppTheme.textFaint, letterSpacing: 0.15),
            textAlign: TextAlign.center),
        const SizedBox(height: 8),
        VeraRing(
          value: pct,
          max: 1.0,
          color: color,
          size: 60,
          strokeWidth: 4,
          center: Text(
            value >= 100
                ? value.toInt().toString()
                : value.toStringAsFixed(value >= 10 ? 0 : 1),
            style: GoogleFonts.spaceGrotesk(
                fontSize: 15, fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary, height: 1),
          ),
        ),
        const SizedBox(height: 4),
        Text(unit, style: vMono(size: 8, color: AppTheme.textFaint)),
      ]),
    );
  }
}

// ─── Secondary tile ───────────────────────────────────────────────────────────

class _SecondaryTile extends StatelessWidget {
  final String label, value;
  final String unit;
  final bool alert;

  const _SecondaryTile({
    required this.label,
    required this.value,
    this.unit = '',
    this.alert = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: vMono(size: 8, color: AppTheme.textFaint, letterSpacing: 0.15)),
        const SizedBox(height: 5),
        Text(value,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 16, fontWeight: FontWeight.w700,
              color: alert ? AppTheme.warningColor : AppTheme.textPrimary,
              height: 1,
            )),
      ]),
    );
  }
}

// ─── Data row (channel table) ─────────────────────────────────────────────────

class _DataRow extends StatelessWidget {
  final String label, value;
  final Color? valueColor;
  final bool last;

  const _DataRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.last = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 11),
          child: Row(children: [
            Text(label, style: vMono(size: 11, color: AppTheme.textSecondary, letterSpacing: 0.05)),
            const Spacer(),
            Text(value,
                style: GoogleFonts.spaceGrotesk(
                    fontSize: 13, fontWeight: FontWeight.w600,
                    color: valueColor ?? AppTheme.textPrimary)),
          ]),
        ),
        if (!last) Divider(color: AppTheme.borderColor, height: 1),
      ],
    );
  }
}
