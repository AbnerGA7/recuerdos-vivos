import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../datos/texto.dart';
import 'voz_neuronal.dart';

/// Por qué una escucha terminó sin texto.
enum FalloEscucha { ninguno, silencio, sinPermiso, noDisponible }

/// Lee textos en voz alta y escucha respuestas habladas.
///
/// Para hablar usa la voz neuronal local (Kokoro). Si no está lista o falla,
/// usa la mejor voz en español del teléfono. Para escuchar usa el
/// reconocimiento de voz de Android, que se cierra solo al detectar silencio.
class Voz extends ChangeNotifier {
  final FlutterTts _tts = FlutterTts();
  final SpeechToText _stt = SpeechToText();
  final AudioPlayer _reproductor = AudioPlayer();
  final VozNeuronal neuronal = VozNeuronal();

  bool leyendo = false;
  bool escuchando = false;
  bool escuchaDisponible = false;
  bool usarVozNatural = true;

  /// Frase que se está diciendo ahora, para los subtítulos.
  String fraseActual = '';
  String textoEscuchado = '';
  String? aviso;
  FalloEscucha fallo = FalloEscucha.ninguno;

  /// Volumen del micrófono entre 0 y 1, para animar el botón de voz.
  final ValueNotifier<double> nivel = ValueNotifier(0);

  double _velocidad = 0.42;
  String? _idiomaEscucha;
  bool _iniciada = false;
  int _turno = 0;
  Completer<void>? _finAudio;
  Completer<String?>? _escucha;
  Timer? _cierreSeguro;

  double get velocidad => _velocidad;

  Future<void> iniciar({double velocidad = 0.42, bool vozNatural = true}) async {
    if (_iniciada) return;
    _iniciada = true;
    _velocidad = velocidad;
    usarVozNatural = vozNatural;
    _reproductor.onPlayerComplete.listen((_) => _terminarAudio());
    try {
      await _tts.awaitSpeakCompletion(true);
      await _elegirVozDelTelefono();
      await _tts.setSpeechRate(velocidad);
      await _tts.setPitch(1.0);
    } catch (e) {
      debugPrint('Voz del teléfono no disponible: $e');
    }
    if (vozNatural) unawaited(prepararVozNatural());
  }

  /// Carga la voz neuronal en segundo plano y avisa cuando está lista.
  Future<void> prepararVozNatural({bool reintentar = false}) async {
    notifyListeners();
    await neuronal.preparar(reintentar: reintentar);
    notifyListeners();
  }

  /// Elige la voz en español de mejor calidad instalada en el teléfono.
  Future<void> _elegirVozDelTelefono() async {
    final voces = await _tts.getVoices;
    Map<String, String>? mejor;
    var mejorPuntaje = -1;
    if (voces is List) {
      for (final v in voces) {
        if (v is! Map) continue;
        final idioma = '${v['locale']}'.toLowerCase();
        if (!idioma.startsWith('es')) continue;
        var puntaje = 0;
        if (idioma.contains('us') || idioma.contains('mx') || idioma.contains('419') ||
            idioma.contains('pe')) {
          puntaje += 4;
        }
        if ('${v['quality']}'.contains('high')) puntaje += 3;
        if ('${v['network_required']}' == '0') puntaje += 2;
        if (puntaje > mejorPuntaje) {
          mejorPuntaje = puntaje;
          mejor = {'name': '${v['name']}', 'locale': '${v['locale']}'};
        }
      }
    }
    if (mejor != null) {
      await _tts.setVoice(mejor);
      return;
    }
    for (final idioma in ['es-US', 'es-MX', 'es-ES']) {
      if (await _tts.isLanguageAvailable(idioma) == true) {
        await _tts.setLanguage(idioma);
        return;
      }
    }
  }

  Future<void> cambiarVelocidad(double velocidad) async {
    _velocidad = velocidad;
    try {
      await _tts.setSpeechRate(velocidad);
    } catch (_) {}
  }

  // ---- Hablar ---------------------------------------------------------------

  /// Dice un texto frase por frase. Termina cuando acaba de hablar o
  /// cuando otra llamada lo interrumpe.
  Future<void> decir(String texto) async {
    final frases = partirEnFrases(texto);
    if (frases.isEmpty) return;
    final turno = ++_turno;
    await _silenciar();
    if (escuchando) await detenerEscucha();
    leyendo = true;
    notifyListeners();
    try {
      final natural = usarVozNatural && neuronal.estado == EstadoVozNeuronal.lista;
      // La voz neuronal va de 0.6 (lenta) a 1.2; la del teléfono usa 0.5 como normal.
      final ritmo = (_velocidad * 2).clamp(0.6, 1.2).toDouble();
      Future<String?>? siguiente =
          natural ? neuronal.sintetizar(frases.first, velocidad: ritmo) : null;
      for (var i = 0; i < frases.length; i++) {
        final ruta = await siguiente;
        if (turno != _turno) return;
        siguiente = natural && i + 1 < frases.length
            ? neuronal.sintetizar(frases[i + 1], velocidad: ritmo)
            : null;
        fraseActual = frases[i];
        notifyListeners();
        if (ruta != null) {
          await _reproducir(ruta);
        } else {
          await _tts.speak(frases[i]);
        }
        if (turno != _turno) return;
      }
    } catch (e) {
      debugPrint('No se pudo hablar: $e');
    } finally {
      if (turno == _turno) {
        leyendo = false;
        fraseActual = '';
        notifyListeners();
      }
    }
  }

