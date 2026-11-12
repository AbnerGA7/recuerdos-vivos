import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../componentes/campo_dictado.dart';
import '../componentes/aviso_voz.dart';
import '../datos/almacen.dart';
import '../datos/modelos.dart';
import '../servicios/voz.dart';
import '../tema/colores.dart';

/// Formulario para agregar o editar un recuerdo.
/// Pensado para que lo complete un familiar junto a la persona.
class NuevoRecuerdo extends StatefulWidget {
  const NuevoRecuerdo({super.key, this.editar});

  final Recuerdo? editar;

  @override
  State<NuevoRecuerdo> createState() => _NuevoRecuerdoState();
}

class _NuevoRecuerdoState extends State<NuevoRecuerdo> {
  late final _titulo = TextEditingController(text: widget.editar?.titulo);
  late final List<_Fila> _gente = [
    for (final p in widget.editar?.gente ?? const <Persona>[]) _Fila(p.nombre, p.parentesco),
    if ((widget.editar?.gente.isEmpty ?? true) && (widget.editar?.personas.isNotEmpty ?? false))
      _Fila(widget.editar!.personas, ''),
  ];
  late final _lugar = TextEditingController(text: widget.editar?.lugar);
  late final _cuando = TextEditingController(text: widget.editar?.cuando);
  late final _historia = TextEditingController(text: widget.editar?.historia);
  late String? _foto = widget.editar?.rutaFoto;
  bool _guardando = false;

  @override
  void dispose() {
    for (final c in [_titulo, _lugar, _cuando, _historia]) {
      c.dispose();
    }
    for (final f in _gente) {
      f.dispose();
    }
    super.dispose();
  }

