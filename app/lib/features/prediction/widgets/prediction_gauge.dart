import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:vehicle_predictive_maintenance_app/app/theme/app_theme.dart';

class PredictionGauge extends StatelessWidget {
  final double probability;

  const PredictionGauge({super.key, required this.probability});

  @override
  Widget build(BuildContext context) {
    final probabilityPercent = probability * 100;
    final color = probability > 0.7 ? AppTheme.errorColor : (probability > 0.4 ? AppTheme.warningColor : AppTheme.successColor);

    return SizedBox(
      height: 200,
      width: 200,
      child: PieChart(
        PieChartData(
          startDegreeOffset: -90,
          sectionsSpace: 0,
          centerSpaceRadius: 70,
          sections: [
            PieChartSectionData(
              value: probabilityPercent,
              color: color,
              radius: 25,
              showTitle: false,
            ),
            PieChartSectionData(
              value: 100 - probabilityPercent,
              color: color.withOpacity(0.2),
              radius: 25,
              showTitle: false,
            ),
          ],
        ),
      ),
    );
  }
}
