import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:vehicle_predictive_maintenance_app/app/theme/app_theme.dart';
import 'package:vehicle_predictive_maintenance_app/app/widgets/custom_card.dart';
import 'package:vehicle_predictive_maintenance_app/core/providers/app_provider.dart';
import 'package:vehicle_predictive_maintenance_app/features/dashboard/widgets/health_meter_widget.dart';
import 'package:vehicle_predictive_maintenance_app/features/dashboard/widgets/main_chart.dart';
import 'package:vehicle_predictive_maintenance_app/features/dashboard/widgets/status_card_widget.dart';

class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final appProvider = context.watch<AppProvider>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Vehicle Predictive\nMaintenance',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              Chip(
                backgroundColor: appProvider.appMode.name == 'demo'
                    ? AppTheme.warningColor.withValues(alpha: 0.2)
                    : AppTheme.successColor.withValues(alpha: 0.2),
                side: BorderSide(
                  color: appProvider.appMode.name == 'demo'
                      ? AppTheme.warningColor
                      : AppTheme.successColor,
                ),
                label: Text(
                  appProvider.appMode.name == 'demo' ? 'Demo' : 'Conectado',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Center(child: HealthMeterWidget(value: 76)),
          const SizedBox(height: 16),
          const GridView(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 2.3,
            ),
            children: [
              StatusCardWidget(
                title: 'Motor',
                value: 'Estable',
                icon: Icons.precision_manufacturing,
                color: AppTheme.successColor,
              ),
              StatusCardWidget(
                title: 'Batería',
                value: '12.7 V',
                icon: Icons.battery_5_bar,
                color: AppTheme.primaryColor,
              ),
              StatusCardWidget(
                title: 'Frenos',
                value: 'En control',
                icon: Icons.car_repair,
                color: AppTheme.warningColor,
              ),
              StatusCardWidget(
                title: 'Temperatura',
                value: '88 °C',
                icon: Icons.thermostat,
                color: AppTheme.dangerColor,
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => context.go('/diagnostics'),
              icon: const Icon(Icons.play_circle_fill),
              label: const Text('Iniciar Diagnóstico'),
            ),
          ),
          const SizedBox(height: 16),
          CustomCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Historial de salud',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => context.go('/history'),
                      child: const Text('Ver historial'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const MainChart(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
