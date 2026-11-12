import 'package:flutter/material.dart';

import '../tema/colores.dart';

/// Botón de tarjeta grande con ícono, título y una frase de ayuda.
/// Toda el área es tocable para quien tenga poca precisión.
class BotonGrande extends StatelessWidget {
  const BotonGrande({
    super.key,
    required this.icono,
    required this.titulo,
    required this.ayuda,
    required this.onTap,
    this.destacado = false,
  });

  final IconData icono;
  final String titulo;
  final String ayuda;
  final VoidCallback onTap;
  final bool destacado;

  @override
  Widget build(BuildContext context) {
    final fondo = destacado ? Colores.tinta : Colores.papel;
    final texto = destacado ? Colores.papel : Colores.tinta;
    return Semantics(
      button: true,
      label: '$titulo. $ayuda',
      excludeSemantics: true,
      child: Material(
        color: fondo,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 104),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: destacado ? null : Border.all(color: Colores.linea, width: 2),
            ),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: destacado ? Colores.calendula : Colores.fondo,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icono, size: 32, color: Colores.tinta),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(titulo,
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(color: texto)),
                      const SizedBox(height: 4),
                      Text(ayuda,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: texto)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, size: 36, color: texto),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
