import 'modelos.dart';

enum TipoPregunta { libre, personas, lugar, tiempo, emocion }

/// Una pregunta guiada de la conversación.
class Pregunta {
  const Pregunta(this.tipo, this.texto);
  final TipoPregunta tipo;
  final String texto;
}

/// Arma las preguntas de una sesión.
///
/// Sigue la terapia de reminiscencia: empieza por lo que se ve y termina
/// en lo que se siente. Son pocas (5) para no cansar.
List<Pregunta> armarPreguntas(Recuerdo r) => const [
      Pregunta(TipoPregunta.libre, 'Mira la foto con calma. ¿Qué es lo primero que ves?'),
      Pregunta(TipoPregunta.personas, '¿Quiénes están en esta foto?'),
      Pregunta(TipoPregunta.lugar, '¿Dónde crees que se tomó?'),
      Pregunta(TipoPregunta.tiempo, '¿Recuerdas cuándo fue?'),
      Pregunta(TipoPregunta.emocion, '¿Qué sientes al ver esta foto?'),
    ];

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