  Future<void> _elegir(ImageSource origen) async {
    try {
      final archivo = await ImagePicker().pickImage(
        source: origen,
        maxWidth: 2000,
        imageQuality: 88,
      );
      if (archivo != null && mounted) setState(() => _foto = archivo.path);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir la foto. Revisa los permisos.')),
      );
    }
  }

  Future<void> _guardar() async {
    final foto = _foto;
    if (foto == null) return;
    setState(() => _guardando = true);
    final almacen = AlmacenScope.leer(context);
    await VozScope.leer(context).detenerEscucha();
    final previo = widget.editar;
    final ruta = previo != null && previo.rutaFoto == foto
        ? foto
        : await almacen.guardarFoto(foto);
    final r = Recuerdo(
      id: previo?.id ?? almacen.nuevoId(),
      rutaFoto: ruta,
      titulo: _titulo.text.trim(),
      gente: [
        for (final f in _gente)
          if (f.nombre.text.trim().isNotEmpty)
            Persona(nombre: f.nombre.text.trim(), parentesco: f.parentesco.text.trim()),
      ],
      lugar: _lugar.text.trim(),
      cuando: _cuando.text.trim(),
      historia: _historia.text.trim(),
      creado: previo?.creado,
    );
    await almacen.guardarRecuerdo(r);
    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(previo == null ? 'Foto guardada' : 'Cambios guardados')),
    );
  }

  /// Familiares de otras fotos que aún no están en esta.
  List<Persona> _sugeridas(BuildContext context) {
    final ya = _gente.map((f) => f.nombre.text.trim().toLowerCase()).toSet();
    return AlmacenScope.of(context)
        .familia
        .where((p) => !ya.contains(p.nombre.trim().toLowerCase()))
        .take(8)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final estilos = Theme.of(context).textTheme;
    final foto = _foto;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.editar == null ? 'Agregar foto' : 'Editar recuerdo'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          children: [
            if (foto == null) ...[
              Text('Elige una foto', style: estilos.headlineMedium),
              const SizedBox(height: 8),
              Text('Una foto con personas o lugares conocidos funciona mejor.',
                  style: estilos.bodyLarge),
              const SizedBox(height: 24),
              _Origen(
                icono: Icons.add_photo_alternate_rounded,
                texto: 'Desde la galería',
                onTap: () => _elegir(ImageSource.gallery),
              ),
              const SizedBox(height: 14),
              _Origen(
                icono: Icons.photo_camera_rounded,
                texto: 'Tomar una foto',
                onTap: () => _elegir(ImageSource.camera),
              ),
            ] else ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.file(File(foto), height: 260, fit: BoxFit.cover, cacheWidth: 1200),
              ),
              TextButton.icon(
                onPressed: () => setState(() => _foto = null),
                icon: const Icon(Icons.edit_rounded),
                label: const Text('Cambiar foto'),
              ),
              const SizedBox(height: 8),
              Text(
                'Cuéntanos sobre la foto. Puedes escribir o tocar el micrófono para dictar. '
                'Todo es opcional, pero ayuda a dar buenas pistas.',
                style: estilos.bodyMedium,
              ),
              const AvisoVoz(),
              const SizedBox(height: 24),
              CampoDictado(controlador: _titulo, etiqueta: 'Nombre del recuerdo', ejemplo: 'Cumpleaños de la abuela'),
              const SizedBox(height: 22),
              Text('¿Quiénes salen?', style: estilos.titleLarge),
              const SizedBox(height: 4),
              Text(
                'Con el nombre y el parentesco, la app puede dar pistas como «es tu hija».',
                style: estilos.bodyMedium,
              ),
              const SizedBox(height: 12),
              for (final f in _gente)
                _TarjetaPersona(
                  fila: f,
                  onQuitar: () => setState(() {
                    _gente.remove(f);
                    f.dispose();
                  }),
                ),
              if (_sugeridas(context).isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final p in _sugeridas(context))
                        ActionChip(
                          avatar: const Icon(Icons.add_rounded, size: 22),
                          label: Text(p.descripcion, style: estilos.bodyMedium),
                          onPressed: () => setState(() => _gente.add(_Fila(p.nombre, p.parentesco))),
                        ),
                    ],
                  ),
                ),
              OutlinedButton.icon(
                onPressed: () => setState(() => _gente.add(_Fila('', ''))),
                icon: const Icon(Icons.person_add_alt_1_rounded, size: 28),
                label: const Text('Agregar persona'),
              ),
              const SizedBox(height: 22),
              CampoDictado(controlador: _lugar, etiqueta: '¿Dónde fue?', ejemplo: 'La casa de Chosica'),
              const SizedBox(height: 22),
              CampoDictado(controlador: _cuando, etiqueta: '¿Cuándo fue?', ejemplo: 'En el verano de 1998'),
              const SizedBox(height: 22),
              CampoDictado(controlador: _historia, etiqueta: 'La historia', ejemplo: 'Qué pasó ese día', lineas: 3),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: _guardando ? null : _guardar,
                child: Text(_guardando ? 'Guardando…' : 'Guardar recuerdo'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Origen extends StatelessWidget {
  const _Origen({required this.icono, required this.texto, required this.onTap});

  final IconData icono;
  final String texto;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(96),
        backgroundColor: Colores.papel,
      ),
      onPressed: onTap,
      icon: Icon(icono, size: 36),
      label: Text(texto),
    );
  }
}

/// Controladores de una persona en el formulario.
class _Fila {
  _Fila(String nombre, String parentesco)
      : nombre = TextEditingController(text: nombre),
        parentesco = TextEditingController(text: parentesco);

  final TextEditingController nombre;
  final TextEditingController parentesco;

  void dispose() {
    nombre.dispose();
    parentesco.dispose();
  }
}

class _TarjetaPersona extends StatelessWidget {
  const _TarjetaPersona({required this.fila, required this.onQuitar});

  final _Fila fila;
  final VoidCallback onQuitar;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: BoxDecoration(
        color: Colores.fondo,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colores.linea, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: onQuitar,
              icon: const Icon(Icons.close_rounded),
              label: const Text('Quitar'),
            ),
          ),
          CampoDictado(controlador: fila.nombre, etiqueta: 'Nombre', ejemplo: 'Carmen'),
          const SizedBox(height: 14),
          CampoDictado(
            controlador: fila.parentesco,
            etiqueta: 'Es tu…',
            ejemplo: 'hija, nieto, esposo, amiga',
          ),
        ],
      ),
    );
  }
}
