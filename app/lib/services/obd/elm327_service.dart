import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:vehicle_predictive_maintenance_app/services/obd/elm327_protocol.dart';

class Elm327Exception implements Exception {
  final String message;
  const Elm327Exception(this.message);
  @override
  String toString() => 'Elm327Exception: $message';
}

/// Lector OBD-II para adaptadores ELM327 Wi-Fi (socket TCP).
///
/// La mayoría de adaptadores Wi-Fi crean su propia red y escuchan en
/// 192.168.0.10:35000. Las consultas se atienden una a la vez: se envía el
/// comando terminado en '\r' y se espera el indicador '>'.
class Elm327Service {
  static const defaultHost = '192.168.0.10';
  static const defaultPort = 35000;

  Socket? _socket;
  StreamSubscription<List<int>>? _sub;
  final StringBuffer _buffer = StringBuffer();
  Completer<String>? _pending;
  Timer? _timer;
  bool _busy = false;
  final StreamController<List<double>> _controller = StreamController.broadcast();

  Set<String> supportedPids = {};

  /// Lecturas de los doce PIDs (en el orden de [kModelPids]), una por segundo.
  Stream<List<double>> get stream => _controller.stream;
  bool get isConnected => _socket != null;

  /// PIDs del modelo que el vehículo no reporta como soportados.
  List<ObdPid> get missingPids =>
      kModelPids.where((p) => !supportedPids.contains(p.code)).toList();

  Future<void> connect({
    String host = defaultHost,
    int port = defaultPort,
    Duration timeout = const Duration(seconds: 5),
  }) async {
    await disconnect();
    final socket = await Socket.connect(host, port, timeout: timeout);
    socket.setOption(SocketOption.tcpNoDelay, true);
    _socket = socket;
    _sub = socket.listen(_onData, onError: (_) => _fail(), onDone: _fail);
    // Reinicio, sin eco, sin saltos de línea, sin espacios, sin cabeceras y
    // selección automática del protocolo del vehículo.
    for (final c in const ['ATZ', 'ATE0', 'ATL0', 'ATS0', 'ATH0', 'ATSP0']) {
      await command(c);
    }
    supportedPids = {};
    for (final base in const [0x00, 0x20, 0x40]) {
      final code = base.toRadixString(16).padLeft(2, '0').toUpperCase();
      final found = parseSupportedPids(await command('01$code'), base);
      supportedPids.addAll(found);
      // El último bit de cada bloque indica si existe el bloque siguiente.
      final next = (base + 0x20).toRadixString(16).padLeft(2, '0').toUpperCase();
      if (!found.contains(next)) break;
    }
  }

  void _onData(List<int> data) {
    _buffer.write(ascii.decode(data, allowInvalid: true));
    final text = _buffer.toString();
    if (text.contains('>')) {
      _buffer.clear();
      final p = _pending;
      _pending = null;
      p?.complete(text);
    }
  }

  void _fail() {
    final p = _pending;
    _pending = null;
    if (p != null && !p.isCompleted) {
      p.completeError(const Elm327Exception('Conexión cerrada por el adaptador'));
    }
    _socket = null;
  }

  /// Envía un comando y devuelve la respuesta cruda hasta el indicador '>'.
  Future<String> command(String cmd, {Duration timeout = const Duration(seconds: 3)}) {
    final socket = _socket;
    if (socket == null) throw const Elm327Exception('Adaptador no conectado');
    if (_pending != null) throw const Elm327Exception('Hay una consulta en curso');
    final completer = Completer<String>();
    _pending = completer;
    socket.add(ascii.encode('$cmd\r'));
    return completer.future.timeout(timeout, onTimeout: () {
      _pending = null;
      throw Elm327Exception('Sin respuesta a $cmd');
    });
  }

  /// Lee una vez los doce PIDs. Devuelve null si alguno no responde.
  Future<List<double>?> readOnce() async {
    final out = <double>[];
    for (final pid in kModelPids) {
      final v = decodePid(pid, await command('01${pid.code}'));
      if (v == null) return null;
      out.add(v);
    }
    return out;
  }

  /// Inicia la lectura periódica (1 Hz por defecto, como en el entrenamiento).
  void start({Duration period = const Duration(seconds: 1)}) {
    _timer?.cancel();
    _timer = Timer.periodic(period, (_) async {
      if (_busy || _socket == null) return;
      _busy = true;
      try {
        final r = await readOnce();
        if (r != null && !_controller.isClosed) _controller.add(r);
      } catch (e) {
        if (!_controller.isClosed) _controller.addError(e);
      } finally {
        _busy = false;
      }
    });
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> disconnect() async {
    stop();
    await _sub?.cancel();
    _sub = null;
    _socket?.destroy();
    _socket = null;
    _pending = null;
    _buffer.clear();
  }

  Future<void> dispose() async {
    await disconnect();
    await _controller.close();
  }
}
