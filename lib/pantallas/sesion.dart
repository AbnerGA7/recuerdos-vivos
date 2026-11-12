import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../componentes/aviso_voz.dart';
import '../componentes/boton_voz.dart';
import '../componentes/marco_foto.dart';
import '../datos/almacen.dart';
import '../datos/dialogo.dart';
import '../datos/modelos.dart';
import '../datos/texto.dart';
import '../servicios/voz.dart';
import '../tema/colores.dart';

/// Conversación guiada sobre una foto.
///
/// Funciona por turnos y sin manos: la app habla, abre el micrófono sola,
/// la persona responde, el micrófono se cierra con el silencio y la app
/// contesta. Nunca corrige; si hace falta, ayuda con pistas.
class SesionGuiada extends StatefulWidget {
  const SesionGuiada({super.key, required this.recuerdo});

  final Recuerdo recuerdo;

  @override
  State<SesionGuiada> createState() => _SesionGuiadaState();
}

enum _Fase { hablando, escuchando, pensando, pausa }

class _SesionGuiadaState extends State<SesionGuiada> {
  late final MotorDialogo _motor;
  late Voz _voz;
  late Almacen _almacen;
  bool _iniciada = false;

  _Fase _fase = _Fase.pensando;
  String _textoApp = '';
  String _ultimoDicho = '';
  int _silencios = 0;

  /// Cambia cada vez que empieza un turno nuevo; los turnos viejos se descartan.
  int _ficha = 0;

