import 'dart:async';

import 'package:flutter/material.dart';

import 'app.dart';
import 'datos/almacen.dart';
import 'servicios/voz.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final almacen = Almacen();
  final voz = Voz();
  runApp(RecuerdosVivosApp(almacen: almacen, voz: voz));
  await almacen.cargar();
  unawaited(voz.iniciar(
    velocidad: almacen.ajustes.velocidadVoz,
    vozNatural: almacen.ajustes.vozNatural,
  ));
}
