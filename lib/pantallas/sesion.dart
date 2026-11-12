import 'dart:async';

import 'package:flutter/material.dart';

import '../componentes/aviso_voz.dart';
import '../componentes/boton_escuchar.dart';
import '../componentes/boton_voz.dart';
import '../componentes/marco_foto.dart';
import '../datos/almacen.dart';
import '../datos/modelos.dart';
import '../datos/preguntas.dart';
import '../servicios/voz.dart';
import '../tema/colores.dart';

/// Sesión guiada: la app lee cada pregunta y la persona responde hablando.
///
/// No hay respuestas incorrectas. Si la persona no sabe, puede pedir
/// una pista o pasar a la siguiente pregunta.
class SesionGuiada extends StatefulWidget {
  const SesionGuiada({super.key, required this.recuerdo});

  final Recuerdo recuerdo;

  @override
  State<SesionGuiada> createState() => _SesionGuiadaState();
}

class _SesionGuiadaState extends State<SesionGuiada> {
  late final List<Pregunta> _preguntas = armarPreguntas(widget.recuerdo);
  final List<Respuesta> _respuestas = [];
  int _indice = 0;
  String _respuestaActual = '';
  bool _pistaVisible = false;
  String? _animo;
  late Voz _voz;

  Pregunta get _pregunta => _preguntas[_indice];
  bool get _leerEnVozAlta => AlmacenScope.leer(context).ajustes.leerEnVozAlta;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _leerPregunta());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _voz = VozScope.leer(context);
  }

  @override
  void dispose() {
    unawaited(_voz.callar());
    unawaited(_voz.detenerEscucha());
    super.dispose();
  }

  Future<void> _leerPregunta() async {
    if (!mounted || !_leerEnVozAlta) return;
    final previo = _animo;
    await _voz.decir(previo == null ? _pregunta.texto : '$previo ${_pregunta.texto}');
  }

  Future<void> _hablar() async {
    if (_voz.escuchando) {
      await _voz.detenerEscucha();
      return;
    }
    await _voz.escuchar((texto) {
      if (!mounted) return;
      setState(() => _respuestaActual = _respuestaActual.isEmpty ? texto : '$_respuestaActual $texto');
    });
  }

  Future<void> _escribir() async {
    final c = TextEditingController(text: _respuestaActual);
    final texto = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (c2) => Padding(
        padding: EdgeInsets.fromLTRB(24, 0, 24, 24 + MediaQuery.viewInsetsOf(c2).bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(_pregunta.texto, style: Theme.of(c2).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextField(
              controller: c,
              autofocus: true,
              minLines: 2,
              maxLines: 5,
              textCapitalization: TextCapitalization.sentences,
              style: Theme.of(c2).textTheme.bodyLarge,
              decoration: const InputDecoration(hintText: 'Escribe aquí tu respuesta'),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => Navigator.pop(c2, c.text.trim()),
              child: const Text('Listo'),
            ),
          ],
        ),
      ),
    );
    c.dispose();
    if (texto != null && mounted) setState(() => _respuestaActual = texto);
  }

  Future<void> _verPista() async {
    final pista = _pregunta.pista;
    if (pista == null) return;
    setState(() => _pistaVisible = true);
    if (_leerEnVozAlta) await _voz.decir(pista);
  }

  Future<void> _avanzar({bool saltar = false}) async {
    await _voz.detenerEscucha();
    final respuesta = _respuestaActual.trim();
    if (!saltar && respuesta.isNotEmpty) {
      _respuestas.add(Respuesta(pregunta: _pregunta.texto, texto: respuesta));
    }
    if (_indice == _preguntas.length - 1) {
      await _voz.callar();
      if (!mounted) return;
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => CierreSesion(recuerdo: widget.recuerdo, respuestas: _respuestas),
        ),
      );
      return;
    }
    setState(() {
      _animo = respuesta.isNotEmpty && !saltar ? fraseDeAnimo(_respuestas.length - 1) : null;
      _indice++;
      _respuestaActual = '';
      _pistaVisible = false;
    });
    await _leerPregunta();
  }

  Future<bool> _confirmarSalida() async {
    final si = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('¿Terminar por hoy?'),
        content: const Text('Puedes volver a esta foto cuando quieras.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Seguir')),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Terminar')),
        ],
      ),
    );
    return si ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final voz = VozScope.of(context);
    final estilos = Theme.of(context).textTheme;
    final ultima = _indice == _preguntas.length - 1;
    final hayRespuesta = _respuestaActual.trim().isNotEmpty;
    final enVivo = voz.escuchando ? voz.textoEscuchado : _respuestaActual;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final nav = Navigator.of(context);
        if (await _confirmarSalida()) nav.pop();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            tooltip: 'Terminar',
            iconSize: 32,
            icon: const Icon(Icons.close_rounded),
            onPressed: () => Navigator.maybePop(context),
          ),
          title: Semantics(
            label: 'Pregunta ${_indice + 1} de ${_preguntas.length}',
            excludeSemantics: true,
            child: _Progreso(total: _preguntas.length, actual: _indice),
          ),
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 4, 24, 28),
            children: [
              MarcoFoto(
                ruta: widget.recuerdo.rutaFoto,
                descripcion: widget.recuerdo.tituloVisible,
                alto: 210,
              ),
              const SizedBox(height: 24),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Column(
                  key: ValueKey(_indice),
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_animo != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(_animo!,
                            style: estilos.titleMedium?.copyWith(color: Colores.calendulaOscura)),
                      ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Semantics(
                            liveRegion: true,
                            child: Text(_pregunta.texto, style: estilos.headlineMedium),
                          ),
                        ),
                        const SizedBox(width: 8),
                        BotonEscuchar(
                          leyendo: voz.leyendo,
                          onTap: () => voz.leyendo ? voz.callar() : voz.decir(_pregunta.texto),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (_pistaVisible && _pregunta.pista != null) _Pista(texto: _pregunta.pista!),
              const SizedBox(height: 12),
              Center(child: BotonVoz(escuchando: voz.escuchando, onTap: _hablar)),
              const AvisoVoz(),
              if (enVivo.trim().isNotEmpty) _RespuestaCaja(texto: enVivo, enVivo: voz.escuchando),
              const SizedBox(height: 16),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 4,
                children: [
                  TextButton.icon(
                    onPressed: _escribir,
                    icon: const Icon(Icons.keyboard_rounded, size: 28),
                    label: const Text('Prefiero escribir'),
                  ),
                  if (_pregunta.pista != null && !_pistaVisible)
                    TextButton.icon(
                      onPressed: _verPista,
                      icon: const Icon(Icons.lightbulb_outline_rounded, size: 28),
                      label: const Text('Dame una pista'),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => _avanzar(),
                child: Text(ultima ? 'Terminar' : (hayRespuesta ? 'Siguiente' : 'No recuerdo, seguir')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Progreso extends StatelessWidget {
  const _Progreso({required this.total, required this.actual});

  final int total;
  final int actual;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(total, (i) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: i == actual ? 32 : 14,
          height: 14,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: i <= actual ? Colores.tinta : Colores.linea,
            borderRadius: BorderRadius.circular(7),
          ),
        );
      }),
    );
  }
}