  bool get _leer => _almacen.ajustes.leerEnVozAlta;
  bool get _manosLibres => _almacen.ajustes.manosLibres;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _voz = VozScope.leer(context);
    _almacen = AlmacenScope.leer(context);
    if (_iniciada) return;
    _iniciada = true;
    _motor = MotorDialogo(widget.recuerdo, nombre: _almacen.ajustes.nombre);
    WidgetsBinding.instance.addPostFrameCallback((_) => _turno(_motor.abrir()));
  }

  @override
  void dispose() {
    _ficha++;
    unawaited(_voz.callar());
    unawaited(_voz.detenerEscucha());
    super.dispose();
  }

  /// La app dice algo y después cede el turno a la persona.
  Future<void> _turno(Reaccion r) async {
    final ficha = ++_ficha;
    if (r.masDespacio) {
      final lenta = (_voz.velocidad - 0.07).clamp(0.25, 0.6).toDouble();
      await _voz.cambiarVelocidad(lenta);
      unawaited(_almacen.actualizarAjustes((a) => a.velocidadVoz = lenta));
    }
    if (!mounted || ficha != _ficha) return;
    setState(() {
      _fase = _Fase.hablando;
      _textoApp = r.decir;
    });
    if (_leer) await _voz.decir(r.decir);
    if (!mounted || ficha != _ficha) return;
    if (r.fin || _motor.terminado) {
      await _irAlCierre();
      return;
    }
    if (_manosLibres && _leer) {
      await _escuchar(ficha);
    } else {
      setState(() => _fase = _Fase.pausa);
    }
  }

  /// Abre el micrófono y espera a que la persona hable y se quede callada.
  Future<void> _escuchar(int ficha) async {
    setState(() => _fase = _Fase.escuchando);
    unawaited(HapticFeedback.selectionClick());
    final texto = await _voz.escucharFrase();
    if (!mounted || ficha != _ficha) return;
    unawaited(HapticFeedback.selectionClick());
    if (texto == null) {
      if (_voz.fallo != FalloEscucha.silencio) {
        setState(() => _fase = _Fase.pausa);
        return;
      }
      _silencios++;
      if (_silencios == 1) {
        await _turno(const Reaccion('Tómate tu tiempo. Aquí estoy.'));
      } else {
        _silencios = 0;
        _ficha++;
        setState(() {
          _fase = _Fase.pausa;
          _textoApp = 'Estoy aquí contigo. Toca el micrófono cuando quieras seguir.';
        });
        if (_leer) await _voz.decir(_textoApp);
      }
      return;
    }
    _silencios = 0;
    await _responder(texto);
  }

  Future<void> _responder(String texto) async {
    setState(() {
      _ultimoDicho = texto;
      _fase = _Fase.pensando;
    });
    await _turno(_motor.escuchar(texto));
  }

  Future<void> _tocarMicrofono() async {
    if (_fase == _Fase.escuchando) {
      // Cierra el micrófono; la escucha en curso entrega lo que entendió.
      await _voz.detenerEscucha();
      return;
    }
    final ficha = ++_ficha;
    await _voz.callar();
    if (!mounted) return;
    await _escuchar(ficha);
  }

  Future<void> _pausar() async {
    _ficha++;
    await _voz.callar();
    await _voz.detenerEscucha();
    if (mounted) setState(() => _fase = _Fase.pausa);
  }

  Future<void> _accion(Reaccion Function() accion) async {
    _ficha++;
    await _voz.detenerEscucha();
    if (!mounted) return;
    await _turno(accion());
  }

  Future<void> _escribir() async {
    await _pausar();
    if (!mounted) return;
    final c = TextEditingController();
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
            Text(_motor.preguntaActual, style: Theme.of(c2).textTheme.titleLarge),
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
    if (texto != null && texto.isNotEmpty && mounted) await _responder(texto);
  }

  Future<void> _irAlCierre() async {
    _ficha++;
    await _voz.callar();
    if (!mounted) return;
    await Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => CierreSesion(recuerdo: widget.recuerdo, respuestas: _motor.respuestas),
      ),
    );
  }

  Future<void> _salir() async {
    await _pausar();
    if (!mounted) return;
    final si = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('¿Terminar por hoy?'),
        content: const Text('Lo que conversamos se guardará en tu diario.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Seguir')),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Terminar')),
        ],
      ),
    );
    if (si != true || !mounted) return;
    _motor.terminar();
    if (_motor.respuestas.isEmpty) {
      Navigator.of(context).pop();
    } else {
      await _irAlCierre();
    }
  }

  EstadoVoz get _estadoBoton => switch (_fase) {
        _Fase.hablando => EstadoVoz.hablando,
        _Fase.escuchando => EstadoVoz.escuchando,
        _Fase.pensando => EstadoVoz.pensando,
        _Fase.pausa => EstadoVoz.reposo,
      };

  @override
  Widget build(BuildContext context) {
    final voz = VozScope.of(context);
    final estilos = Theme.of(context).textTheme;
    final total = _motor.preguntas.length;
    final actual = _motor.indice.clamp(0, total - 1);
    final enVivo = _fase == _Fase.escuchando ? voz.textoEscuchado : _ultimoDicho;
    final sinMovimiento = MediaQuery.disableAnimationsOf(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_salir());
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            tooltip: 'Terminar',
            iconSize: 32,
            icon: const Icon(Icons.close_rounded),
            onPressed: _salir,
          ),
          title: Semantics(
            label: 'Pregunta ${actual + 1} de $total',
            excludeSemantics: true,
            child: _Progreso(total: total, actual: actual),
          ),
          actions: [
            if (_fase != _Fase.pausa)
              TextButton.icon(
                onPressed: _pausar,
                icon: const Icon(Icons.pause_rounded, size: 28),
                label: const Text('Pausa'),
              ),
            const SizedBox(width: 8),
          ],
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 4, 24, 28),
            children: [
              // La foto aparece una sola vez, como si se revelara.
              TweenAnimationBuilder<double>(
                tween: Tween(begin: sinMovimiento ? 1 : 0, end: 1),
                duration: const Duration(milliseconds: 900),
                curve: Curves.easeOutCubic,
                builder: (_, v, hijo) => Opacity(
                  opacity: v,
                  child: Transform.scale(scale: 0.94 + 0.06 * v, child: hijo),
                ),
                child: MarcoFoto(
                  ruta: widget.recuerdo.rutaFoto,
                  descripcion: widget.recuerdo.tituloVisible,
                  alto: 200,
                ),
              ),
              const SizedBox(height: 22),
              _Subtitulos(texto: _textoApp, fraseActual: voz.fraseActual),
              if (enVivo.trim().isNotEmpty)
                _Dicho(texto: enVivo, enVivo: _fase == _Fase.escuchando),
              const AvisoVoz(),
              const SizedBox(height: 8),
              Center(
                child: BotonVoz(
                  estado: _estadoBoton,
                  nivel: voz.nivel,
                  onTap: _tocarMicrofono,
                ),
              ),
              const SizedBox(height: 18),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 10,
                runSpacing: 10,
                children: [
                  _Accion(
                    icono: Icons.lightbulb_outline_rounded,
                    texto: 'Pista',
                    onTap: () => _accion(_motor.pedirPista),
                  ),
                  _Accion(
                    icono: Icons.arrow_forward_rounded,
                    texto: 'Siguiente',
                    onTap: () => _accion(_motor.saltar),
                  ),
                  _Accion(
                    icono: Icons.keyboard_rounded,
                    texto: 'Escribir',
                    onTap: _escribir,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Lo que dice la app, con la frase que suena ahora resaltada.
class _Subtitulos extends StatelessWidget {
  const _Subtitulos({required this.texto, required this.fraseActual});

  final String texto;
  final String fraseActual;

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).textTheme.titleLarge!;
    final frases = partirEnFrases(texto);
    final hayActual = frases.contains(fraseActual);
    return Semantics(
      liveRegion: true,
      label: texto,
      excludeSemantics: true,
      child: Text.rich(
        TextSpan(
          children: [
            for (final f in frases)
              TextSpan(
                text: '$f ',
                style: base.copyWith(
                  fontSize: base.fontSize! + 2,
                  height: 1.35,
                  color: !hayActual || f == fraseActual ? Colores.tinta : Colores.tintaSuave,
                  fontWeight: !hayActual || f == fraseActual ? FontWeight.w700 : FontWeight.w400,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Burbuja con lo que dijo la persona.
class _Dicho extends StatelessWidget {
  const _Dicho({required this.texto, required this.enVivo});

  final String texto;
  final bool enVivo;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(top: 16, left: 36),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: Colores.papel,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(4),
          ),
          border: Border.all(color: enVivo ? Colores.calendula : Colores.linea, width: 2),
        ),
        child: Text(texto, style: Theme.of(context).textTheme.bodyLarge),
      ),
    );
  }
}

class _Accion extends StatelessWidget {
  const _Accion({required this.icono, required this.texto, required this.onTap});

  final IconData icono;
  final String texto;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 60),
        backgroundColor: Colores.papel,
        side: const BorderSide(color: Colores.linea, width: 2),
        padding: const EdgeInsets.symmetric(horizontal: 18),
      ),
      onPressed: onTap,
      icon: Icon(icono, size: 26),
      label: Text(texto),
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
      unawaited(VozScope.leer(context).decir('¿Cómo te sientes ahora?'));
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
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: MediaQuery.disableAnimationsOf(context) ? 1 : 0.4, end: 1),
                duration: const Duration(milliseconds: 700),
                curve: Curves.elasticOut,
                builder: (_, escala, hijo) => Transform.scale(scale: escala, child: hijo),
                child: Container(
                  width: 112,
                  height: 112,
                  decoration: const BoxDecoration(color: Colores.calendula, shape: BoxShape.circle),
                  child: const Icon(Icons.favorite_rounded, size: 60, color: Colores.tinta),
                ),
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
