import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:vehicle_predictive_maintenance_app/app/theme/app_theme.dart';
import 'package:vehicle_predictive_maintenance_app/app/widgets/custom_card.dart';
import 'package:vehicle_predictive_maintenance_app/core/enums/app_enums.dart';
import 'package:vehicle_predictive_maintenance_app/core/providers/app_provider.dart';
import 'package:vehicle_predictive_maintenance_app/features/diagnostics/widgets/gauge_widget.dart';
import 'package:vehicle_predictive_maintenance_app/features/diagnostics/widgets/realtime_chart_widget.dart';
import 'package:vehicle_predictive_maintenance_app/models/vehicle_reading.dart';
import 'package:vehicle_predictive_maintenance_app/services/mock_obd_service.dart';

class DiagnosticsScreen extends StatefulWidget {
  const DiagnosticsScreen({super.key});

  @override
  State<DiagnosticsScreen> createState() => _DiagnosticsScreenState();
}

class _DiagnosticsScreenState extends State<DiagnosticsScreen> {
  final MockObdService _mockObdService = MockObdService();
  StreamSubscription<VehicleReading>? _subscription;
  final List<VehicleReading> _readings = <VehicleReading>[];

  @override
  void initState() {
    super.initState();
    _mockObdService.start();
    _subscription = _mockObdService.stream.listen((reading) {
      if (!mounted) return;
      setState(() {
        _readings.add(reading);
        if (_readings.length > 20) {
          _readings.removeAt(0);
        }
      });
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _mockObdService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = context.watch<AppProvider>();
    final latest = _readings.isEmpty
        ? VehicleReading(
            timestamp: DateTime.now(),
            rpm: 900,
            engineTemp: 88,
            speed: 0,
            engineLoad: 35,
            voltage: 12.7,
            maf: 8,
          )
        : _readings.last;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (appProvider.appMode == AppMode.demo)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.warningColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.warningColor),
              ),
              child: const Text(
                'MODO DEMO - Datos simulados',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          CustomCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Lecturas OBD-II en vivo', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    GaugeWidget(label: 'RPM', value: latest.rpm, min: 800, max: 4000, unit: 'rpm'),
                    GaugeWidget(label: 'Motor', value: latest.engineTemp, min: 70, max: 110, unit: '°C'),
                    GaugeWidget(label: 'Velocidad', value: latest.speed, min: 0, max: 120, unit: 'km/h'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          CustomCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Últimas 20 lecturas', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                RealtimeChartWidget(readings: _readings),
              ],
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => context.go('/predict'),
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Analizar con IA'),
            ),
          ),
        ],
      ),
    );
  }
}
