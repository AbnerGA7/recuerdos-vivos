import 'package:flutter/material.dart';

import '../componentes/marco_foto.dart';
import '../datos/almacen.dart';
import '../tema/colores.dart';
import 'detalle_recuerdo.dart';
import 'nuevo_recuerdo.dart';

/// Álbum con todas las fotos en dos columnas grandes.
class Album extends StatelessWidget {
  const Album({super.key});

  @override
  Widget build(BuildContext context) {
    final almacen = AlmacenScope.of(context);
    final estilos = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Mis fotos')),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colores.calendula,
        foregroundColor: Colores.tinta,
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const NuevoRecuerdo()),
        ),
        icon: const Icon(Icons.add_a_photo_rounded, size: 28),
        label: Text('Agregar foto', style: estilos.labelLarge),
      ),
      body: almacen.recuerdos.isEmpty
          ? Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Text(
                  'Aquí aparecerán tus fotos. Toca «Agregar foto» para guardar la primera.',
                  style: estilos.bodyLarge,
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 24,
                crossAxisSpacing: 18,
                childAspectRatio: 0.72,
              ),
              itemCount: almacen.recuerdos.length,
              itemBuilder: (context, i) {
                final r = almacen.recuerdos[i];
                return Semantics(
                  button: true,
                  label: 'Abrir ${r.tituloVisible}',
                  excludeSemantics: true,
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => DetalleRecuerdo(recuerdoId: r.id),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: MarcoFoto(
                            ruta: r.rutaFoto,
                            descripcion: r.tituloVisible,
                            inclinacion: i.isEven ? -0.02 : 0.018,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          r.tituloVisible,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: estilos.titleMedium,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
