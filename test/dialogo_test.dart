import 'package:flutter_test/flutter_test.dart';
import 'package:recuerdos_vivos/datos/dialogo.dart';
import 'package:recuerdos_vivos/datos/modelos.dart';
import 'package:recuerdos_vivos/datos/texto.dart';

Recuerdo _foto() => Recuerdo(
      id: '1',
      rutaFoto: 'x.jpg',
      gente: const [
        Persona(nombre: 'Carmen', parentesco: 'hija'),
        Persona(nombre: 'Luis', parentesco: 'nieto'),
      ],
      lugar: 'La casa de Chosica',
      cuando: 'en el verano de 1998',
    );

/// Lleva al motor hasta la pregunta de personas.
MotorDialogo _enPersonas() {
  final m = MotorDialogo(_foto(), nombre: 'Rosa')..abrir();
  m.escuchar('Veo una familia');
  m.escuchar('Están en un jardín');
  expect(m.indice, 1);
  return m;
}

const _prohibidas = ['incorrect', 'equivoc', 'mal', 'error', 'no es', 'fallaste'];

void _sinRegaños(String frase) {
  final n = ' ${normalizar(frase)} ';
  for (final p in _prohibidas) {
    expect(n.contains(' $p'), isFalse, reason: 'La frase "$frase" contiene "$p"');
  }
}

void main() {
  test('normaliza tildes y tolera errores pequeños de la voz', () {
    expect(normalizar('¡Está en Chosíca!'), 'esta en chosica');
    expect(seParecen('carmen', 'carmem'), isTrue);
    expect(seParecen('luis', 'ruiz'), isFalse);
    expect(partirEnFrases('Hola. ¿Cómo estás? Bien'), ['Hola.', '¿Cómo estás?', 'Bien']);
  });

  test('entiende órdenes habladas', () {
    expect(detectarIntencion('repite por favor'), Intencion.repetir);
    expect(detectarIntencion('dame una pista'), Intencion.pista);
    expect(detectarIntencion('no me acuerdo'), Intencion.noSabe);
    expect(detectarIntencion('más despacio'), Intencion.despacio);
    expect(detectarIntencion('ya no quiero'), Intencion.terminar);
    expect(
      detectarIntencion('mi mamá siempre me pedía ayuda en la cocina los domingos'),
      Intencion.ninguna,
    );
  });

  test('saluda por el nombre y hace la primera pregunta', () {
    final r = MotorDialogo(_foto(), nombre: 'Rosa').abrir();
    expect(r.decir, contains('Hola, Rosa'));
    expect(r.decir, contains('¿Qué es lo primero que ves?'));
  });

  test('reconoce a una persona y pregunta por la que falta', () {
    final m = _enPersonas();
    final r = m.escuchar('Creo que es Carmen');
    expect(r.decir, contains('Carmen, tu hija'));
    expect(r.decir, contains('alguien más'));
    expect(m.indice, 1);
  });

  test('reconoce por parentesco y acepta nombres mal transcritos', () {
    final m = _enPersonas();
    expect(m.escuchar('es mi hija').decir, contains('Carmen'));
    expect(m.escuchar('y Luiz').decir, contains('Luis'));
  });

  test('si no coincide da pistas cada vez más claras y nunca regaña', () {
    final m = _enPersonas();
    final uno = m.escuchar('Es mi vecina Marta');
    expect(uno.decir, contains('tu hija'));
    expect(uno.decir, isNot(contains('Carmen')));
    final dos = m.escuchar('no sé');
    expect(dos.decir, contains('letra C'));
    final tres = m.escuchar('no me acuerdo');
    expect(tres.decir, contains('Carmen, tu hija'));
    expect(tres.decir, contains('Luis, tu nieto'));
    for (final r in [uno, dos, tres]) {
      _sinRegaños(r.decir);
    }
  });

  test('acierta el lugar con parte del nombre y el año por década', () {
    final m = _enPersonas();
    m.escuchar('Carmen y Luis');
    m.escuchar('Los quiero mucho');
    expect(m.indice, 2);
    expect(m.escuchar('en Chosica').decir, contains('¡Eso es!'));
    m.escuchar('almorzábamos');
    expect(m.indice, 3);
    expect(m.escuchar('por 1995').decir, contains('Muy cerca'));
  });

  test('termina con cariño y guarda lo dicho', () {
    final m = _enPersonas();
    m.escuchar('Carmen y Luis');
    final r = m.escuchar('ya no quiero');
    expect(r.fin, isTrue);
    expect(m.terminado, isTrue);
    expect(m.respuestas.map((x) => x.texto).join(' '), contains('Carmen y Luis'));
    _sinRegaños(r.decir);
  });

  test('sin datos del familiar la conversación fluye sin pistas inventadas', () {
    final m = MotorDialogo(Recuerdo(id: '2', rutaFoto: 'y.jpg'))..abrir();
    var pasos = 0;
    while (!m.terminado && pasos < 30) {
      final r = m.escuchar('una respuesta cualquiera');
      _sinRegaños(r.decir);
      pasos++;
    }
    expect(m.terminado, isTrue);
    expect(m.respuestas, hasLength(5));
  });
}
