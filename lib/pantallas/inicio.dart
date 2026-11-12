import 'package:flutter/material.dart';

import '../componentes/boton_escuchar.dart';
import '../componentes/boton_grande.dart';
import '../componentes/marco_foto.dart';
import '../componentes/pin.dart';
import '../datos/almacen.dart';
import '../datos/modelos.dart';
import '../datos/preguntas.dart';
import '../servicios/voz.dart';
import '../tema/colores.dart';
import '../util/fechas.dart';
import 'ajustes.dart';
import 'nuevo_recuerdo.dart';
import 'sesion.dart';

/// Pantalla de inicio: saludo, fecha de hoy y el recuerdo sugerido.
class Inicio extends StatelessWidget {
  const Inicio({super.key, required this.irAlbum});

  final VoidCallback irAlbum;

  @override
  Widget build(BuildContext context) {
    final almacen = AlmacenScope.of(context);
    final voz = VozScope.of(context);
    final ahora = DateTime.now();
    final estilos = Theme.of(context).textTheme;
    final sugerido = almacen.recuerdoSugerido();
    final semana = almacen.sesionesDeLaSemana(ahora);
    final hola = saludo(ahora, almacen.ajustes.nombre);
    final hoy = fechaLarga(ahora);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(hoy, style: estilos.titleMedium?.copyWith(color: Colores.tintaSuave)),
              ),
              BotonEscuchar(
                leyendo: voz.leyendo,
                onTap: () => voz.leyendo
                    ? voz.callar()
                    : voz.decir('$hola. Hoy es $hoy.'),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Ajustes',
                iconSize: 32,
                style: IconButton.styleFrom(minimumSize: const Size(60, 60)),
                icon: const Icon(Icons.settings_rounded),
                onPressed: () async {
                  if (!await pedirPin(context) || !context.mounted) return;
                  await Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => const PantallaAjustes()),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          Semantics(header: true, child: Text(hola, style: estilos.displaySmall)),
          const SizedBox(height: 28),
          if (sugerido == null)
            _SinFotos(onAgregar: () => _agregar(context))
          else
            _Sugerido(recuerdo: sugerido),
          const SizedBox(height: 20),
          if (sugerido != null) ...[
            BotonGrande(
              icono: Icons.photo_library_rounded,
              titulo: 'Ver todas mis fotos',
              ayuda: '${almacen.recuerdos.length} ${almacen.recuerdos.length == 1 ? 'foto guardada' : 'fotos guardadas'}',
              onTap: irAlbum,
            ),
            const SizedBox(height: 14),
          ],
          BotonGrande(
            icono: Icons.add_a_photo_rounded,
            titulo: 'Agregar una foto',
            ayuda: 'Ideal para hacerlo con un familiar',
            onTap: () => _agregar(context),
          ),
          if (semana > 0) ...[
            const SizedBox(height: 28),
            _Racha(cantidad: semana),
          ],
        ],
      ),
    );
  }

  void _agregar(BuildContext context) => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const NuevoRecuerdo()),
      );
}

class _Sugerido extends StatelessWidget {
  const _Sugerido({required this.recuerdo});

  final Recuerdo recuerdo;

  @override
  Widget build(BuildContext context) {
    final estilos = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      decoration: BoxDecoration(
        color: Colores.tinta,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('¿Recordamos esta foto?',
              style: estilos.headlineMedium?.copyWith(color: Colores.papel)),
          const SizedBox(height: 20),
          MarcoFoto(
            ruta: recuerdo.rutaFoto,
            descripcion: recuerdo.tituloVisible,
            alto: 220,
            inclinacion: -0.025,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: Colores.calendula,
              foregroundColor: Colores.tinta,
            ),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => SesionGuiada(recuerdo: recuerdo)),
            ),
            icon: const Icon(Icons.record_voice_over_rounded, size: 30),
            label: const Text('Empezar a recordar'),
          ),
        ],
      ),
    );
  }
}

class _SinFotos extends StatelessWidget {
  const _SinFotos({required this.onAgregar});

  final VoidCallback onAgregar;

  @override
  Widget build(BuildContext context) {
    final estilos = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colores.papel,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colores.linea, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.photo_camera_rounded, size: 48, color: Colores.tinta),
          const SizedBox(height: 16),
          Text('Todavía no hay fotos', style: estilos.headlineMedium),
          const SizedBox(height: 8),
          Text(
            'Agrega una foto de un momento especial. Después conversaremos sobre ella.',
            style: estilos.bodyLarge,
          ),
          const SizedBox(height: 20),
          FilledButton(onPressed: onAgregar, child: const Text('Agregar la primera foto')),
        ],
      ),
    );
  }
}

class _Racha extends StatelessWidget {
  const _Racha({required this.cantidad});

  final int cantidad;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Esta semana recordaste $cantidad ${cantidad == 1 ? 'vez' : 'veces'}',
      excludeSemantics: true,
      child: Row(
        children: [
          const Icon(Icons.favorite_rounded, color: Colores.calendulaOscura, size: 30),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Esta semana recordaste $cantidad ${cantidad == 1 ? 'vez' : 'veces'}.',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ],
      ),
    );
  }
}
