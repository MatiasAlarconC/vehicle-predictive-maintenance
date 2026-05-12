import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:vehicle_predictive_maintenance_app/app/theme/app_theme.dart';
import 'package:vehicle_predictive_maintenance_app/app/widgets/custom_card.dart';
import 'package:vehicle_predictive_maintenance_app/core/enums/app_enums.dart';
import 'package:vehicle_predictive_maintenance_app/core/providers/app_provider.dart';
import 'package:vehicle_predictive_maintenance_app/core/providers/diagnostics_provider.dart';
import 'package:vehicle_predictive_maintenance_app/features/diagnostics/widgets/gauge_widget.dart';
import 'package:vehicle_predictive_maintenance_app/features/diagnostics/widgets/realtime_chart_widget.dart';

class DiagnosticsScreen extends StatelessWidget {
  const DiagnosticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appProvider = context.watch<AppProvider>();
    final diagnostics = context.watch<DiagnosticsProvider>();
    final reading = diagnostics.latestReading;

    final rpm = reading?.rpm ?? 900;
    final temp = reading?.engineTemp ?? 88;
    final speed = reading?.speed ?? 0;
    final voltage = reading?.voltage ?? 12.7;
    final engineLoad = reading?.engineLoad ?? 35;
    final maf = reading?.maf ?? 8;
    final isDemo = appProvider.appMode == AppMode.demo;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // Header fijo
        SliverToBoxAdapter(
          child: _ScannerHeader(isDemo: isDemo),
        ),

        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
          sliver: SliverList(
            delegate: SliverChildListDelegate([

              // Banner Demo
              if (isDemo)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppTheme.warningColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppTheme.warningColor.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded,
                          color: AppTheme.warningColor, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'MODO DEMO — Datos simulados OBD-II',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.warningColor,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),

              // Los 3 gauges principales
              CustomCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionLabel(label: 'LECTURAS OBD-II EN VIVO'),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        GaugeWidget(
                          label: 'RPM',
                          value: rpm,
                          min: 0,
                          max: 6000,
                          unit: 'rpm',
                          overrideColor: rpm > 4500 ? AppTheme.dangerColor : null,
                        ),
                        GaugeWidget(
                          label: 'TEMP',
                          value: temp,
                          min: 60,
                          max: 120,
                          unit: '°C',
                          overrideColor: temp > 100 ? AppTheme.dangerColor : null,
                        ),
                        GaugeWidget(
                          label: 'VELOCIDAD',
                          value: speed,
                          min: 0,
                          max: 160,
                          unit: 'km/h',
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Métricas secundarias
                    Row(
                      children: [
                        _MetricChip(
                          label: 'Carga motor',
                          value: '${engineLoad.toStringAsFixed(0)}%',
                          icon: Icons.speed_rounded,
                        ),
                        const SizedBox(width: 10),
                        _MetricChip(
                          label: 'Voltaje',
                          value: '${voltage.toStringAsFixed(1)} V',
                          icon: Icons.bolt_rounded,
                          alert: voltage < 12.0,
                        ),
                        const SizedBox(width: 10),
                        _MetricChip(
                          label: 'MAF',
                          value: '${maf.toStringAsFixed(1)} g/s',
                          icon: Icons.air_rounded,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Gráfico en tiempo real
              CustomCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionLabel(label: 'ÚLTIMAS 20 LECTURAS'),
                    const SizedBox(height: 16),
                    RealtimeChartWidget(readings: diagnostics.readings),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Estado de anomalía
              if (reading != null && reading.isAnomalous)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.dangerColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: AppTheme.dangerColor.withValues(alpha: 0.4)),
                    boxShadow: AppTheme.glowShadow(AppTheme.dangerColor,
                        intensity: 0.15),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.dangerColor.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.warning_rounded,
                            color: AppTheme.dangerColor, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ANOMALÍA DETECTADA',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.dangerColor,
                                letterSpacing: 1,
                              ),
                            ),
                            Text(
                              'Valores fuera de rango normal',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

              // Botón Analizar con IA
              _AnalyzeButton(
                onTap: reading != null
                    ? () => context.go('/predict')
                    : null,
              ),
            ]),
          ),
        ),
      ],
    );
  }
}

class _ScannerHeader extends StatelessWidget {
  final bool isDemo;
  const _ScannerHeader({required this.isDemo});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        left: 20,
        right: 20,
        bottom: 20,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.backgroundSecondary, AppTheme.background],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'OBD-II SCANNER',
                style: TextStyle(
                  fontFamily: 'Rajdhani',
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                  letterSpacing: 2,
                ),
              ),
              Text(
                'Diagnóstico en tiempo real',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const Spacer(),
          // Indicador pulsante de lectura activa
          _PulsingDot(color: isDemo ? AppTheme.warningColor : AppTheme.successColor),
        ],
      ),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  final Color color;
  const _PulsingDot({required this.color});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000))
      ..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.4, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: widget.color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: widget.color.withValues(alpha: _anim.value * 0.5)),
          boxShadow: [
            BoxShadow(
              color: widget.color.withValues(alpha: _anim.value * 0.3),
              blurRadius: 12,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.color.withValues(alpha: _anim.value),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              'ACTIVO',
              style: TextStyle(
                fontSize: 10,
                color: widget.color,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 11,
        color: AppTheme.textSecondary,
        fontWeight: FontWeight.w700,
        letterSpacing: 2,
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool alert;

  const _MetricChip({
    required this.label,
    required this.value,
    required this.icon,
    this.alert = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = alert ? AppTheme.dangerColor : AppTheme.primaryColor;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: alert ? AppTheme.dangerColor : AppTheme.textPrimary,
              ),
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 9, color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnalyzeButton extends StatelessWidget {
  final VoidCallback? onTap;
  const _AnalyzeButton({this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: onTap != null ? 1.0 : 0.5,
        child: Container(
          height: 60,
          decoration: BoxDecoration(
            gradient: onTap != null ? AppTheme.primaryGradient : null,
            color: onTap == null ? AppTheme.borderColor : null,
            borderRadius: BorderRadius.circular(16),
            boxShadow: onTap != null
                ? AppTheme.glowShadow(AppTheme.primaryColor, intensity: 0.35)
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.psychology_rounded,
                  color: Colors.black, size: 22),
              const SizedBox(width: 12),
              Text(
                'ANALIZAR CON IA',
                style: TextStyle(
                  fontFamily: 'Rajdhani',
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
