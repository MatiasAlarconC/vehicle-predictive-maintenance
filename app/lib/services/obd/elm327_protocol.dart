/// Protocolo OBD-II (modo 01) sobre un adaptador ELM327: PIDs usados por el
/// detector, decodificación de respuestas y lectura de PIDs soportados.
///
/// Las fórmulas corresponden al estándar SAE J1979.
library;

class ObdPid {
  final String code; // hexadecimal de dos dígitos, p. ej. '0C'
  final String name; // nombre de la señal en el modelo
  final String label; // etiqueta para el usuario
  final int bytes;
  final double Function(List<int> d) decode;

  const ObdPid(this.code, this.name, this.label, this.bytes, this.decode);
}

double _rpm(List<int> d) => (256 * d[0] + d[1]) / 4;
double _byte(List<int> d) => d[0].toDouble();
double _percent(List<int> d) => d[0] * 100 / 255;
double _temp(List<int> d) => d[0] - 40.0;
double _trim(List<int> d) => d[0] / 1.28 - 100;
double _timing(List<int> d) => d[0] / 2 - 64;
double _catalyst(List<int> d) => (256 * d[0] + d[1]) / 10 - 40;
double _voltage(List<int> d) => (256 * d[0] + d[1]) / 1000;

/// Los doce PIDs, en el mismo orden en que el modelo los espera.
const List<ObdPid> kModelPids = [
  ObdPid('0C', 'ENGINE_RPM', 'RPM', 2, _rpm),
  ObdPid('0D', 'VEHICLE_SPEED', 'Velocidad', 1, _byte),
  ObdPid('11', 'THROTTLE', 'Acelerador', 1, _percent),
  ObdPid('04', 'ENGINE_LOAD', 'Carga del motor', 1, _percent),
  ObdPid('05', 'COOLANT_TEMPERATURE', 'Temperatura del refrigerante', 1, _temp),
  ObdPid('07', 'LONG_TERM_FUEL_TRIM_BANK_1', 'Ajuste de combustible (largo plazo)', 1, _trim),
  ObdPid('06', 'SHORT_TERM_FUEL_TRIM_BANK_1', 'Ajuste de combustible (corto plazo)', 1, _trim),
  ObdPid('0B', 'INTAKE_MANIFOLD_PRESSURE', 'Presión del colector (MAP)', 1, _byte),
  ObdPid('0F', 'INTAKE_AIR_TEMP', 'Temperatura del aire de admisión', 1, _temp),
  ObdPid('0E', 'TIMING_ADVANCE', 'Avance de encendido', 1, _timing),
  ObdPid('3C', 'CATALYST_TEMPERATURE_BANK1_SENSOR1', 'Temperatura del catalizador', 2, _catalyst),
  ObdPid('42', 'CONTROL_MODULE_VOLTAGE', 'Voltaje', 2, _voltage),
];

/// Limpia la respuesta cruda del adaptador (eco, espacios, '>' y líneas
/// como SEARCHING...) y devuelve la última línea útil en mayúsculas.
String cleanResponse(String raw) {
  final lines = raw
      .replaceAll('>', '')
      .split(RegExp(r'[\r\n]+'))
      .map((l) => l.replaceAll(' ', '').trim().toUpperCase())
      .where((l) => l.isNotEmpty && !l.startsWith('SEARCHING'))
      .toList();
  return lines.isEmpty ? '' : lines.last;
}

/// Extrae los bytes de datos de una respuesta al modo 01 (`41 <pid> <datos>`).
/// Devuelve null si la respuesta no corresponde al PID o está incompleta
/// (NO DATA, ?, STOPPED...).
List<int>? parseMode01(String response, String pidCode, int bytes) {
  final r = cleanResponse(response);
  final i = r.indexOf('41$pidCode');
  if (i < 0) return null;
  final hex = r.substring(i + 4);
  if (hex.length < 2 * bytes) return null;
  final out = <int>[];
  for (var k = 0; k < bytes; k++) {
    final v = int.tryParse(hex.substring(2 * k, 2 * k + 2), radix: 16);
    if (v == null) return null;
    out.add(v);
  }
  return out;
}

/// Decodifica el valor físico de un PID a partir de la respuesta cruda.
double? decodePid(ObdPid pid, String response) {
  final d = parseMode01(response, pid.code, pid.bytes);
  return d == null ? null : pid.decode(d);
}

/// Interpreta la respuesta a 0100 / 0120 / 0140: mapa de bits con los 32 PIDs
/// siguientes a [base] que el vehículo soporta.
Set<String> parseSupportedPids(String response, int base) {
  final code = base.toRadixString(16).padLeft(2, '0').toUpperCase();
  final d = parseMode01(response, code, 4);
  final out = <String>{};
  if (d == null) return out;
  final bits = (d[0] << 24) | (d[1] << 16) | (d[2] << 8) | d[3];
  for (var i = 0; i < 32; i++) {
    if (bits & (1 << (31 - i)) != 0) {
      out.add((base + i + 1).toRadixString(16).padLeft(2, '0').toUpperCase());
    }
  }
  return out;
}
