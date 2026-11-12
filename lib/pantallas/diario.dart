import 'package:flutter/material.dart';

import '../componentes/boton_escuchar.dart';
import '../datos/almacen.dart';
import '../datos/modelos.dart';
import '../servicios/voz.dart';
import '../tema/colores.dart';
import '../util/fechas.dart';

/// Diario con las conversaciones guardadas, de la más reciente a la más antigua.
class Diario extends StatelessWidget {
  const Diario({super.key});

  @override
  Widget build(BuildContext context) {
    final almacen = AlmacenScope.of(context);
    final estilos = Theme.of(context).textTheme;
    final ahora = DateTime.now();
    return Scaffold(
      appBar: AppBar(title: const Text('Diario')),
      body: almacen.sesiones.isEmpty
          ? Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Text(
                  'Cuando termines de recordar una foto, lo que contaste aparecerá aquí.',
                  style: estilos.bodyLarge,
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
              itemCount: almacen.sesiones.length,
              separatorBuilder: (_, _) => const SizedBox(height: 14),
              itemBuilder: (context, i) {
                final s = almacen.sesiones[i];
                final r = almacen.buscar(s.recuerdoId);
                return _EntradaDiario(
                  sesion: s,
                  titulo: r?.tituloVisible ?? 'Un recuerdo',
                  fecha: '${fechaRelativa(s.fecha, ahora)}, ${hora(s.fecha)}',
                );
              },
            ),
    );
  }
}

class _EntradaDiario extends StatelessWidget {
  const _EntradaDiario({required this.sesion, required this.titulo, required this.fecha});

  final Sesion sesion;
  final String titulo;
  final String fecha;

  IconData get _iconoAnimo => switch (sesion.animo) {
        Animo.contento => Icons.sentiment_very_satisfied_rounded,
        Animo.tranquilo => Icons.sentiment_satisfied_rounded,
        Animo.cansado => Icons.sentiment_dissatisfied_rounded,
        null => Icons.auto_stories_rounded,
      };

  String get _lectura => [
        '$titulo. $fecha.',
        for (final r in sesion.respuestas) '${r.pregunta} ${r.texto}.',
      ].join(' ');

  @override
  Widget build(BuildContext context) {
    final estilos = Theme.of(context).textTheme;
    final voz = VozScope.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colores.papel,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colores.linea, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_iconoAnimo, size: 36, color: Colores.tinta),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(titulo, style: estilos.titleLarge),
                    Text(fecha, style: estilos.bodyMedium?.copyWith(color: Colores.tintaSuave)),
                  ],
                ),
              ),
              BotonEscuchar(onTap: () => voz.leyendo ? voz.callar() : voz.decir(_lectura)),
            ],
          ),
          if (sesion.respuestas.isNotEmpty) const Divider(height: 28, color: Colores.linea),
          for (final r in sesion.respuestas) ...[
            Text(r.pregunta, style: estilos.titleMedium?.copyWith(color: Colores.tintaSuave)),
            const SizedBox(height: 2),
            Text(r.texto, style: estilos.bodyLarge),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}
