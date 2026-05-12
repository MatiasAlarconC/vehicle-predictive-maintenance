import 'package:dio/dio.dart';
import 'package:vehicle_predictive_maintenance_app/core/constants/app_constants.dart';
import 'package:vehicle_predictive_maintenance_app/models/prediction_request.dart';
import 'package:vehicle_predictive_maintenance_app/models/prediction_response.dart';

class ApiService {
  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 4),
      receiveTimeout: const Duration(seconds: 4),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  Future<PredictionResponse> predict(PredictionRequest request, {String? baseUrl}) async {
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

  Future<bool> pingHealth(String baseUrl) async {
    try {
      final response = await _dio.get('$baseUrl${ApiConstants.healthEndpoint}');
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
