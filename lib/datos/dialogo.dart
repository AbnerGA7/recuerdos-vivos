import 'modelos.dart';
import 'preguntas.dart';
import 'texto.dart';

/// Lo que la persona quiso pedir con su frase.
enum Intencion { ninguna, repetir, pista, siguiente, terminar, noSabe, despacio }

/// Detecta órdenes habladas como "repite", "dame una pista" o "no sé".
Intencion detectarIntencion(String texto) {
  final n = ' ${normalizar(texto)} ';
  final corta = n.trim().split(' ').length <= 6;
  bool tiene(List<String> frases) => frases.any((f) => n.contains(' $f '));

  if (tiene(['no se', 'no lo se', 'no recuerdo', 'no me acuerdo', 'ni idea',
      'no tengo idea', 'se me olvido', 'no sabria'])) {
    return Intencion.noSabe;
  }
  if (!corta) return Intencion.ninguna;
  if (tiene(['terminar', 'terminemos', 'terminamos', 'ya no quiero', 'basta',
      'hasta aqui', 'paremos', 'estoy cansado', 'estoy cansada'])) {
    return Intencion.terminar;
  }
  if (tiene(['mas despacio', 'mas lento', 'muy rapido'])) return Intencion.despacio;
  if (tiene(['repite', 'repetir', 'repiteme', 'repitelo', 'otra vez', 'de nuevo',
      'no escuche', 'no te escuche', 'como dijiste'])) {
    return Intencion.repetir;
  }
  if (tiene(['pista', 'ayuda', 'ayudame', 'ayudita'])) return Intencion.pista;
  if (tiene(['siguiente', 'otra pregunta', 'pasemos', 'la que sigue'])) {
    return Intencion.siguiente;
  }
  return Intencion.ninguna;
}

/// Respuesta de la app a un turno de la conversación.
class Reaccion {
  const Reaccion(this.decir, {this.fin = false, this.masDespacio = false});

  /// Lo que la app dice en voz alta y muestra en pantalla.
  final String decir;

  /// La conversación terminó.
  final bool fin;

  /// La persona pidió que la voz vaya más lenta.
  final bool masDespacio;
}

/// Conduce la conversación sobre una foto.
///
/// Compara lo que la persona dice con lo que escribió el familiar y
/// responde con calidez. Nunca corrige: si la respuesta no coincide,
/// ofrece pistas cada vez más claras y al final cuenta el dato con cariño.
class MotorDialogo {
  MotorDialogo(this.recuerdo, {this.nombre = ''}) : preguntas = armarPreguntas(recuerdo);

  final Recuerdo recuerdo;
  final String nombre;
  final List<Pregunta> preguntas;

  /// Respuestas guardadas para el diario.
  final List<Respuesta> respuestas = [];

  int indice = 0;
  int _pistasDadas = 0;
  int _animos = 0;
  bool _enSeguimiento = false;
  final Set<int> _halladas = {};
  final List<String> _dicho = [];

  bool get terminado => indice >= preguntas.length;
  Pregunta get _actual => preguntas[indice];
  String get preguntaActual => terminado ? '' : _actual.texto;

  static const _frasesAnimo = [
    'Gracias por contármelo.',
    'Qué bonito.',
    'Me encanta escucharte.',
    'Qué lindo recuerdo.',
    'Muy bien.',
  ];

  String _animo() => _frasesAnimo[_animos++ % _frasesAnimo.length];

  /// Primera frase de la conversación.
  Reaccion abrir() {
    final hola = nombre.trim().isEmpty ? 'Hola' : 'Hola, ${nombre.trim()}';
    return Reaccion('$hola. Vamos a mirar esta foto juntos, con calma. $preguntaActual');
  }

  /// Procesa lo que la persona dijo o escribió.
  Reaccion escuchar(String texto) {
    if (terminado) return const Reaccion('', fin: true);
    switch (detectarIntencion(texto)) {
      case Intencion.terminar:
        return terminar();
      case Intencion.repetir:
        return Reaccion('Claro. $preguntaActual');
      case Intencion.despacio:
        return Reaccion('Claro, hablaré más despacio. $preguntaActual', masDespacio: true);
      case Intencion.pista:
        return pedirPista();
      case Intencion.siguiente:
        return saltar();
      case Intencion.noSabe:
        return _enSeguimiento ? _avanzar('No pasa nada.') : _ayudar(noSabe: true);
      case Intencion.ninguna:
        break;
    }

    _dicho.add(texto.trim());
    if (_enSeguimiento) return _avanzar(_animo());

    final dichas = palabrasClave(texto);
    switch (_actual.tipo) {
      case TipoPregunta.libre:
      case TipoPregunta.emocion:
        return _preguntarMas();
      case TipoPregunta.personas:
        return _evaluarPersonas(dichas);
      case TipoPregunta.lugar:
        return _evaluarDato(dichas, recuerdo.lugar, (d) => '¡Eso es! Fue en $d.');
      case TipoPregunta.tiempo:
        return _evaluarDato(dichas, recuerdo.cuando, (d) => '¡Sí! Fue $d.');
    }
  }

