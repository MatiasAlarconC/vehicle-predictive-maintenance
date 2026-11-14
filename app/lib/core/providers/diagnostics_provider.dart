import 'dart:async';
import 'package:flutter/material.dart';
import 'package:vehicle_predictive_maintenance_app/core/enums/app_enums.dart';
import 'package:vehicle_predictive_maintenance_app/core/providers/app_provider.dart';
import 'package:vehicle_predictive_maintenance_app/models/vehicle_reading.dart';
import 'package:vehicle_predictive_maintenance_app/services/api_service.dart';
import 'package:vehicle_predictive_maintenance_app/services/anomaly/anomaly_detector.dart';
import 'package:vehicle_predictive_maintenance_app/services/anomaly/tflite_reconstructor.dart';
import 'package:vehicle_predictive_maintenance_app/services/mock_obd_service.dart';
import 'package:vehicle_predictive_maintenance_app/services/obd/elm327_protocol.dart';
import 'package:vehicle_predictive_maintenance_app/services/obd/elm327_service.dart';

/// Proveedor global de lecturas OBD-II en tiempo real.
/// Mantiene la última lectura disponible para todos los widgets.
class DiagnosticsProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  final MockObdService _obdService = MockObdService();
  StreamSubscription<VehicleReading>? _subscription;
  Timer? _pollingTimer;

  final List<VehicleReading> _readings = [];
  VehicleReading? _latestReading;
  bool _isRunning = false;
  bool _isUsingDemoFallback = false;
  AppMode _appMode = AppMode.demo;
  String _baseUrl = '';
  AppProvider? _appProvider;

  // Lectura real por ELM327 y detección de anomalías en el dispositivo.
  final Elm327Service _elm327 = Elm327Service();
  StreamSubscription<List<double>>? _obdSubscription;
  AnomalyDetector? _detector;
  TfliteReconstructor? _model;
  AnomalyResult? _latestAnomaly;
  bool _obdConnected = false;
  bool _obdConnecting = false;
  String? _obdError;
  List<String> _missingPids = const [];

  bool get obdConnected => _obdConnected;
  bool get obdConnecting => _obdConnecting;
  String? get obdError => _obdError;
  AnomalyResult? get latestAnomaly => _latestAnomaly;
  bool get detectorReady => _detector != null;

  /// Etiquetas de los PIDs del modelo que el vehículo no soporta.
  List<String> get missingPids => _missingPids;

  /// Lecturas que faltan para llenar la primera ventana del detector.
  int get samplesToWarmUp {
    final d = _detector;
    if (d == null) return 0;
    final left = d.config.window - d.samples;
    return left > 0 ? left : 0;
  }

  /// Etiqueta de la señal que más se aleja de lo normal en la última ventana.
  String? get anomalySignalLabel {
    final a = _latestAnomaly;
    final d = _detector;
    if (a == null || d == null) return null;
    return d.config.labels[a.topSignals.first];
  }

  List<VehicleReading> get readings => List.unmodifiable(_readings);
  VehicleReading? get latestReading => _latestReading;
  bool get isRunning => _isRunning;
  bool get isUsingDemoFallback => _isUsingDemoFallback;

  /// Salud del vehículo calculada a partir de la última lectura (0-100)
  double get vehicleHealth {
    if (_latestReading == null) return 76;
    final r = _latestReading!;
    double score = 100;
    if (r.engineTemp > 100) score -= (r.engineTemp - 100) * 2;
    if (r.voltage < 12.5) score -= (12.5 - r.voltage) * 15;
    if (r.rpm > 4500) score -= (r.rpm - 4500) / 100;
    if (r.isAnomalous) score -= 25;
    return score.clamp(0, 100);
  }

  void updateConfig(AppProvider appProvider) {
    final nextMode = appProvider.appMode;
    final nextBaseUrl = appProvider.baseUrl;
    final shouldRestart =
        _isRunning && (_appMode != nextMode || _baseUrl != nextBaseUrl);

    _appProvider = appProvider;
    _appMode = nextMode;
    _baseUrl = nextBaseUrl;
    _isUsingDemoFallback = nextMode == AppMode.demo;

    if (shouldRestart) {
      stopStream();
      startStream();
    } else {
      notifyListeners();
    }
  }

  void startStream() {
    if (_isRunning || _obdConnected) return;
    _isRunning = true;
    if (_appMode == AppMode.production) {
      _startProductionPolling();
      return;
    }
    _startDemoStream();
  }

  void _startDemoStream() {
    _isUsingDemoFallback = true;
    _obdService.start();
    _subscription = _obdService.stream.listen(_pushReading);
    notifyListeners();
  }

  void _startProductionPolling() {
    _isUsingDemoFallback = false;
    unawaited(_fetchProductionReading());
    _pollingTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      unawaited(_fetchProductionReading());
    });
    notifyListeners();
  }

  Future<void> _fetchProductionReading() async {
    try {
      final reading = await _apiService.getLiveObd(baseUrl: _baseUrl);
      _isUsingDemoFallback = false;
      unawaited(_appProvider?.setConnection(true) ?? Future.value());
      _pushReading(reading);
    } catch (_) {
      await _fallbackToDemo();
    }
  }

  Future<void> _fallbackToDemo() async {
    if (_appMode == AppMode.demo && _isUsingDemoFallback) return;

    _pollingTimer?.cancel();
    _pollingTimer = null;

    _appMode = AppMode.demo;
    _isUsingDemoFallback = true;
    await _appProvider?.setConnection(false);
    await _appProvider?.setAppMode(AppMode.demo);

    if (_subscription == null) {
      _startDemoStream();
    } else {
      notifyListeners();
    }
  }

  /// Conecta con el adaptador ELM327 Wi-Fi, verifica los PIDs soportados y
  /// empieza a leer una vez por segundo. El detector solo se activa si el
  /// vehículo expone las doce señales del modelo.
  Future<bool> connectObd({
    String host = Elm327Service.defaultHost,
    int port = Elm327Service.defaultPort,
  }) async {
    if (_obdConnecting) return false;
    _obdConnecting = true;
    _obdError = null;
    notifyListeners();
    try {
      await _elm327.connect(host: host, port: port);
      _missingPids = [for (final p in _elm327.missingPids) p.label];
      if (_missingPids.isEmpty && _detector == null) {
        try {
          final (detector, model) = await loadAnomalyDetector();
          _detector = detector;
          _model = model;
        } catch (e) {
          _obdError = 'No se pudo cargar el modelo: $e';
        }
      }
      _detector?.reset();
      _latestAnomaly = null;
      stopStream();
      _isRunning = true;
      _isUsingDemoFallback = false;
      _obdConnected = true;
      _obdSubscription = _elm327.stream.listen(_onObdSample, onError: (Object e) {
        _obdError = e.toString();
        unawaited(disconnectObd());
      });
      _elm327.start();
      return true;
    } catch (e) {
      _obdError = e.toString();
      _obdConnected = false;
      return false;
    } finally {
      _obdConnecting = false;
      notifyListeners();
    }
  }

  Future<void> disconnectObd() async {
    await _obdSubscription?.cancel();
    _obdSubscription = null;
    await _elm327.disconnect();
    _obdConnected = false;
    _latestAnomaly = null;
    _isRunning = false;
    startStream();
    notifyListeners();
  }

  void _onObdSample(List<double> s) {
    double v(String code) => s[kModelPids.indexWhere((p) => p.code == code)];
    if (_missingPids.isEmpty) {
      final result = _detector?.add(s);
      if (result != null) _latestAnomaly = result;
    }
    _pushReading(VehicleReading(
      timestamp: DateTime.now(),
      rpm: v('0C'),
      engineTemp: v('05'),
      speed: v('0D'),
      engineLoad: v('04'),
      voltage: v('42'),
      maf: 0,
    ));
  }

  void _pushReading(VehicleReading reading) {
    _latestReading = reading;
    _readings.add(reading);
    if (_readings.length > 20) {
      _readings.removeAt(0);
    }
    notifyListeners();
  }

  void stopStream() {
    _isRunning = false;
    _subscription?.cancel();
    _subscription = null;
    _pollingTimer?.cancel();
    _pollingTimer = null;
    _obdService.stop();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _pollingTimer?.cancel();
    _obdService.dispose();
    _obdSubscription?.cancel();
    unawaited(_elm327.dispose());
    _model?.close();
    super.dispose();
  }
}
