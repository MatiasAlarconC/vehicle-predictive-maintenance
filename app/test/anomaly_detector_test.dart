import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:vehicle_predictive_maintenance_app/services/anomaly/anomaly_detector.dart';

/// Compara el detector de la aplicación con el de la evaluación (Python):
/// mismas lecturas, mismas reconstrucciones del modelo .tflite y, por tanto,
/// mismos puntajes, alertas y señal indicada.
void main() {
  final config = AnomalyConfig.fromJson(File('assets/ml/vera_config.json').readAsStringSync());
  final fixture = jsonDecode(File('test/fixtures/detector_case.json').readAsStringSync()) as Map<String, dynamic>;
  final readings = (fixture['lecturas'] as List)
      .map((r) => (r as List).map((v) => (v as num).toDouble()).toList())
      .toList();
  final expected = (fixture['esperado'] as List).cast<Map<String, dynamic>>();

  test('la configuración corresponde a doce señales y ventanas de 60 s', () {
    expect(config.signals.length, 12);
    expect(config.window, 60);
    expect(config.step, 5);
    expect(config.referenceError.length, 12);
  });

  test('reproduce puntajes, alertas y atribución de la evaluación', () {
    var k = 0;
    final detector = AnomalyDetector(config, (Float32List input) {
      final rec = (expected[k]['reconstruccion'] as List);
      return Float32List.fromList([for (final v in rec) (v as num).toDouble()]);
    });
    final results = <AnomalyResult>[];
    for (final r in readings) {
      final res = detector.add(r);
      if (res != null) {
        results.add(res);
        k++;
      }
    }
    expect(results.length, expected.length);
    for (var i = 0; i < results.length; i++) {
      final e = expected[i];
      final want = (e['puntaje'] as num).toDouble();
      expect(results[i].sample, e['muestra']);
      expect(results[i].score, closeTo(want, 1e-3 * (1 + want.abs())), reason: 'ventana $i');
      expect(results[i].alert, e['alerta'], reason: 'ventana $i');
      if (results[i].exceeds) {
        expect(config.signals[results[i].topSignals.first], e['senal']);
      }
    }
    expect(results.any((r) => r.alert), isTrue);
    expect(results.first.alert, isFalse);
  });

  test('no evalúa antes de llenar la ventana y rechaza lecturas incompletas', () {
    final detector = AnomalyDetector(config, (w) => w);
    for (var i = 0; i < config.window - 1; i++) {
      expect(detector.add(readings[i]), isNull);
    }
    final first = detector.add(readings[config.window - 1]);
    expect(first, isNotNull);
    expect(first!.score, 0);
    expect(first.alert, isFalse);
    expect(() => detector.add([1, 2, 3]), throwsArgumentError);
  });
}
