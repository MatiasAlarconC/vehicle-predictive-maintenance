import 'dart:async';
import 'dart:math';

import 'package:vehicle_predictive_maintenance_app/models/vehicle_reading.dart';

class MockObdService {
  final Random _random = Random();
  Timer? _timer;
  final StreamController<VehicleReading> _controller = StreamController.broadcast();

  Stream<VehicleReading> get stream => _controller.stream;

  void start() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 2), (_) {
      _controller.add(_generateReading());
    });
  }

  void stop() {
    _timer?.cancel();
  }

  void dispose() {
    _timer?.cancel();
    _controller.close();
  }

  VehicleReading _generateReading() {
    final isAnomaly = _random.nextDouble() < 0.15;

    final rpm = isAnomaly && _random.nextBool()
        ? 5600 + _random.nextInt(900)
        : 800 + _random.nextInt(3200);

    final temp = isAnomaly && _random.nextBool()
        ? 105 + _random.nextDouble() * 9
        : 70 + _random.nextDouble() * 40;

    final voltage = isAnomaly && _random.nextBool()
        ? 10.8 + _random.nextDouble() * 0.7
        : 12.0 + _random.nextDouble() * 2.8;

    return VehicleReading(
      timestamp: DateTime.now(),
      rpm: rpm.toDouble(),
      engineTemp: temp,
      speed: _random.nextDouble() * 120,
      engineLoad: 20 + _random.nextDouble() * 70,
      voltage: voltage,
      maf: 5 + _random.nextDouble() * 20,
    );
  }
}
