import 'dart:io';

import 'package:flutter/material.dart';

import '../tema/colores.dart';

/// Foto con marco blanco ancho, como una foto impresa de álbum.
class MarcoFoto extends StatelessWidget {
  const MarcoFoto({
    super.key,
    required this.ruta,
    this.descripcion = '',
    this.alto,
    this.inclinacion = 0,
  });

  final String ruta;
  final String descripcion;
  final double? alto;

  /// Giro leve en radianes para dar sensación de foto suelta.
  final double inclinacion;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: inclinacion,
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 28),
        decoration: BoxDecoration(
          color: Colores.papel,
          borderRadius: BorderRadius.circular(6),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33173A35),
              blurRadius: 18,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: SizedBox(
          height: alto,
          width: double.infinity,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: Image.file(
              File(ruta),
              fit: BoxFit.cover,
              cacheWidth: 1200,
              semanticLabel: descripcion.isEmpty ? 'Foto' : descripcion,
              errorBuilder: (_, _, _) => Container(
                color: Colores.fondo,
                alignment: Alignment.center,
                child: const Icon(Icons.image_not_supported_outlined,
                    size: 48, color: Colores.tintaSuave),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
