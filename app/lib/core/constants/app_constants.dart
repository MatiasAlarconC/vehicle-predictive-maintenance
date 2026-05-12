class ApiConstants {
  static const String baseUrl = 'http://127.0.0.1:8000';
  static const String predictEndpoint = '/predict';
  static const String liveObdEndpoint = '/obd/live';
  static const String historyEndpoint = '/history';
  static const String healthEndpoint = '/health';
  static const String demoEndpoint = '/demo';
}

class AppConstants {
  static const String appName = 'vehicle_predictive_maintenance';
  static const String datasetName = 'Hyundai Cars Maintenance Dataset';
  static const String defaultIp = '127.0.0.1';
  static const String defaultPort = '8000';
}