  /// La persona pidió ayuda o tocó el botón de pista.
  Reaccion pedirPista() {
    if (terminado) return const Reaccion('', fin: true);
    if (_enSeguimiento || !_tieneDato) {
      return Reaccion('No hay respuesta correcta. Dime lo que te venga a la mente. $preguntaActual');
    }
    return _ayudar(pedida: true);
  }

  /// Pasa a la siguiente pregunta sin responder.
  Reaccion saltar() => terminado ? const Reaccion('', fin: true) : _avanzar('Está bien, sigamos.');

  /// Termina la conversación antes de tiempo, guardando lo dicho.
  Reaccion terminar() {
    _guardarDicho();
    indice = preguntas.length;
    return const Reaccion('Está bien. Lo hiciste muy bien. Terminamos por hoy.', fin: true);
  }

  bool get _tieneDato => switch (_actual.tipo) {
        TipoPregunta.personas => recuerdo.gente.isNotEmpty || recuerdo.personas.trim().isNotEmpty,
        TipoPregunta.lugar => recuerdo.lugar.trim().isNotEmpty,
        TipoPregunta.tiempo => recuerdo.cuando.trim().isNotEmpty,
        _ => false,
      };

  // ---- Evaluación de respuestas -------------------------------------------

  Reaccion _preguntarMas() {
    final masPregunta = _actual.tipo == TipoPregunta.emocion
        ? '¿Qué es lo que más te gusta de este recuerdo?'
        : 'Cuéntame un poquito más. ¿Qué más ves?';
    _enSeguimiento = true;
    return Reaccion('${_animo()} $masPregunta');
  }

  Reaccion _evaluarPersonas(List<String> dichas) {
    final gente = recuerdo.gente;
    if (gente.isEmpty) {
      if (recuerdo.personas.trim().isEmpty) return _preguntarMas();
      return _evaluarDato(dichas, recuerdo.personas, (d) => '¡Sí! En la foto están $d.');
    }
    final nuevas = <Persona>[];
    for (var i = 0; i < gente.length; i++) {
      if (_halladas.contains(i)) continue;
      final claves = [...palabrasClave(gente[i].nombre), ...palabrasClave(gente[i].parentesco)];
      if (claves.any((c) => dijo(dichas, c))) {
        _halladas.add(i);
        nuevas.add(gente[i]);
      }
    }
    if (nuevas.isEmpty) return _ayudar();
    final quienes = unirConY(nuevas.map((p) => p.descripcion).toList());
    if (_halladas.length == gente.length) {
      return _seguir('¡Sí! ${nuevas.length == 1 ? 'Es' : 'Son'} $quienes.');
    }
    _pistasDadas = 0;
    return Reaccion('¡Sí! ${nuevas.length == 1 ? 'Está' : 'Están'} $quienes. '
        'También hay alguien más en la foto. ¿Sabes quién es?');
  }

  Reaccion _evaluarDato(List<String> dichas, String dato, String Function(String) acierto) {
    final limpio = dato.trim();
    if (limpio.isEmpty) return _preguntarMas();
    final claves = palabrasClave(limpio);
    final aciertos = claves.where((c) => dijo(dichas, c)).length;
    if (claves.isEmpty || aciertos * 2 >= claves.length) return _seguir(acierto(limpio));
    if (_actual.tipo == TipoPregunta.tiempo && _mismaDecada(dichas, claves)) {
      return _seguir('Muy cerca. Fue $limpio.');
    }
    return _ayudar();
  }

  bool _mismaDecada(List<String> dichas, List<String> claves) {
    int? anio(List<String> palabras) => palabras
        .map(int.tryParse)
        .where((n) => n != null && n > 1900 && n < 2100)
        .firstOrNull;
    final real = anio(claves);
    final dicho = anio(dichas);
    return real != null && dicho != null && real ~/ 10 == dicho ~/ 10;
  }

  // ---- Pistas en escalones ------------------------------------------------

