import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:vehicle_predictive_maintenance_app/app/theme/app_theme.dart';
import 'package:vehicle_predictive_maintenance_app/app/widgets/custom_card.dart';
import 'package:vehicle_predictive_maintenance_app/core/providers/app_provider.dart';
import 'package:vehicle_predictive_maintenance_app/core/providers/diagnostics_provider.dart';
import 'package:vehicle_predictive_maintenance_app/features/dashboard/widgets/health_meter_widget.dart';
import 'package:vehicle_predictive_maintenance_app/features/dashboard/widgets/main_chart.dart';
import 'package:vehicle_predictive_maintenance_app/features/dashboard/widgets/status_card_widget.dart';

class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final appProvider = context.watch<AppProvider>();
    final diagnostics = context.watch<DiagnosticsProvider>();
    final reading = diagnostics.latestReading;
    final health = diagnostics.vehicleHealth;

    final rpm = reading?.rpm ?? 900;
    final temp = reading?.engineTemp ?? 88;
    final voltage = reading?.voltage ?? 12.7;
    final anomaly = reading?.isAnomalous ?? false;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // Header tipo BMW iDrive
        SliverToBoxAdapter(
          child: _DashboardHeader(
            isDemo: appProvider.appMode.name == 'demo',
          ),
        ),

        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              const SizedBox(height: 8),

              // Health meter centrado
              Center(child: HealthMeterWidget(value: health)),

              const SizedBox(height: 24),

              // Grid de tarjetas de estado
              GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.55,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  StatusCardWidget(
                    title: 'MOTOR',
                    value: '${rpm.toStringAsFixed(0)} RPM',
                    subtitle: rpm > 4500 ? 'RPM elevado' : 'Normal',
                    icon: Icons.settings_input_component_rounded,
                    color: rpm > 4500 ? AppTheme.dangerColor : AppTheme.successColor,
                    isAlert: rpm > 4500,
                  ),
                  StatusCardWidget(
                    title: 'BATERÍA',
                    value: '${voltage.toStringAsFixed(1)} V',
                    subtitle: voltage < 12.0 ? 'Baja tensión' : 'Estable',
                    icon: Icons.battery_charging_full_rounded,
                    color: voltage < 12.0 ? AppTheme.dangerColor : AppTheme.primaryColor,
                    isAlert: voltage < 12.0,
                  ),
                  StatusCardWidget(
                    title: 'TEMPERATURA',
                    value: '${temp.toStringAsFixed(0)} °C',
                    subtitle: temp > 100 ? 'Sobrecalentamiento' : 'Normal',
                    icon: Icons.thermostat_rounded,
                    color: temp > 100 ? AppTheme.dangerColor : AppTheme.warningColor,
                    isAlert: temp > 100,
                  ),
                  StatusCardWidget(
                    title: 'ESTADO',
                    value: anomaly ? 'ALERTA' : 'ÓPTIMO',
                    subtitle: 'Sistema general',
                    icon: anomaly
                        ? Icons.warning_amber_rounded
                        : Icons.verified_rounded,
                    color: anomaly ? AppTheme.dangerColor : AppTheme.successColor,
                    isAlert: anomaly,
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Botón principal de diagnóstico
              _DiagnoseButton(onTap: () => context.go('/predict')),

              const SizedBox(height: 20),

              // Card de historial de salud
              CustomCard(
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
                              color: AppTheme.primaryColor, size: 18),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Temperatura en tiempo real',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () {},
                          child: Text(
                            'Ver más',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    MainChart(readings: diagnostics.readings),
                  ],
                ),
              ),

              const SizedBox(height: 100),
            ]),
          ),
        ),
      ],
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  final bool isDemo;
  const _DashboardHeader({required this.isDemo});

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
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'VEHICLE',
                style: TextStyle(
                  fontFamily: 'Rajdhani',
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                  letterSpacing: 3,
                  height: 1.1,
                ),
              ),
              ShaderMask(
                shaderCallback: (b) =>
                    AppTheme.primaryGradient.createShader(b),
                child: Text(
                  'DIAGNOSTICS',
                  style: TextStyle(
                    fontFamily: 'Rajdhani',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 4,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          // Badge de modo
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isDemo
                  ? AppTheme.warningColor.withValues(alpha: 0.12)
                  : AppTheme.successColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDemo
                    ? AppTheme.warningColor.withValues(alpha: 0.4)
                    : AppTheme.successColor.withValues(alpha: 0.4),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDemo ? AppTheme.warningColor : AppTheme.successColor,
                    boxShadow: [
                      BoxShadow(
                        color: (isDemo ? AppTheme.warningColor : AppTheme.successColor)
                            .withValues(alpha: 0.7),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  isDemo ? 'DEMO' : 'LIVE',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                    color: isDemo ? AppTheme.warningColor : AppTheme.successColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DiagnoseButton extends StatelessWidget {
  final VoidCallback onTap;
  const _DiagnoseButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGradient,
          borderRadius: BorderRadius.circular(18),
          boxShadow: AppTheme.glowShadow(AppTheme.primaryColor, intensity: 0.4),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.auto_awesome_rounded, color: Colors.black, size: 22),
            const SizedBox(width: 12),
            Text(
              'ANALIZAR CON IA',
              style: TextStyle(
                fontFamily: 'Rajdhani',
                fontSize: 20,
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
