import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:vehicle_predictive_maintenance_app/app/theme/app_theme.dart';
import 'package:vehicle_predictive_maintenance_app/models/vehicle_reading.dart';

class RealtimeChartWidget extends StatelessWidget {
  final List<VehicleReading> readings;

  const RealtimeChartWidget({super.key, required this.readings});

  @override
  Widget build(BuildContext context) {
    final points = readings
        .asMap()
        .entries
        .map((entry) => FlSpot(entry.key.toDouble(), entry.value.engineTemp))
        .toList();

    return SizedBox(
      height: 220,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            getDrawingHorizontalLine: (_) => FlLine(
              color: Colors.white.withValues(alpha: 0.08),
            ),
            getDrawingVerticalLine: (_) => FlLine(
              color: Colors.white.withValues(alpha: 0.05),
            ),
          ),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: 19,
          minY: 65,
          maxY: 120,
          titlesData: const FlTitlesData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: points,
              isCurved: true,
              color: AppTheme.primaryColor,
              barWidth: 3,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: AppTheme.primaryColor.withValues(alpha: 0.15),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
