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
  late final _personas = TextEditingController(text: widget.editar?.personas);
  late final _lugar = TextEditingController(text: widget.editar?.lugar);
  late final _cuando = TextEditingController(text: widget.editar?.cuando);
  late final _historia = TextEditingController(text: widget.editar?.historia);
  late String? _foto = widget.editar?.rutaFoto;
  bool _guardando = false;

  @override
  void dispose() {
    for (final c in [_titulo, _personas, _lugar, _cuando, _historia]) {
      c.dispose();
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
      personas: _personas.text.trim(),
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
              CampoDictado(controlador: _personas, etiqueta: '¿Quiénes salen?', ejemplo: 'Tu hija Carmen y tu nieto Luis'),
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
