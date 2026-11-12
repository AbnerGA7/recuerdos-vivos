import 'package:flutter/material.dart';

import '../servicios/voz.dart';
import '../tema/colores.dart';

/// Campo de texto con micrófono: se puede escribir o dictar.
class CampoDictado extends StatelessWidget {
  const CampoDictado({
    super.key,
    required this.controlador,
    required this.etiqueta,
    this.ejemplo,
    this.lineas = 1,
  });

  final TextEditingController controlador;
  final String etiqueta;
  final String? ejemplo;
  final int lineas;

  @override
  Widget build(BuildContext context) {
    final voz = VozScope.of(context);
    final activo = voz.escuchando && _CampoActivo.de(controlador);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(etiqueta, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        TextField(
          controller: controlador,
          minLines: lineas,
          maxLines: lineas == 1 ? 1 : lineas + 3,
          textCapitalization: TextCapitalization.sentences,
          style: Theme.of(context).textTheme.bodyLarge,
          decoration: InputDecoration(
            hintText: activo ? 'Te escucho…' : ejemplo,
            suffixIcon: Padding(
              padding: const EdgeInsets.only(right: 6),
              child: IconButton(
                tooltip: activo ? 'Terminar de dictar' : 'Dictar $etiqueta',
                iconSize: 30,
                style: IconButton.styleFrom(
                  backgroundColor: activo ? Colores.tinta : Colores.calendula,
                  foregroundColor: activo ? Colores.calendula : Colores.tinta,
                  minimumSize: const Size(52, 52),
                ),
                icon: Icon(activo ? Icons.graphic_eq_rounded : Icons.mic_rounded),
                onPressed: () async {
                  if (activo) {
                    await voz.detenerEscucha();
                    return;
                  }
                  _CampoActivo.actual = controlador;
                  await voz.escuchar((texto) {
                    final previo = controlador.text.trim();
                    controlador.text = previo.isEmpty ? texto : '$previo $texto';
                  });
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Recuerda qué campo está dictando para mostrar el estado solo en ese.
abstract final class _CampoActivo {
  static TextEditingController? actual;
  static bool de(TextEditingController c) => identical(actual, c);
}
