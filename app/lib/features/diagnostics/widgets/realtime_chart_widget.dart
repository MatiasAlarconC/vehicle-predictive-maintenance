import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:vehicle_predictive_maintenance_app/app/theme/app_theme.dart';
import 'package:vehicle_predictive_maintenance_app/models/vehicle_reading.dart';

class RealtimeChartWidget extends StatelessWidget {
  final List<VehicleReading> readings;

  const RealtimeChartWidget({super.key, required this.readings});

  @override
  Widget build(BuildContext context) {
    final tempSpots = readings
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.engineTemp))
        .toList();

    final rpmSpots = readings
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.rpm / 60))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Leyenda
        Row(
          children: [
            _Legend(color: AppTheme.primaryColor, label: 'Temperatura °C'),
            const SizedBox(width: 20),
            _Legend(color: AppTheme.warningColor, label: 'RPM ÷60'),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 200,
          child: LineChart(
            LineChartData(
              clipData: const FlClipData.all(),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (_) => FlLine(
                  color: AppTheme.borderColor.withValues(alpha: 0.4),
                  strokeWidth: 1,
                ),
              ),
              borderData: FlBorderData(show: false),
              minX: 0,
              maxX: 19,
              minY: 0,
              maxY: 130,
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 36,
                    interval: 40,
                    getTitlesWidget: (value, _) => Text(
                      value.toInt().toString(),
                      style: TextStyle(
                        fontSize: 10,
                        color: AppTheme.textSecondary.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                ),
                rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                bottomTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
              ),
              lineBarsData: [
                // Temperatura
                LineChartBarData(
                  spots: tempSpots.isEmpty
                      ? [const FlSpot(0, 88)]
                      : tempSpots,
                  isCurved: true,
                  curveSmoothness: 0.3,
                  color: AppTheme.primaryColor,
                  barWidth: 2.5,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primaryColor.withValues(alpha: 0.15),
                        Colors.transparent,
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
                // RPM normalizado
                LineChartBarData(
                  spots: rpmSpots.isEmpty
                      ? [const FlSpot(0, 15)]
                      : rpmSpots,
                  isCurved: true,
                  curveSmoothness: 0.3,
                  color: AppTheme.warningColor,
                  barWidth: 2,
                  dotData: const FlDotData(show: false),
                  dashArray: [6, 4],
                  belowBarData: BarAreaData(show: false),
                ),
              ],
            ),
            duration: const Duration(milliseconds: 150),
          ),
        ),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  const _Legend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
        ),
      ],
    );
  }
}
