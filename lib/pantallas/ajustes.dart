import 'package:flutter/material.dart';

import '../componentes/campo_dictado.dart';
import '../componentes/pin.dart';
import '../datos/almacen.dart';
import '../servicios/voz.dart';
import '../servicios/voz_neuronal.dart';
import '../tema/colores.dart';

/// Ajustes de voz, tamaño de letra y nombre.
class PantallaAjustes extends StatefulWidget {
  const PantallaAjustes({super.key});

  @override
  State<PantallaAjustes> createState() => _PantallaAjustesState();
}

class _PantallaAjustesState extends State<PantallaAjustes> {
  late final TextEditingController _nombre =
      TextEditingController(text: AlmacenScope.leer(context).ajustes.nombre);

  @override
  void dispose() {
    _nombre.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final almacen = AlmacenScope.of(context);
    final voz = VozScope.of(context);
    final a = almacen.ajustes;
    final estilos = Theme.of(context).textTheme;

    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop && _nombre.text.trim() != a.nombre) {
          almacen.actualizarAjustes((x) => x.nombre = _nombre.text.trim());
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Ajustes')),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
            children: [
              CampoDictado(controlador: _nombre, etiqueta: 'Tu nombre'),
              const SizedBox(height: 32),
              Text('Voz', style: estilos.headlineMedium),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: a.leerEnVozAlta,
                onChanged: (v) => almacen.actualizarAjustes((x) => x.leerEnVozAlta = v),
                title: Text('Leer las preguntas en voz alta', style: estilos.titleMedium),
                subtitle: Text('Recomendado', style: estilos.bodyMedium),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: a.manosLibres,
                onChanged: (v) => almacen.actualizarAjustes((x) => x.manosLibres = v),
                title: Text('Conversación manos libres', style: estilos.titleMedium),
                subtitle: Text('El micrófono se abre y se cierra solo', style: estilos.bodyMedium),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: a.vozNatural,
                onChanged: (v) {
                  almacen.actualizarAjustes((x) => x.vozNatural = v);
                  voz.usarVozNatural = v;
                  if (v) voz.prepararVozNatural(reintentar: true);
                },
                title: Text('Voz natural', style: estilos.titleMedium),
                subtitle: Text(
                  switch (voz.neuronal.estado) {
                    EstadoVozNeuronal.lista => 'Lista. Funciona sin internet.',
                    EstadoVozNeuronal.preparando => 'Preparando la voz…',
                    EstadoVozNeuronal.noDisponible =>
                      'No se pudo cargar. Se usa la voz del teléfono. Apaga y enciende para reintentar.',
                    EstadoVozNeuronal.apagada => 'Se usa la voz del teléfono.',
                  },
                  style: estilos.bodyMedium,
                ),
              ),
              const SizedBox(height: 12),
              Text('Velocidad de la voz', style: estilos.titleMedium),
              Slider(
                value: a.velocidadVoz,
                min: 0.25,
                max: 0.6,
                divisions: 7,
                label: a.velocidadVoz < 0.38
                    ? 'Lenta'
                    : a.velocidadVoz < 0.5
                        ? 'Normal'
                        : 'Rápida',
                onChanged: (v) {
                  almacen.actualizarAjustes((x) => x.velocidadVoz = v);
                  voz.cambiarVelocidad(v);
                },
              ),
              OutlinedButton.icon(
                onPressed: () => voz.decir('Así sonará mi voz cuando te haga preguntas.'),
                icon: const Icon(Icons.volume_up_rounded, size: 28),
                label: const Text('Probar la voz'),
              ),
              const SizedBox(height: 32),
              Text('Tamaño de la letra', style: estilos.headlineMedium),
              const SizedBox(height: 16),
              SegmentedButton<double>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(value: 1.0, label: Text('Normal')),
                  ButtonSegment(value: 1.15, label: Text('Grande')),
                  ButtonSegment(value: 1.3, label: Text('Enorme')),
                ],
                selected: {a.escalaTexto},
                onSelectionChanged: (s) =>
                    almacen.actualizarAjustes((x) => x.escalaTexto = s.first),
                style: SegmentedButton.styleFrom(
                  minimumSize: const Size(0, 60),
                  selectedBackgroundColor: Colores.calendula,
                  selectedForegroundColor: Colores.tinta,
                  textStyle: estilos.titleMedium,
                ),
              ),
              const SizedBox(height: 32),
              Text('Modo cuidador', style: estilos.headlineMedium),
              const SizedBox(height: 8),
              Text(
                a.pin.isEmpty
                    ? 'Sin PIN. Cualquiera puede editar o borrar fotos.'
                    : 'Con PIN. Se pide para editar, borrar y abrir los ajustes.',
                style: estilos.bodyMedium,
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () async {
                  final nuevo = await crearPin(context);
                  if (nuevo != null) await almacen.actualizarAjustes((x) => x.pin = nuevo);
                },
                icon: const Icon(Icons.lock_outline_rounded, size: 28),
                label: Text(a.pin.isEmpty ? 'Crear PIN' : 'Cambiar PIN'),
              ),
              if (a.pin.isNotEmpty)
                TextButton(
                  onPressed: () => almacen.actualizarAjustes((x) => x.pin = ''),
                  child: const Text('Quitar PIN'),
                ),
              const SizedBox(height: 40),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colores.papel,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colores.linea, width: 2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Icon(Icons.lock_outline_rounded, size: 28),
                      const SizedBox(width: 10),
                      Text('Privacidad', style: estilos.titleLarge),
                    ]),
                    const SizedBox(height: 8),
                    Text(
                      'Las fotos y lo que cuentas se guardan solo en este teléfono. '
                      'La voz se genera dentro del teléfono y la app no envía tus datos.',
                      style: estilos.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    Row(children: [
                      const Icon(Icons.info_outline_rounded, size: 28),
                      const SizedBox(width: 10),
                      Text('Importante', style: estilos.titleLarge),
                    ]),
                    const SizedBox(height: 8),
                    Text(
                      'Recuerdos Vivos es un apoyo de estimulación cognitiva. '
                      'No reemplaza el tratamiento ni la orientación de profesionales de la salud.',
                      style: estilos.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
