import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:tflite_flutter/tflite_flutter.dart';

import 'package:vehicle_predictive_maintenance_app/services/anomaly/anomaly_detector.dart';

const kAnomalyModelAsset = 'assets/ml/vera_ae_conv.tflite';
const kAnomalyConfigAsset = 'assets/ml/vera_config.json';

/// Autoencoder Conv1D en TensorFlow Lite, ejecutado en el teléfono.
class TfliteReconstructor {
  final Interpreter _interpreter;
  final int window;
  final int signals;

  TfliteReconstructor._(this._interpreter, this.window, this.signals);

  static Future<TfliteReconstructor> load({String asset = kAnomalyModelAsset}) async {
    final interpreter = await Interpreter.fromAsset(asset);
    final shape = interpreter.getInputTensor(0).shape; // [1, ventana, señales]
    return TfliteReconstructor._(interpreter, shape[1], shape[2]);
  }

  Float32List call(Float32List input) {
    final output = Float32List(window * signals);
    _interpreter.run(input.buffer, output.buffer);
    return output;
  }

  void close() => _interpreter.close();
}

/// Carga el modelo y su configuración desde los assets y arma el detector.
Future<(AnomalyDetector, TfliteReconstructor)> loadAnomalyDetector() async {
  final config = AnomalyConfig.fromJson(await rootBundle.loadString(kAnomalyConfigAsset));
  final model = await TfliteReconstructor.load();
  return (AnomalyDetector(config, model.call), model);
}
