import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'datos/almacen.dart';
import 'pantallas/bienvenida.dart';
import 'pantallas/navegacion.dart';
import 'servicios/voz.dart';
import 'tema/colores.dart';
import 'tema/tema.dart';

/// Raíz de la app: tema, idioma español y acceso a datos y voz.
class RecuerdosVivosApp extends StatelessWidget {
  const RecuerdosVivosApp({super.key, required this.almacen, required this.voz});

  final Almacen almacen;
  final Voz voz;

  @override
  Widget build(BuildContext context) {
    return AlmacenScope(
      almacen: almacen,
      child: VozScope(
        voz: voz,
        child: ListenableBuilder(
          listenable: almacen,
          builder: (context, _) => MaterialApp(
            title: 'Recuerdos Vivos',
            debugShowCheckedModeBanner: false,
            theme: crearTema(escalaTexto: almacen.ajustes.escalaTexto),
            locale: const Locale('es'),
            supportedLocales: const [Locale('es')],
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            home: !almacen.cargado
                ? const Scaffold(
                    body: Center(child: CircularProgressIndicator(color: Colores.tinta)),
                  )
                : almacen.ajustes.bienvenidaVista
                    ? const Navegacion()
                    : const Bienvenida(),
          ),
        ),
      ),
    );
  }
}
