import 'package:flutter_test/flutter_test.dart';
import 'package:vehicle_predictive_maintenance_app/services/obd/elm327_protocol.dart';

ObdPid pid(String code) => kModelPids.firstWhere((p) => p.code == code);

void main() {
  test('decodifica los PIDs con las fórmulas del estándar', () {
    expect(decodePid(pid('0C'), '410C1AF8\r\r>'), closeTo(1726.0, 1e-9));
    expect(decodePid(pid('0D'), '41 0D 3C \r\r>'), 60);
    expect(decodePid(pid('05'), '41057B'), 83);
    expect(decodePid(pid('04'), '4104FF'), closeTo(100, 1e-9));
    expect(decodePid(pid('07'), '410780'), closeTo(0, 1e-9));
    expect(decodePid(pid('0E'), '410E92'), closeTo(9, 1e-9));
    expect(decodePid(pid('3C'), '413C1360'), closeTo(456, 1e-9));
    expect(decodePid(pid('42'), '414235AC'), closeTo(13.74, 1e-9));
  });

  test('ignora el eco y los mensajes del adaptador', () {
    expect(decodePid(pid('05'), '0105\rSEARCHING...\r41 05 7B \r\r>'), 83);
    expect(decodePid(pid('05'), 'NO DATA\r\r>'), isNull);
    expect(decodePid(pid('0C'), '410C1A'), isNull);
    expect(decodePid(pid('0C'), '?\r>'), isNull);
  });

  test('interpreta el mapa de bits de PIDs soportados', () {
    // BE1FA813: respuesta típica a 0100
    final s = parseSupportedPids('4100BE1FA813', 0x00);
    expect(s.containsAll(['01', '03', '04', '05', '06', '07', '0C', '0D', '0E', '0F', '11', '1C', '1F', '20']), isTrue);
    expect(s.contains('02'), isFalse);
    expect(s.contains('0B'), isFalse);
    expect(parseSupportedPids('NO DATA', 0x20), isEmpty);
  });
}
