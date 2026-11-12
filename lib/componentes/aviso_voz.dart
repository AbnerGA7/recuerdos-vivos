import 'package:flutter/material.dart';

import '../servicios/voz.dart';
import '../tema/colores.dart';

/// Muestra el último aviso del servicio de voz (por ejemplo, si no oyó bien).
class AvisoVoz extends StatelessWidget {
  const AvisoVoz({super.key});

  @override
  Widget build(BuildContext context) {
    final aviso = VozScope.of(context).aviso;
    if (aviso == null) return const SizedBox.shrink();
    return Semantics(
      liveRegion: true,
      child: Container(
        margin: const EdgeInsets.only(top: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colores.papel,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colores.calendula, width: 2),
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline_rounded, size: 28, color: Colores.calendulaOscura),
            const SizedBox(width: 12),
            Expanded(child: Text(aviso, style: Theme.of(context).textTheme.bodyMedium)),
          ],
        ),
      ),
    );
  }
}
