/// Modelos de datos de Recuerdos Vivos. Todo se guarda solo en el teléfono.
library;

/// Una foto con lo que el cuidador sabe de ella.
///
/// Las pistas de las preguntas salen solo de estos datos: la app nunca
/// inventa quién está en una foto ni dónde se tomó.
class Recuerdo {
  Recuerdo({
    required this.id,
    required this.rutaFoto,
    this.titulo = '',
    this.personas = '',
    this.lugar = '',
    this.cuando = '',
    this.historia = '',
    DateTime? creado,
  }) : creado = creado ?? DateTime.now();

  final String id;
  final String rutaFoto;
  String titulo;
  String personas;
  String lugar;
  String cuando;
  String historia;
  final DateTime creado;

  String get tituloVisible => titulo.trim().isEmpty ? 'Un recuerdo' : titulo.trim();

  Map<String, dynamic> aJson() => {
        'id': id,
        'rutaFoto': rutaFoto,
        'titulo': titulo,
        'personas': personas,
        'lugar': lugar,
        'cuando': cuando,
        'historia': historia,
        'creado': creado.toIso8601String(),
      };

  factory Recuerdo.desdeJson(Map<String, dynamic> j) => Recuerdo(
        id: j['id'] as String,
        rutaFoto: j['rutaFoto'] as String,
        titulo: j['titulo'] as String? ?? '',
        personas: j['personas'] as String? ?? '',
        lugar: j['lugar'] as String? ?? '',
        cuando: j['cuando'] as String? ?? '',
        historia: j['historia'] as String? ?? '',
        creado: DateTime.tryParse(j['creado'] as String? ?? ''),
      );
}

/// Una respuesta dada durante una sesión.
class Respuesta {
  const Respuesta({required this.pregunta, required this.texto});
  final String pregunta;
  final String texto;

  Map<String, dynamic> aJson() => {'pregunta': pregunta, 'texto': texto};
  factory Respuesta.desdeJson(Map<String, dynamic> j) => Respuesta(
        pregunta: j['pregunta'] as String? ?? '',
        texto: j['texto'] as String? ?? '',
      );
}

/// Cómo se sintió la persona al terminar la sesión.
enum Animo { contento, tranquilo, cansado }

/// Una sesión de recuerdo terminada, guardada en el diario.
class Sesion {
  Sesion({
    required this.id,
    required this.recuerdoId,
    required this.respuestas,
    this.animo,
    DateTime? fecha,
  }) : fecha = fecha ?? DateTime.now();

  final String id;
  final String recuerdoId;
  final List<Respuesta> respuestas;
  final Animo? animo;
  final DateTime fecha;

  Map<String, dynamic> aJson() => {
        'id': id,
        'recuerdoId': recuerdoId,
        'respuestas': respuestas.map((r) => r.aJson()).toList(),
        'animo': animo?.name,
        'fecha': fecha.toIso8601String(),
      };

  factory Sesion.desdeJson(Map<String, dynamic> j) => Sesion(
        id: j['id'] as String,
        recuerdoId: j['recuerdoId'] as String,
        respuestas: (j['respuestas'] as List? ?? [])
            .map((e) => Respuesta.desdeJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
        animo: Animo.values.where((a) => a.name == j['animo']).firstOrNull,
        fecha: DateTime.tryParse(j['fecha'] as String? ?? ''),
      );
}

/// Preferencias de la persona y del cuidador.
class Ajustes {
  Ajustes({
    this.nombre = '',
    this.leerEnVozAlta = true,
    this.velocidadVoz = 0.42,
    this.escalaTexto = 1.0,
    this.bienvenidaVista = false,
  });

  String nombre;
  bool leerEnVozAlta;

  /// Velocidad de lectura de flutter_tts (0.5 es la normal en Android).
  double velocidadVoz;
  double escalaTexto;
  bool bienvenidaVista;

  Map<String, dynamic> aJson() => {
        'nombre': nombre,
        'leerEnVozAlta': leerEnVozAlta,
        'velocidadVoz': velocidadVoz,
        'escalaTexto': escalaTexto,
        'bienvenidaVista': bienvenidaVista,
      };

  factory Ajustes.desdeJson(Map<String, dynamic> j) => Ajustes(
        nombre: j['nombre'] as String? ?? '',
        leerEnVozAlta: j['leerEnVozAlta'] as bool? ?? true,
        velocidadVoz: (j['velocidadVoz'] as num?)?.toDouble() ?? 0.42,
        escalaTexto: (j['escalaTexto'] as num?)?.toDouble() ?? 1.0,
        bienvenidaVista: j['bienvenidaVista'] as bool? ?? false,
      );
}
