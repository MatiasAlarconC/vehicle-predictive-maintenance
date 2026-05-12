// models/prediction_request.dart
class PredictionRequest {
  final double engineTemp;
  final double brakePadThickness;
  final double tirePressure;
  final String maintenanceType;

  PredictionRequest({
    required this.engineTemp,
    required this.brakePadThickness,
    required this.tirePressure,
    required this.maintenanceType,
  });

  Map<String, dynamic> toJson() {
    return {
      'engine_temp': engineTemp,
      'brake_pad_thickness': brakePadThickness,
      'tire_pressure': tirePressure,
      'maintenance_type': maintenanceType,
    };
  }
}
