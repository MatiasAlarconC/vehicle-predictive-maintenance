import 'package:flutter/material.dart';
import 'package:vehicle_predictive_maintenance_app/core/enums/app_enums.dart';
import 'package:vehicle_predictive_maintenance_app/models/prediction_request.dart';
import 'package:vehicle_predictive_maintenance_app/models/prediction_response.dart';
import 'package:vehicle_predictive_maintenance_app/models/vehicle_reading.dart';
import 'package:vehicle_predictive_maintenance_app/services/api_service.dart';
import 'package:vehicle_predictive_maintenance_app/services/mock_ml_service.dart';

class PredictionProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  final MockMlService _mockMlService = MockMlService();

  PredictionStatus _status = PredictionStatus.initial;
  PredictionStatus get status => _status;

  PredictionResponse? _predictionResponse;
  PredictionResponse? get predictionResponse => _predictionResponse;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  /// Realiza predicción usando una lectura OBD-II directa (flujo principal desde Diagnóstico)
  Future<void> predictFromReading(
    VehicleReading reading,
    AppMode appMode, {
    required String baseUrl,
    required Future<void> Function() onFallbackToDemo,
  }) async {
    _status = PredictionStatus.loading;
    _predictionResponse = null;
    _errorMessage = null;
    notifyListeners();

    try {
      if (appMode == AppMode.demo) {
        final mockResult = await _mockMlService.predictFromReading(reading);
        _predictionResponse = PredictionResponse(
          anomaly: mockResult.anomaly,
          probability: mockResult.probability,
          explanation: mockResult.explanation
              .map((e) => ExplanationItem(
                    variable: e.variable,
                    contribution: e.contribution,
                    direction: e.direction,
                  ))
              .toList(),
        );
      } else {
        try {
          final request = PredictionRequest(
            engineTemp: reading.engineTemp,
            brakePadThickness: 8.0,
            tirePressure: 32.0,
            maintenanceType: 'Routine Maintenance',
          );
          _predictionResponse = await _apiService.predict(request, baseUrl: baseUrl);
        } catch (_) {
          await onFallbackToDemo();
          final mockResult = await _mockMlService.predictFromReading(reading);
          _predictionResponse = PredictionResponse(
            anomaly: mockResult.anomaly,
            probability: mockResult.probability,
            explanation: mockResult.explanation
                .map((e) => ExplanationItem(
                      variable: e.variable,
                      contribution: e.contribution,
                      direction: e.direction,
                    ))
                .toList(),
          );
        }
      }
      _status = PredictionStatus.success;
    } catch (e) {
      _status = PredictionStatus.error;
      _errorMessage = e.toString();
    }
    notifyListeners();
  }

  /// Realiza predicción con request manual (compatibilidad)
  Future<void> makePrediction(
    PredictionRequest request,
    AppMode appMode, {
    required String baseUrl,
    required Future<void> Function() onFallbackToDemo,
  }) async {
    final reading = VehicleReading(
      timestamp: DateTime.now(),
      rpm: 850,
      engineTemp: request.engineTemp,
      speed: 40,
      engineLoad: 42,
      voltage: 12.8,
      maf: 10,
    );
    await predictFromReading(reading, appMode,
        baseUrl: baseUrl, onFallbackToDemo: onFallbackToDemo);
  }

  void reset() {
    _status = PredictionStatus.initial;
    _predictionResponse = null;
    _errorMessage = null;
    notifyListeners();
  }
}