  List<String> _pistas() {
    switch (_actual.tipo) {
      case TipoPregunta.personas:
        final gente = recuerdo.gente;
        if (gente.isEmpty) return [_pistaInicial(recuerdo.personas, 'Uno de los nombres')];
        final falta = gente[List.generate(gente.length, (i) => i)
            .firstWhere((i) => !_halladas.contains(i), orElse: () => 0)];
        return [
          if (falta.parentesco.trim().isNotEmpty) 'En la foto está tu ${falta.parentesco.trim()}.',
          'Su nombre empieza con la letra ${falta.nombre.trim()[0].toUpperCase()}.',
        ];
      case TipoPregunta.lugar:
        return [_pistaInicial(recuerdo.lugar, 'El nombre del lugar')];
      case TipoPregunta.tiempo:
        final anio = palabrasClave(recuerdo.cuando)
            .map(int.tryParse)
            .where((n) => n != null && n > 1900 && n < 2100)
            .firstOrNull;
        if (anio != null) return ['Fue en la década de ${anio ~/ 10 * 10}.'];
        return [_pistaInicial(recuerdo.cuando, 'La respuesta')];
      case TipoPregunta.libre:
      case TipoPregunta.emocion:
        return const [];
    }
  }

  String _pistaInicial(String dato, String sujeto) {
    final claves = palabrasClave(dato)..sort((a, b) => b.length.compareTo(a.length));
    final letra = claves.isEmpty ? dato.trim()[0] : claves.first[0];
    return '$sujeto tiene una palabra que empieza con la letra ${letra.toUpperCase()}.';
  }

  String get _invitacion => switch (_actual.tipo) {
        TipoPregunta.personas => '¿Quién será?',
        TipoPregunta.lugar => '¿Dónde será?',
        TipoPregunta.tiempo => '¿Cuándo habrá sido?',
        _ => '',
      };

  String get _revelacion {
    switch (_actual.tipo) {
      case TipoPregunta.personas:
        final gente = recuerdo.gente;
        if (gente.isEmpty) return 'En la foto están ${recuerdo.personas.trim()}.';
        final faltan = [
          for (var i = 0; i < gente.length; i++)
            if (!_halladas.contains(i)) gente[i],
        ];
        final quienes = unirConY(faltan.map((p) => p.descripcion).toList());
        return faltan.length == 1 ? 'Es $quienes.' : 'Son $quienes.';
      case TipoPregunta.lugar:
        return 'Fue en ${recuerdo.lugar.trim()}.';
      case TipoPregunta.tiempo:
        return 'Fue ${recuerdo.cuando.trim()}.';
      case TipoPregunta.libre:
      case TipoPregunta.emocion:
        return '';
    }
  }

  Reaccion _ayudar({bool noSabe = false, bool pedida = false}) {
    if (!_tieneDato) return _avanzar(noSabe ? 'No pasa nada.' : _animo());
    final pistas = _pistas();
    if (_pistasDadas >= pistas.length) {
      return _seguir('${noSabe ? 'No te preocupes, yo te cuento.' : 'Te cuento.'} $_revelacion');
    }
    final entrada = pedida
        ? 'Claro, te ayudo.'
        : noSabe
            ? 'No pasa nada, te ayudo.'
            : _pistasDadas == 0
                ? 'Gracias por contármelo. Pensemos juntos.'
                : 'Vamos bien. Te doy otra pista.';
    final pista = pistas[_pistasDadas++];
    return Reaccion('$entrada $pista $_invitacion');
  }

  // ---- Avance -------------------------------------------------------------

  /// Tras acertar o conocer el dato, invita a contar algo más.
  Reaccion _seguir(String entrada) {
    _enSeguimiento = true;
    final mas = switch (_actual.tipo) {
      TipoPregunta.personas => recuerdo.gente.isEmpty
          ? '¿Qué recuerdas de ellos?'
          : 'Cuéntame algo de ${recuerdo.gente.first.nombre.trim()}.',
      TipoPregunta.lugar => '¿Qué hacían en ese lugar?',
      TipoPregunta.tiempo => '¿Qué más recuerdas de esa época?',
      _ => '¿Quieres contarme algo más?',
    };
    return Reaccion('$entrada $mas');
  }

  void _guardarDicho() {
    if (terminado || _dicho.isEmpty) return;
    respuestas.add(Respuesta(pregunta: _actual.texto, texto: _dicho.join(' ')));
    _dicho.clear();
  }

  Reaccion _avanzar(String entrada) {
    _guardarDicho();
    indice++;
    _pistasDadas = 0;
    _enSeguimiento = false;
    _halladas.clear();
    if (terminado) {
      return Reaccion('$entrada Hemos terminado. Gracias por compartir este recuerdo conmigo.',
          fin: true);
    }
    return Reaccion('$entrada $preguntaActual');
  }
}
