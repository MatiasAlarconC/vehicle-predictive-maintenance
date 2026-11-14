import 'dart:convert';
import 'dart:typed_data';

/// Configuración exportada junto con el modelo (.tflite): orden de las
/// señales, media y desviación de entrenamiento, error de referencia por
/// señal, umbral y regla de persistencia.
class AnomalyConfig {
  final List<String> signals;
  final List<String> labels;
  final List<double> mean;
  final List<double> scale;
  final List<double> referenceError;
  final double threshold;
  final int persistence;
  final int window;
  final int step;

  const AnomalyConfig({
    required this.signals,
    required this.labels,
    required this.mean,
    required this.scale,
    required this.referenceError,
    required this.threshold,
    required this.persistence,
    required this.window,
    required this.step,
  });

  factory AnomalyConfig.fromJson(String source) {
    final j = jsonDecode(source) as Map<String, dynamic>;
    List<double> nums(String k) =>
        (j[k] as List).map((e) => (e as num).toDouble()).toList();
    return AnomalyConfig(
      signals: (j['senales'] as List).cast<String>(),
      labels: (j['etiquetas'] as List).cast<String>(),
      mean: nums('media'),
      scale: nums('escala'),
      referenceError: nums('error_referencia'),
      threshold: (j['umbral'] as num).toDouble(),
      persistence: j['persistencia'] as int,
      window: j['ventana'] as int,
      step: j['paso'] as int,
    );
  }
}

/// Resultado de evaluar una ventana.
class AnomalyResult {
  final int sample; // número de lecturas recibidas
  final double score; // puntaje s de la ventana
  final bool exceeds; // s supera el umbral
  final bool alert; // se cumple la regla de persistencia
  final List<int> topSignals; // índices de las tres señales con mayor cociente
  final List<double> topRatios;

  const AnomalyResult({
    required this.sample,
    required this.score,
    required this.exceeds,
    required this.alert,
    required this.topSignals,
    required this.topRatios,
  });
}

/// Función que reconstruye una ventana estandarizada (ventana × señales,
/// aplanada por filas). En la aplicación es el autoencoder TensorFlow Lite.
typedef WindowReconstructor = Float32List Function(Float32List window);

/// Detector de anomalías en línea. Reproduce el cálculo de la evaluación:
/// búfer de [AnomalyConfig.window] lecturas, evaluación cada
/// [AnomalyConfig.step] lecturas, error cuadrático medio por señal dividido
/// entre su error de referencia, puntaje igual al máximo cociente y alerta
/// cuando el puntaje supera el umbral en `persistence` evaluaciones seguidas.
class AnomalyDetector {
  final AnomalyConfig config;
  final WindowReconstructor reconstruct;

  final List<Float32List> _buffer = [];
  int _count = 0;
  int _streak = 0;

  AnomalyDetector(this.config, this.reconstruct);

  int get samples => _count;
  bool get isWarm => _buffer.length >= config.window;

  void reset() {
    _buffer.clear();
    _count = 0;
    _streak = 0;
  }

  /// Agrega una lectura (valores físicos, en el orden de `config.signals`).
  /// Devuelve un resultado cada `step` lecturas una vez llena la ventana.
  AnomalyResult? add(List<double> reading) {
    final f = config.signals.length;
    if (reading.length != f) {
      throw ArgumentError('Se esperaban $f señales y llegaron ${reading.length}');
    }
    final z = Float32List(f);
    for (var j = 0; j < f; j++) {
      z[j] = (reading[j] - config.mean[j]) / config.scale[j];
    }
    _buffer.add(z);
    if (_buffer.length > config.window) _buffer.removeAt(0);
    _count++;
    if (_buffer.length < config.window || (_count - config.window) % config.step != 0) {
      return null;
    }
    final w = config.window;
    final input = Float32List(w * f);
    for (var t = 0; t < w; t++) {
      input.setRange(t * f, (t + 1) * f, _buffer[t]);
    }
    final output = reconstruct(input);
    final ratios = List<double>.filled(f, 0);
    for (var j = 0; j < f; j++) {
      var acc = 0.0;
      for (var t = 0; t < w; t++) {
        final e = input[t * f + j] - output[t * f + j];
        acc += e * e;
      }
      ratios[j] = acc / w / config.referenceError[j];
    }
    final order = List<int>.generate(f, (i) => i)
      ..sort((a, b) => ratios[b].compareTo(ratios[a]));
    final score = ratios[order.first];
    final exceeds = score > config.threshold;
    _streak = exceeds ? _streak + 1 : 0;
    final top = order.take(3).toList();
    return AnomalyResult(
      sample: _count,
      score: score,
      exceeds: exceeds,
      alert: _streak >= config.persistence,
      topSignals: top,
      topRatios: [for (final i in top) ratios[i]],
    );
  }
}