  Future<void> _reproducir(String ruta) async {
    final fin = Completer<void>();
    _finAudio = fin;
    try {
      await _reproductor.play(DeviceFileSource(ruta));
      await fin.future.timeout(const Duration(seconds: 60), onTimeout: () {});
    } finally {
      unawaited(File(ruta).delete().then((_) {}, onError: (_) {}));
    }
  }

  void _terminarAudio() {
    final fin = _finAudio;
    _finAudio = null;
    if (fin != null && !fin.isCompleted) fin.complete();
  }

  Future<void> _silenciar() async {
    try {
      await _reproductor.stop();
    } catch (_) {}
    _terminarAudio();
    try {
      await _tts.stop();
    } catch (_) {}
  }

  /// Deja de hablar de inmediato.
  Future<void> callar() async {
    _turno++;
    await _silenciar();
    if (leyendo) {
      leyendo = false;
      fraseActual = '';
      notifyListeners();
    }
  }

  // ---- Escuchar -------------------------------------------------------------

  Future<bool> _prepararEscucha() async {
    if (escuchaDisponible) return true;
    try {
      escuchaDisponible = await _stt.initialize(
        onError: _alError,
        onStatus: _alEstado,
        options: [SpeechToText.androidNoBluetooth],
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
      fallo = FalloEscucha.noDisponible;
      aviso = 'No puedo usar el micrófono. Revisa el permiso o escribe tu respuesta.';
      notifyListeners();
    }
    return escuchaDisponible;
  }

  /// Abre el micrófono y espera una frase.
  ///
  /// Se cierra solo cuando la persona deja de hablar. Devuelve lo que
  /// entendió, o null si hubo silencio o un problema (ver [fallo]).
  Future<String?> escucharFrase() async {
    await callar();
    if (escuchando) await detenerEscucha();
    if (!await _prepararEscucha()) return null;
    final espera = Completer<String?>();
    _escucha = espera;
    textoEscuchado = '';
    aviso = null;
    fallo = FalloEscucha.ninguno;
    escuchando = true;
    nivel.value = 0;
    notifyListeners();
    try {
      await _stt.listen(
        onResult: _alResultado,
        onSoundLevelChange: (db) => nivel.value = ((db + 2) / 12).clamp(0.0, 1.0).toDouble(),
        listenOptions: SpeechListenOptions(
          localeId: _idiomaEscucha,
          pauseFor: const Duration(seconds: 4),
          listenFor: const Duration(seconds: 60),
          partialResults: true,
          cancelOnError: true,
          listenMode: ListenMode.dictation,
        ),
      );
    } catch (e) {
      debugPrint('No se pudo escuchar: $e');
      fallo = FalloEscucha.noDisponible;
      aviso = 'No pude abrir el micrófono. Puedes escribir tu respuesta.';
      _terminarEscucha();
    }
    return espera.future;
  }

  void _alResultado(SpeechRecognitionResult r) {
    textoEscuchado = r.recognizedWords;
    notifyListeners();
    if (r.finalResult) _terminarEscucha();
  }

  void _alEstado(String estado) {
    if (estado == SpeechToText.doneStatus) {
      _terminarEscucha();
    } else if (estado == SpeechToText.notListeningStatus && escuchando) {
      // El micrófono se cerró; el texto final llega un instante después.
      escuchando = false;
      nivel.value = 0;
      notifyListeners();
      _cierreSeguro?.cancel();
      _cierreSeguro = Timer(const Duration(seconds: 3), _terminarEscucha);
    }
  }

  void _alError(SpeechRecognitionError e) {
    final m = e.errorMsg;
    if (m.contains('permission')) {
      fallo = FalloEscucha.sinPermiso;
      aviso = 'Falta el permiso del micrófono. Actívalo en los ajustes del teléfono.';
    } else if (m == 'error_no_match' || m == 'error_speech_timeout') {
      fallo = FalloEscucha.silencio;
    } else {
      fallo = FalloEscucha.silencio;
      debugPrint('Error de escucha: $m');
    }
    _terminarEscucha();
  }

  void _terminarEscucha() {
    _cierreSeguro?.cancel();
    final espera = _escucha;
    _escucha = null;
    if (escuchando) {
      escuchando = false;
      nivel.value = 0;
    }
    notifyListeners();
    if (espera == null || espera.isCompleted) return;
    final texto = textoEscuchado.trim();
    if (texto.isEmpty && fallo == FalloEscucha.ninguno) fallo = FalloEscucha.silencio;
    espera.complete(texto.isEmpty ? null : texto);
  }

  /// Cierra el micrófono y entrega lo que se haya entendido hasta ahora.
  Future<void> detenerEscucha() async {
    if (_escucha == null && !escuchando) return;
    try {
      await _stt.stop();
    } catch (_) {}
    _terminarEscucha();
  }

  @override
  void dispose() {
    neuronal.cerrar();
    unawaited(_reproductor.dispose());
    unawaited(_tts.stop());
    unawaited(_stt.cancel());
    nivel.dispose();
    super.dispose();
  }
}

/// Da acceso al servicio de voz desde cualquier pantalla.
class VozScope extends InheritedNotifier<Voz> {
  const VozScope({super.key, required Voz voz, required super.child}) : super(notifier: voz);

  static Voz of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<VozScope>()!.notifier!;

  static Voz leer(BuildContext context) =>
      context.getInheritedWidgetOfExactType<VozScope>()!.notifier!;
}
