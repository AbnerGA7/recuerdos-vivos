import 'package:flutter_test/flutter_test.dart';
import 'package:recuerdos_vivos/datos/modelos.dart';
import 'package:recuerdos_vivos/util/fechas.dart';

void main() {
  test('un recuerdo se guarda y se lee igual', () {
    final r = Recuerdo(id: 'a', rutaFoto: 'f.jpg', titulo: 'Playa', personas: 'Luis');
    final copia = Recuerdo.desdeJson(r.aJson());
    expect(copia.titulo, 'Playa');
    expect(copia.personas, 'Luis');
    expect(copia.creado, r.creado);
  });

  test('una sesión conserva respuestas y ánimo', () {
    final s = Sesion(
      id: 's',
      recuerdoId: 'a',
      respuestas: const [Respuesta(pregunta: '¿Quién?', texto: 'Mi hija')],
      animo: Animo.contento,
    );
    final copia = Sesion.desdeJson(s.aJson());
    expect(copia.respuestas.single.texto, 'Mi hija');
    expect(copia.animo, Animo.contento);
  });

  test('las fechas se muestran en español', () {
    final f = DateTime(2026, 11, 11, 16, 5);
    expect(fechaLarga(f), 'Miércoles 11 de noviembre');
    expect(fechaRelativa(f, DateTime(2026, 11, 12)), 'Ayer');
    expect(hora(f), '4:05 p. m.');
  });
}
