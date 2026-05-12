import 'dart:math';

import 'package:vehicle_predictive_maintenance_app/models/prediction_result.dart';
import 'package:vehicle_predictive_maintenance_app/models/vehicle_reading.dart';
import 'package:vehicle_predictive_maintenance_app/models/xai_explanation.dart';

class MockMlService {
  final Random _random = Random();

  Future<PredictionResult> predictFromReading(VehicleReading reading) async {
    await Future<void>.delayed(const Duration(milliseconds: 900));

    final anomaly = reading.isAnomalous;
    final probability = anomaly
        ? 0.65 + _random.nextDouble() * 0.30
        : 0.05 + _random.nextDouble() * 0.30;

    final explanation = <XaiExplanation>[
      XaiExplanation(
        variable: 'Temperatura del motor',
        contribution: 0.22 + _random.nextDouble() * 0.25,
        direction: reading.engineTemp > 100 ? 'aumenta riesgo' : 'reduce riesgo',
      ),
      XaiExplanation(
        variable: 'Voltaje de batería',
        contribution: 0.15 + _random.nextDouble() * 0.20,
        direction: reading.voltage < 12 ? 'aumenta riesgo' : 'reduce riesgo',
      ),
      XaiExplanation(
        variable: 'RPM en ralentí',
        contribution: 0.12 + _random.nextDouble() * 0.18,
        direction: reading.rpm > 1500 ? 'aumenta riesgo' : 'reduce riesgo',
      ),
    ];

    return PredictionResult(
      anomaly: anomaly,
      probability: probability.clamp(0.0, 1.0),
      explanation: explanation,
    );
  }
}
