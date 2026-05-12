import 'dart:async';
import 'package:flutter/material.dart';
import 'package:vehicle_predictive_maintenance_app/models/vehicle_reading.dart';
import 'package:vehicle_predictive_maintenance_app/services/mock_obd_service.dart';

/// Proveedor global de lecturas OBD-II en tiempo real.
/// Mantiene la última lectura disponible para todos los widgets.
class DiagnosticsProvider with ChangeNotifier {
  final MockObdService _obdService = MockObdService();
  StreamSubscription<VehicleReading>? _subscription;

  final List<VehicleReading> _readings = [];
  VehicleReading? _latestReading;
  bool _isRunning = false;

  List<VehicleReading> get readings => List.unmodifiable(_readings);
  VehicleReading? get latestReading => _latestReading;
  bool get isRunning => _isRunning;

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

  void startStream() {
    if (_isRunning) return;
    _isRunning = true;
    _obdService.start();
    _subscription = _obdService.stream.listen((reading) {
      _latestReading = reading;
      _readings.add(reading);
      if (_readings.length > 20) _readings.removeAt(0);
      notifyListeners();
    });
  }

  void stopStream() {
    _isRunning = false;
    _subscription?.cancel();
    _obdService.stop();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _obdService.dispose();
    super.dispose();
  }
}
