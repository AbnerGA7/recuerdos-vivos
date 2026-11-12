import 'package:flutter_test/flutter_test.dart';
import 'package:recuerdos_vivos/datos/modelos.dart';
import 'package:recuerdos_vivos/datos/preguntas.dart';

void main() {
  test('una sesión tiene cinco preguntas, de lo visible a lo emocional', () {
    final preguntas = armarPreguntas(Recuerdo(id: '1', rutaFoto: 'x.jpg'));
    expect(preguntas, hasLength(5));
    expect(preguntas.first.tipo, TipoPregunta.libre);
    expect(preguntas.last.tipo, TipoPregunta.emocion);
  });

  test('el saludo cambia según la hora y usa el nombre', () {
    expect(saludo(DateTime(2026, 1, 1, 9), 'Rosa'), 'Buenos días, Rosa');
    expect(saludo(DateTime(2026, 1, 1, 15), ''), 'Buenas tardes');
    expect(saludo(DateTime(2026, 1, 1, 21), 'Rosa'), 'Buenas noches, Rosa');
  });
}
