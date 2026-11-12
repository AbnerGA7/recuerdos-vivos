import 'package:flutter/material.dart';

import '../tema/colores.dart';

/// Botón pequeño para volver a oír un texto en voz alta.
class BotonEscuchar extends StatelessWidget {
  const BotonEscuchar({super.key, required this.onTap, this.leyendo = false});

  final VoidCallback onTap;
  final bool leyendo;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: leyendo ? 'Detener' : 'Escuchar otra vez',
      child: IconButton.filledTonal(
        onPressed: onTap,
        iconSize: 32,
        style: IconButton.styleFrom(
          backgroundColor: Colores.papel,
          foregroundColor: Colores.tinta,
          minimumSize: const Size(60, 60),
          side: const BorderSide(color: Colores.linea, width: 2),
        ),
        icon: Icon(leyendo ? Icons.stop_rounded : Icons.volume_up_rounded),
      ),
    );
  }
}
