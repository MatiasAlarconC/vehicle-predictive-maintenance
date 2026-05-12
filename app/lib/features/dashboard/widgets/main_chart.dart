import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:vehicle_predictive_maintenance_app/app/theme/app_theme.dart';
import 'package:vehicle_predictive_maintenance_app/models/vehicle_reading.dart';

class MainChart extends StatelessWidget {
  final List<VehicleReading> readings;

  const MainChart({super.key, required this.readings});

  @override
  Widget build(BuildContext context) {
    final spots = readings.isEmpty
        ? _demoSpots()
        : readings
            .asMap()
            .entries
            .map((e) => FlSpot(e.key.toDouble(), e.value.engineTemp))
            .toList();

    return SizedBox(
      height: 120,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => FlLine(
              color: AppTheme.borderColor.withValues(alpha: 0.5),
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 32,
                getTitlesWidget: (value, _) => Text(
                  '${value.toInt()}',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppTheme.textSecondary.withValues(alpha: 0.6),
                  ),
                ),
                interval: 20,
              ),
            ),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          minY: 60,
          maxY: 120,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.35,
              color: AppTheme.primaryColor,
              barWidth: 2.5,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryColor.withValues(alpha: 0.2),
                    AppTheme.primaryColor.withValues(alpha: 0.0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
        duration: const Duration(milliseconds: 300),
      ),
    );
  }

  List<FlSpot> _demoSpots() => const [
        FlSpot(0, 88),
        FlSpot(1, 90),
        FlSpot(2, 87),
        FlSpot(3, 92),
        FlSpot(4, 89),
        FlSpot(5, 91),
        FlSpot(6, 88),
      ];
}
