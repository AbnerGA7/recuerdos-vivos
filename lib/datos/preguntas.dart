import 'modelos.dart';

/// Una pregunta guiada con su pista opcional.
class Pregunta {
  const Pregunta({required this.texto, this.pista, this.icono = TipoPregunta.libre});
  final String texto;

  /// Pista suave. Solo existe si el cuidador escribió ese dato.
  final String? pista;
  final TipoPregunta icono;
}

enum TipoPregunta { personas, lugar, tiempo, emocion, libre }

/// Arma las preguntas de una sesión a partir de lo que se sabe de la foto.
///
/// Reglas de la terapia de reminiscencia que sigue:
/// - Empieza por lo que se ve y termina en lo que se siente.
/// - Nunca corrige: la pista se ofrece, no se impone.
/// - Pocas preguntas (máximo 5) para no cansar.
List<Pregunta> armarPreguntas(Recuerdo r) {
  String? dato(String s) => s.trim().isEmpty ? null : s.trim();

  final personas = dato(r.personas);
  final lugar = dato(r.lugar);
  final cuando = dato(r.cuando);

  return [
    const Pregunta(
      texto: 'Mira la foto con calma. ¿Qué es lo primero que ves?',
      icono: TipoPregunta.libre,
    ),
    Pregunta(
      texto: '¿Quiénes están en esta foto?',
      pista: personas == null ? null : 'Tal vez reconozcas a $personas.',
      icono: TipoPregunta.personas,
    ),
    Pregunta(
      texto: '¿Dónde crees que se tomó?',
      pista: lugar == null ? null : 'Piensa en $lugar.',
      icono: TipoPregunta.lugar,
    ),
    Pregunta(
      texto: '¿Recuerdas cuándo fue?',
      pista: cuando == null ? null : 'Fue $cuando.',
      icono: TipoPregunta.tiempo,
    ),
    const Pregunta(
      texto: '¿Qué sientes al ver esta foto?',
      icono: TipoPregunta.emocion,
    ),
  ];
}

/// Frases de ánimo. Celebran la participación, no el acierto.
const frasesDeAnimo = [
  'Gracias por contármelo.',
  'Qué bonito recuerdo.',
  'Muy bien, sigamos.',
  'Me encanta escucharte.',
];

/// Elige una frase de ánimo según el número de respuesta.
String fraseDeAnimo(int indice) => frasesDeAnimo[indice % frasesDeAnimo.length];

/// Saludo según la hora del día.
String saludo(DateTime ahora, String nombre) {
  final n = nombre.trim();
  final base = ahora.hour < 12
      ? 'Buenos días'
      : ahora.hour < 19
          ? 'Buenas tardes'
          : 'Buenas noches';
  return n.isEmpty ? base : '$base, $n';
}
