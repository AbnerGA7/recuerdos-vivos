import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// Lee textos en voz alta y escucha respuestas habladas.
///
/// Usa los motores de voz del propio teléfono, en español.
class Voz extends ChangeNotifier {
  final FlutterTts _tts = FlutterTts();
  final SpeechToText _stt = SpeechToText();

  bool leyendo = false;
  bool escuchando = false;
  bool escuchaDisponible = false;
  String textoEscuchado = '';
  String? aviso;

  String? _idiomaEscucha;
  bool _iniciada = false;
  void Function(String texto)? _alTerminar;

  Future<void> iniciar({double velocidad = 0.42}) async {
    if (_iniciada) return;
    _iniciada = true;
    try {
      await _tts.awaitSpeakCompletion(true);
      for (final idioma in ['es-PE', 'es-US', 'es-MX', 'es-ES']) {
        if (await _tts.isLanguageAvailable(idioma) == true) {
          await _tts.setLanguage(idioma);
          break;
        }
      }
      await _tts.setSpeechRate(velocidad);
      await _tts.setPitch(1.0);
      _tts.setStartHandler(() => _cambiarLectura(true));
      _tts.setCompletionHandler(() => _cambiarLectura(false));
      _tts.setCancelHandler(() => _cambiarLectura(false));
      _tts.setErrorHandler((_) => _cambiarLectura(false));
    } catch (e) {
      debugPrint('Lectura en voz alta no disponible: $e');
    }
  }

  void _cambiarLectura(bool valor) {
    leyendo = valor;
    notifyListeners();
  }

  Future<void> cambiarVelocidad(double velocidad) async {
    try {
      await _tts.setSpeechRate(velocidad);
    } catch (_) {}
  }

  /// Lee un texto. Si ya estaba leyendo, lo corta y lee el nuevo.
  Future<void> decir(String texto) async {
    if (escuchando) await detenerEscucha();
    try {
      await _tts.stop();
      leyendo = true;
      notifyListeners();
      await _tts.speak(texto);
    } catch (e) {
      debugPrint('No se pudo leer: $e');
    } finally {
      leyendo = false;
      notifyListeners();
    }
  }

  Future<void> callar() async {
    try {
      await _tts.stop();
    } catch (_) {}
    leyendo = false;
    notifyListeners();
  }

  Future<bool> _prepararEscucha() async {
    if (escuchaDisponible) return true;
    try {
      escuchaDisponible = await _stt.initialize(
        onError: _alError,
        onStatus: _alEstado,
      );
      if (escuchaDisponible) {
        final idiomas = await _stt.locales();
        final espanol = idiomas.where((l) => l.localeId.toLowerCase().startsWith('es'));
        _idiomaEscucha = espanol
                .where((l) => l.localeId.toLowerCase().contains('pe'))
                .firstOrNull
                ?.localeId ??
            espanol.firstOrNull?.localeId;
      }
    } catch (e) {
      debugPrint('Reconocimiento de voz no disponible: $e');
      escuchaDisponible = false;
    }
    if (!escuchaDisponible) {
      aviso = 'Este teléfono no permite responder hablando. Puedes escribir.';
      notifyListeners();
    }
    return escuchaDisponible;
  }

  /// Empieza a escuchar. Llama a [alTerminar] con lo que se entendió.
  Future<void> escuchar(void Function(String texto) alTerminar) async {
    await callar();
    if (!await _prepararEscucha()) return;
    _alTerminar = alTerminar;
    textoEscuchado = '';
    aviso = null;
    escuchando = true;
    notifyListeners();
    try {
      await _stt.listen(
        onResult: _alResultado,
        listenOptions: SpeechListenOptions(
          localeId: _idiomaEscucha,
          // Pausas largas: algunas personas tardan en encontrar la palabra.
          pauseFor: const Duration(seconds: 6),
          listenFor: const Duration(seconds: 60),
          partialResults: true,
          cancelOnError: true,
          listenMode: ListenMode.dictation,
        ),
      );
    } catch (e) {
      debugPrint('No se pudo escuchar: $e');
      escuchando = false;
      aviso = 'No pude usar el micrófono. Revisa el permiso en Ajustes.';
      notifyListeners();
    }
  }

  void _alResultado(SpeechRecognitionResult r) {
    textoEscuchado = r.recognizedWords;
    notifyListeners();
    if (r.finalResult) _terminar();
  }

  void _alEstado(String estado) {
    if (estado == SpeechToText.doneStatus ||
        estado == SpeechToText.notListeningStatus) {
      _terminar();
    }
  }

  void _alError(SpeechRecognitionError e) {
    if (e.errorMsg == 'error_no_match' || e.errorMsg == 'error_speech_timeout') {
      aviso = 'No te escuché bien. Toca el micrófono e inténtalo otra vez.';
    } else if (e.errorMsg == 'error_permission' ||
        e.errorMsg == 'error_insufficient_permissions') {
      aviso = 'Falta el permiso del micrófono.';
    } else {
      aviso = 'No pude escucharte. Puedes intentarlo otra vez o escribir.';
    }
    _terminar();
  }

  void _terminar() {
    if (!escuchando) return;
    escuchando = false;
    final cb = _alTerminar;
    _alTerminar = null;
    notifyListeners();
    if (cb != null && textoEscuchado.trim().isNotEmpty) cb(textoEscuchado.trim());
  }

  Future<void> detenerEscucha() async {
    try {
      await _stt.stop();
    } catch (_) {}
    _terminar();
  }

  @override
  void dispose() {
    unawaited(_tts.stop());
    unawaited(_stt.cancel());
    super.dispose();
  }
}

/// Da acceso al servicio de voz desde cualquier pantalla.
class VozScope extends InheritedNotifier<Voz> {
  const VozScope({super.key, required Voz voz, required super.child})
      : super(notifier: voz);

  static Voz of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<VozScope>()!.notifier!;

  static Voz leer(BuildContext context) =>
      context.getInheritedWidgetOfExactType<VozScope>()!.notifier!;
}
