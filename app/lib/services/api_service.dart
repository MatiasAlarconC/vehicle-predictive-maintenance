import 'package:dio/dio.dart';
import 'package:vehicle_predictive_maintenance_app/core/constants/app_constants.dart';
import 'package:vehicle_predictive_maintenance_app/models/prediction_request.dart';
import 'package:vehicle_predictive_maintenance_app/models/prediction_response.dart';
import 'package:vehicle_predictive_maintenance_app/models/vehicle_reading.dart';

class ApiService {
  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 4),
      receiveTimeout: const Duration(seconds: 4),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  VehicleReading _parseVehicleReading(Map<String, dynamic> json) {
    return VehicleReading(
      timestamp: DateTime.tryParse(json['timestamp']?.toString() ?? '') ??
          DateTime.now(),
      rpm: (json['rpm'] as num?)?.toDouble() ?? 0,
      engineTemp: (json['engine_temp'] as num?)?.toDouble() ?? 0,
      speed: (json['speed'] as num?)?.toDouble() ?? 0,
      engineLoad: (json['engine_load'] as num?)?.toDouble() ?? 0,
      voltage: (json['voltage'] as num?)?.toDouble() ?? 0,
      maf: (json['maf'] as num?)?.toDouble() ?? 0,
      brakePadThickness: (json['brake_pad_thickness'] as num?)?.toDouble(),
      tirePressure: (json['tire_pressure'] as num?)?.toDouble(),
      maintenanceType: json['maintenance_type']?.toString(),
    );
  }

  Future<PredictionResponse> predict(PredictionRequest request,
      {String? baseUrl}) async {
    final response = await _dio.post(
      (baseUrl ?? ApiConstants.baseUrl) + ApiConstants.predictEndpoint,
      data: request.toJson(),
    );

    return PredictionResponse.fromJson(response.data as Map<String, dynamic>);
  }

  Future<PredictionResponse> getDemoPrediction({String? baseUrl}) async {
    final response = await _dio.get(
      (baseUrl ?? ApiConstants.baseUrl) + ApiConstants.demoEndpoint,
    );

    return PredictionResponse.fromJson(response.data as Map<String, dynamic>);
  }

  Future<VehicleReading> getLiveObd({String? baseUrl}) async {
    final response = await _dio.get(
      (baseUrl ?? ApiConstants.baseUrl) + ApiConstants.liveObdEndpoint,
    );

    return _parseVehicleReading(response.data as Map<String, dynamic>);
  }

  Future<bool> pingHealth(String baseUrl) async {
    try {
      final response = await _dio.get('$baseUrl${ApiConstants.healthEndpoint}');
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
