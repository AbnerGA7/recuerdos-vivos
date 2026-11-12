import 'package:flutter_test/flutter_test.dart';
import 'package:recuerdos_vivos/datos/modelos.dart';
import 'package:recuerdos_vivos/datos/preguntas.dart';

void main() {
  test('sin datos del cuidador no hay pistas inventadas', () {
    final preguntas = armarPreguntas(Recuerdo(id: '1', rutaFoto: 'x.jpg'));
    expect(preguntas, hasLength(5));
    expect(preguntas.every((p) => p.pista == null), isTrue);
  });

  test('las pistas usan solo lo que escribió el cuidador', () {
    final r = Recuerdo(id: '1', rutaFoto: 'x.jpg', personas: 'Carmen', lugar: 'Chosica');
    final preguntas = armarPreguntas(r);
    expect(preguntas[1].pista, contains('Carmen'));
    expect(preguntas[2].pista, contains('Chosica'));
    expect(preguntas[3].pista, isNull);
  });

  test('el saludo cambia según la hora y usa el nombre', () {
    expect(saludo(DateTime(2026, 1, 1, 9), 'Rosa'), 'Buenos días, Rosa');
    expect(saludo(DateTime(2026, 1, 1, 15), ''), 'Buenas tardes');
    expect(saludo(DateTime(2026, 1, 1, 21), 'Rosa'), 'Buenas noches, Rosa');
  });
}
