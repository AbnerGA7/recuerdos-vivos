import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';

import 'modelos.dart';

/// Guarda recuerdos, sesiones y ajustes en un archivo JSON privado
/// de la app. No usa internet ni servidores.
class Almacen extends ChangeNotifier {
  Almacen({Directory? carpeta}) : _carpetaFija = carpeta;

  final Directory? _carpetaFija;
  late Directory _carpeta;

  final List<Recuerdo> recuerdos = [];
  final List<Sesion> sesiones = [];
  Ajustes ajustes = Ajustes();
  bool cargado = false;

  File get _archivo => File('${_carpeta.path}/recuerdos_vivos.json');
  Directory get carpetaFotos => Directory('${_carpeta.path}/fotos');

  Future<void> cargar() async {
    _carpeta = _carpetaFija ?? await getApplicationDocumentsDirectory();
    await carpetaFotos.create(recursive: true);
    if (await _archivo.exists()) {
      try {
        final j = jsonDecode(await _archivo.readAsString()) as Map<String, dynamic>;
        recuerdos
          ..clear()
          ..addAll((j['recuerdos'] as List? ?? [])
              .map((e) => Recuerdo.desdeJson(Map<String, dynamic>.from(e as Map))));
        sesiones
          ..clear()
          ..addAll((j['sesiones'] as List? ?? [])
              .map((e) => Sesion.desdeJson(Map<String, dynamic>.from(e as Map))));
        ajustes = Ajustes.desdeJson(
            Map<String, dynamic>.from(j['ajustes'] as Map? ?? {}));
      } catch (e) {
        debugPrint('No se pudo leer el archivo de datos: $e');
      }
    }
    cargado = true;
    notifyListeners();
  }

  Future<void> _guardar() async {
    final datos = {
      'version': 1,
      'recuerdos': recuerdos.map((r) => r.aJson()).toList(),
      'sesiones': sesiones.map((s) => s.aJson()).toList(),
      'ajustes': ajustes.aJson(),
    };
    final tmp = File('${_archivo.path}.tmp');
    await tmp.writeAsString(jsonEncode(datos), flush: true);
    await tmp.rename(_archivo.path);
  }

  String nuevoId() => DateTime.now().microsecondsSinceEpoch.toString();

  /// Copia la foto elegida a la carpeta privada de la app.
  Future<String> guardarFoto(String rutaOrigen) async {
    final ext = rutaOrigen.contains('.') ? rutaOrigen.split('.').last : 'jpg';
    final destino = '${carpetaFotos.path}/${nuevoId()}.$ext';
    await File(rutaOrigen).copy(destino);
    return destino;
  }

  Recuerdo? buscar(String id) => recuerdos.where((r) => r.id == id).firstOrNull;

  Future<void> guardarRecuerdo(Recuerdo r) async {
    final i = recuerdos.indexWhere((x) => x.id == r.id);
    if (i >= 0) {
      recuerdos[i] = r;
    } else {
      recuerdos.insert(0, r);
    }
    notifyListeners();
    await _guardar();
  }

  Future<void> borrarRecuerdo(Recuerdo r) async {
    recuerdos.removeWhere((x) => x.id == r.id);
    sesiones.removeWhere((s) => s.recuerdoId == r.id);
    notifyListeners();
    await _guardar();
    try {
      await File(r.rutaFoto).delete();
    } catch (_) {}
  }

  Future<void> guardarSesion(Sesion s) async {
    sesiones.insert(0, s);
    notifyListeners();
    await _guardar();
  }

  Future<void> actualizarAjustes(void Function(Ajustes a) cambio) async {
    cambio(ajustes);
    notifyListeners();
    await _guardar();
  }

  /// Sesiones de los últimos 7 días, para la racha del inicio.
  int sesionesDeLaSemana(DateTime ahora) => sesiones
      .where((s) => ahora.difference(s.fecha).inDays < 7)
      .length;

  /// El recuerdo menos visitado, para sugerir uno en el inicio.
  Recuerdo? recuerdoSugerido() {
    if (recuerdos.isEmpty) return null;
    final visitas = <String, int>{};
    for (final s in sesiones) {
      visitas[s.recuerdoId] = (visitas[s.recuerdoId] ?? 0) + 1;
    }
    final orden = [...recuerdos]
      ..sort((a, b) => (visitas[a.id] ?? 0).compareTo(visitas[b.id] ?? 0));
    return orden.first;
  }
}

/// Da acceso al almacén desde cualquier pantalla y la redibuja al cambiar.
class AlmacenScope extends InheritedNotifier<Almacen> {
  const AlmacenScope({super.key, required Almacen almacen, required super.child})
      : super(notifier: almacen);

  static Almacen of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AlmacenScope>()!.notifier!;

  static Almacen leer(BuildContext context) =>
      context.getInheritedWidgetOfExactType<AlmacenScope>()!.notifier!;
}
