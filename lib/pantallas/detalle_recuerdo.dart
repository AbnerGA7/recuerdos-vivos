import 'package:flutter/material.dart';

import '../componentes/boton_escuchar.dart';
import '../componentes/marco_foto.dart';
import '../componentes/pin.dart';
import '../datos/almacen.dart';
import '../datos/modelos.dart';
import '../servicios/voz.dart';
import '../tema/colores.dart';
import 'nuevo_recuerdo.dart';
import 'sesion.dart';

/// Muestra una foto con su historia y permite empezar una sesión.
class DetalleRecuerdo extends StatelessWidget {
  const DetalleRecuerdo({super.key, required this.recuerdoId});

  final String recuerdoId;

  String _narracion(Recuerdo r) => [
        r.tituloVisible,
        if (r.personasTexto.isNotEmpty) 'En la foto: ${r.personasTexto}.',
        if (r.lugar.isNotEmpty) 'Fue en ${r.lugar}.',
        if (r.cuando.isNotEmpty) 'Fue ${r.cuando}.',
        if (r.historia.isNotEmpty) r.historia,
      ].join(' ');

  @override
  Widget build(BuildContext context) {
    final almacen = AlmacenScope.of(context);
    final voz = VozScope.of(context);
    final r = almacen.buscar(recuerdoId);
    if (r == null) return const Scaffold();
    final estilos = Theme.of(context).textTheme;
    final veces = almacen.sesiones.where((s) => s.recuerdoId == r.id).length;

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            tooltip: 'Editar',
            iconSize: 30,
            icon: const Icon(Icons.edit_rounded),
            onPressed: () async {
              if (!await pedirPin(context) || !context.mounted) return;
              await Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => NuevoRecuerdo(editar: r)),
              );
            },
          ),
          IconButton(
            tooltip: 'Borrar',
            iconSize: 30,
            icon: const Icon(Icons.delete_outline_rounded),
            onPressed: () => _borrar(context, r),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
          children: [
            MarcoFoto(ruta: r.rutaFoto, descripcion: r.tituloVisible, alto: 320),
            const SizedBox(height: 28),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: Text(r.tituloVisible, style: estilos.headlineMedium)),
                BotonEscuchar(
                  leyendo: voz.leyendo,
                  onTap: () => voz.leyendo ? voz.callar() : voz.decir(_narracion(r)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (r.personasTexto.isNotEmpty)
              _Dato(icono: Icons.people_alt_rounded, texto: r.personasTexto),
            if (r.lugar.isNotEmpty) _Dato(icono: Icons.place_rounded, texto: r.lugar),
            if (r.cuando.isNotEmpty) _Dato(icono: Icons.event_rounded, texto: r.cuando),
            if (r.historia.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(r.historia, style: estilos.bodyLarge),
            ],
            const SizedBox(height: 12),
            Text(
              veces == 0 ? 'Aún no lo has recordado.' : 'Lo recordaste $veces ${veces == 1 ? 'vez' : 'veces'}.',
              style: estilos.bodyMedium?.copyWith(color: Colores.tintaSuave),
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => SesionGuiada(recuerdo: r)),
              ),
              icon: const Icon(Icons.record_voice_over_rounded, size: 30),
              label: const Text('Empezar a recordar'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _borrar(BuildContext context, Recuerdo r) async {
    final almacen = AlmacenScope.leer(context);
    if (!await pedirPin(context) || !context.mounted) return;
    final si = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('¿Borrar este recuerdo?'),
        content: const Text('Se borrará la foto y lo que se habló sobre ella. No se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('No, conservar')),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            style: TextButton.styleFrom(foregroundColor: Colores.error),
            child: const Text('Sí, borrar'),
          ),
        ],
      ),
    );
    if (si != true || !context.mounted) return;
    Navigator.of(context).pop();
    await almacen.borrarRecuerdo(r);
  }
}

class _Dato extends StatelessWidget {
  const _Dato({required this.icono, required this.texto});

  final IconData icono;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, size: 28, color: Colores.tintaSuave),
          const SizedBox(width: 14),
          Expanded(child: Text(texto, style: Theme.of(context).textTheme.bodyLarge)),
        ],
      ),
    );
  }
}
