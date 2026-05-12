import 'package:vehicle_predictive_maintenance_app/models/xai_explanation.dart';

class PredictionResult {
  final bool anomaly;
  final double probability;
  final List<XaiExplanation> explanation;

  const PredictionResult({
    required this.anomaly,
    required this.probability,
    required this.explanation,
  });
}