class _Pista extends StatelessWidget {
  const _Pista({required this.texto});

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3D6),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const Icon(Icons.lightbulb_outline_rounded, size: 30, color: Colores.calendulaOscura),
          const SizedBox(width: 12),
          Expanded(child: Text(texto, style: Theme.of(context).textTheme.bodyLarge)),
        ],
      ),
    );
  }
}

class _RespuestaCaja extends StatelessWidget {
  const _RespuestaCaja({required this.texto, required this.enVivo});

  final String texto;
  final bool enVivo;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colores.papel,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: enVivo ? Colores.calendula : Colores.linea, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(enVivo ? 'Te escucho:' : 'Tu respuesta:',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colores.tintaSuave)),
          const SizedBox(height: 6),
          Text(texto, style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }
}

/// Cierre de la sesión: agradece, pregunta cómo se sintió y guarda en el diario.
class CierreSesion extends StatefulWidget {
  const CierreSesion({super.key, required this.recuerdo, required this.respuestas});

  final Recuerdo recuerdo;
  final List<Respuesta> respuestas;

  @override
  State<CierreSesion> createState() => _CierreSesionState();
}

class _CierreSesionState extends State<CierreSesion> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !AlmacenScope.leer(context).ajustes.leerEnVozAlta) return;
      unawaited(VozScope.leer(context)
          .decir('Muy bien, terminamos. Gracias por compartir este recuerdo. ¿Cómo te sientes?'));
    });
  }

  Future<void> _terminar(Animo animo) async {
    final almacen = AlmacenScope.leer(context);
    await VozScope.leer(context).callar();
    await almacen.guardarSesion(Sesion(
      id: almacen.nuevoId(),
      recuerdoId: widget.recuerdo.id,
      respuestas: widget.respuestas,
      animo: animo,
    ));
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final estilos = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 40, 24, 28),
          children: [
            Center(
              child: Container(
                width: 112,
                height: 112,
                decoration: const BoxDecoration(color: Colores.calendula, shape: BoxShape.circle),
                child: const Icon(Icons.check_rounded, size: 64, color: Colores.tinta),
              ),
            ),
            const SizedBox(height: 28),
            Text('¡Terminamos!', style: estilos.displaySmall, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            Text(
              widget.respuestas.isEmpty
                  ? 'Gracias por mirar este recuerdo conmigo.'
                  : 'Compartiste ${widget.respuestas.length} ${widget.respuestas.length == 1 ? 'respuesta' : 'respuestas'}. Quedan guardadas en tu diario.',
              style: estilos.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 36),
            Text('¿Cómo te sientes?', style: estilos.headlineMedium, textAlign: TextAlign.center),
            const SizedBox(height: 18),
            _OpcionAnimo(
              icono: Icons.sentiment_very_satisfied_rounded,
              texto: 'Contento',
              onTap: () => _terminar(Animo.contento),
            ),
            const SizedBox(height: 12),
            _OpcionAnimo(
              icono: Icons.sentiment_satisfied_rounded,
              texto: 'Tranquilo',
              onTap: () => _terminar(Animo.tranquilo),
            ),
            const SizedBox(height: 12),
            _OpcionAnimo(
              icono: Icons.sentiment_dissatisfied_rounded,
              texto: 'Cansado',
              onTap: () => _terminar(Animo.cansado),
            ),
          ],
        ),
      ),
    );
  }
}

class _OpcionAnimo extends StatelessWidget {
  const _OpcionAnimo({required this.icono, required this.texto, required this.onTap});

  final IconData icono;
  final String texto;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(80),
        backgroundColor: Colores.papel,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 24),
      ),
      onPressed: onTap,
      icon: Icon(icono, size: 40),
      label: Text(texto),
    );
  }
}
