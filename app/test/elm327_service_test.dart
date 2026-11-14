import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:vehicle_predictive_maintenance_app/services/obd/elm327_protocol.dart';
import 'package:vehicle_predictive_maintenance_app/services/obd/elm327_service.dart';

/// Prueba de la lectura por socket contra el emulador de ELM327 del proyecto
/// (ml/si2/elm327.py). Se ejecuta solo si VERA_ELM_PORT está definido:
///   python ml/si2/elm327.py 35000 drive12 &
///   VERA_ELM_PORT=35000 flutter test test/elm327_service_test.dart
void main() {
  final port = int.tryParse(Platform.environment['VERA_ELM_PORT'] ?? '');

  test('lee los doce PIDs del emulador ELM327', () async {
    final fixture = jsonDecode(File('test/fixtures/detector_case.json').readAsStringSync()) as Map<String, dynamic>;
    final first = (fixture['primeras_lecturas'] as List)
        .map((r) => (r as List).map((v) => (v as num).toDouble()).toList())
        .toList();
    final elm = Elm327Service();
    await elm.connect(host: '127.0.0.1', port: port!);
    expect(elm.missingPids, isEmpty);
    // Resolución de cada PID según su codificación (medio paso de cuantización).
    const tol = [0.13, 0.5, 0.2, 0.2, 0.5, 0.4, 0.4, 0.5, 0.5, 0.25, 0.05, 0.001];
    for (var t = 0; t < first.length; t++) {
      final r = await elm.readOnce();
      expect(r, isNotNull);
      expect(r!.length, kModelPids.length);
      for (var j = 0; j < r.length; j++) {
        expect(r[j], closeTo(first[t][j], tol[j] + 1e-6), reason: 'lectura $t, ${kModelPids[j].name}');
      }
    }
    await elm.dispose();
  }, skip: port == null ? 'Defina VERA_ELM_PORT con el puerto del emulador' : false);
}
