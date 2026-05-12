import 'package:flutter/material.dart';
import 'package:vehicle_predictive_maintenance_app/app/theme/app_theme.dart';

class HealthMeterWidget extends StatelessWidget {
  final double value;

  const HealthMeterWidget({super.key, required this.value});

  @override
  Widget build(BuildContext context) {
    final color = value > 70
        ? AppTheme.successColor
        : value >= 40
            ? AppTheme.warningColor
            : AppTheme.dangerColor;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value),
      duration: const Duration(milliseconds: 850),
      builder: (context, animated, _) {
        return SizedBox(
          width: 180,
          height: 180,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CircularProgressIndicator(
                value: animated / 100,
                strokeWidth: 14,
                backgroundColor: Colors.white.withValues(alpha: 0.1),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${animated.toStringAsFixed(0)}%',
                      style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w800),
                    ),
                    const Text('Vehicle Health'),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
