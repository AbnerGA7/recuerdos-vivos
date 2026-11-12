import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa;

/// Estado de la voz neuronal.
enum EstadoVozNeuronal { apagada, preparando, lista, noDisponible }

/// Voz neuronal local (Piper) que genera el audio dentro del teléfono.
///
/// El modelo corre en un isolate aparte para no trabar la pantalla.
/// Cada frase se convierte en un archivo WAV que luego se reproduce.
class VozNeuronal {
  EstadoVozNeuronal estado = EstadoVozNeuronal.apagada;

  SendPort? _envio;
  Isolate? _isolate;
  late Directory _temporal;
  int _pedido = 0;
  final Map<int, Completer<String?>> _pendientes = {};

  static const _version = 'voz_v1';

  /// Copia el modelo a la carpeta privada (solo la primera vez) y lo carga.
  ///
  /// Antes de cargar deja una marca en disco y la borra al terminar bien.
  /// Si la app se cierra durante la carga, la marca queda y en el siguiente
  /// arranque la voz neuronal se desactiva sola para que la app siga
  /// funcionando con la voz del teléfono. Con [reintentar] se vuelve a probar.
  Future<bool> preparar({bool reintentar = false}) async {
    if (estado == EstadoVozNeuronal.lista) return true;
    if (estado == EstadoVozNeuronal.preparando) return false;
    estado = EstadoVozNeuronal.preparando;
    try {
      final base = await getApplicationSupportDirectory();
      final guardia = File('${base.path}/voz_cargando');
      if (await guardia.exists()) {
        if (!reintentar) {
          debugPrint('La voz neuronal cerró la app la última vez; se desactiva.');
          estado = EstadoVozNeuronal.noDisponible;
          return false;
        }
        await guardia.delete();
      }
      await guardia.create(recursive: true);
      final carpeta = Directory('${base.path}/$_version');
      final marca = File('${carpeta.path}/listo');
      if (!await marca.exists()) {
        await carpeta.create(recursive: true);
        await _copiar('assets/voz/voz.onnx', '${carpeta.path}/voz.onnx');
        await _copiar('assets/voz/tokens.txt', '${carpeta.path}/tokens.txt');
        final zip = await rootBundle.load('assets/voz/espeak.zip');
        await compute(_descomprimir, (zip.buffer.asUint8List(), carpeta.path));
        await marca.writeAsString('ok');
      }
      _temporal = Directory('${(await getTemporaryDirectory()).path}/frases');
      if (await _temporal.exists()) await _temporal.delete(recursive: true);
      await _temporal.create(recursive: true);

      final recepcion = ReceivePort();
      final listo = Completer<bool>();
      recepcion.listen((mensaje) {
        if (mensaje is SendPort) {
          _envio = mensaje;
        } else if (mensaje is bool) {
          if (!listo.isCompleted) listo.complete(mensaje);
        } else if (mensaje is (int, String?)) {
          _pendientes.remove(mensaje.$1)?.complete(mensaje.$2);
        }
      });
      _isolate = await Isolate.spawn(
        _trabajar,
        (recepcion.sendPort, carpeta.path),
        errorsAreFatal: false,
      );
      final cargo = await listo.future.timeout(const Duration(seconds: 60), onTimeout: () => false);
      await guardia.delete();
      estado = cargo ? EstadoVozNeuronal.lista : EstadoVozNeuronal.noDisponible;
    } catch (e) {
      debugPrint('Voz neuronal no disponible: $e');
      estado = EstadoVozNeuronal.noDisponible;
    }
    return estado == EstadoVozNeuronal.lista;
  }

  static Future<void> _copiar(String recurso, String destino) async {
    final datos = await rootBundle.load(recurso);
    await File(destino).writeAsBytes(
      datos.buffer.asUint8List(datos.offsetInBytes, datos.lengthInBytes),
      flush: true,
    );
  }

  /// Genera el audio de una frase. Devuelve la ruta del WAV o null si falla.
  Future<String?> sintetizar(String texto, {double velocidad = 1.0}) {
    final envio = _envio;
    if (estado != EstadoVozNeuronal.lista || envio == null) return Future.value();
    final id = ++_pedido;
    final espera = Completer<String?>();
    _pendientes[id] = espera;
    envio.send((id, texto, velocidad, '${_temporal.path}/f$id.wav'));
    return espera.future.timeout(const Duration(seconds: 30), onTimeout: () {
      _pendientes.remove(id);
      return null;
    });
  }

  void cerrar() {
    _isolate?.kill(priority: Isolate.immediate);
    _isolate = null;
    _envio = null;
    estado = EstadoVozNeuronal.apagada;
  }
}

/// Extrae el zip de datos de pronunciación. Corre fuera del hilo principal.
void _descomprimir((Uint8List, String) entrada) {
  final (bytes, destino) = entrada;
  for (final archivo in ZipDecoder().decodeBytes(bytes)) {
    final ruta = '$destino/${archivo.name}';
    if (archivo.isFile) {
      File(ruta)
        ..createSync(recursive: true)
        ..writeAsBytesSync(archivo.content);
    } else {
      Directory(ruta).createSync(recursive: true);
    }
  }
}

/// Punto de entrada del isolate: carga el modelo y atiende pedidos.
void _trabajar((SendPort, String) entrada) {
  final (salida, carpeta) = entrada;
  final pedidos = ReceivePort();
  salida.send(pedidos.sendPort);
  sherpa.OfflineTts? tts;
  try {
    // Comprueba los archivos antes de cargar: si falta alguno, el motor
    // nativo cerraría la app en lugar de devolver un error.
    for (final ruta in ['voz.onnx', 'tokens.txt', 'espeak-ng-data/phontab']) {
      if (!File('$carpeta/$ruta').existsSync()) throw StateError('Falta $ruta');
    }
    sherpa.initBindings();
    tts = sherpa.OfflineTts(
      sherpa.OfflineTtsConfig(
        model: sherpa.OfflineTtsModelConfig(
          vits: sherpa.OfflineTtsVitsModelConfig(
            model: '$carpeta/voz.onnx',
            tokens: '$carpeta/tokens.txt',
            dataDir: '$carpeta/espeak-ng-data',
          ),
          numThreads: 2,
        ),
      ),
    );
    // Frase de prueba: confirma que el modelo genera audio antes de usarlo.
    final prueba = tts.generate(text: 'Hola.');
    salida.send(prueba.samples.isNotEmpty);
  } catch (_) {
    salida.send(false);
    return;
  }
  pedidos.listen((mensaje) {
    if (mensaje is! (int, String, double, String)) return;
    final (id, texto, velocidad, ruta) = mensaje;
    try {
      final audio = tts!.generate(text: texto, speed: velocidad);
      final ok = sherpa.writeWave(
        filename: ruta,
        samples: audio.samples,
        sampleRate: audio.sampleRate,
      );
      salida.send((id, ok ? ruta : null));
    } catch (_) {
      salida.send((id, null));
    }
  });
}
