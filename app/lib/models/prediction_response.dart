// models/prediction_response.dart
class ExplanationItem {
  final String variable;
  final double contribution;
  final String direction;

  ExplanationItem({
    required this.variable,
    required this.contribution,
    required this.direction,
  });

  factory ExplanationItem.fromJson(Map<String, dynamic> json) {
    return ExplanationItem(
      variable: json['variable'],
      contribution: json['contribution'],
      direction: json['direction'],
    );
  }
}

class PredictionResponse {
  final bool anomaly;
  final double probability;
  final List<ExplanationItem> explanation;

  PredictionResponse({
    required this.anomaly,
    required this.probability,
    required this.explanation,
  });

  factory PredictionResponse.fromJson(Map<String, dynamic> json) {
    var explanationList = json['explanation'] as List;
    List<ExplanationItem> explanations =
        explanationList.map((i) => ExplanationItem.fromJson(i)).toList();

    return PredictionResponse(
      anomaly: json['anomaly'],
      probability: json['probability'],
      explanation: explanations,
    );
  }
}
