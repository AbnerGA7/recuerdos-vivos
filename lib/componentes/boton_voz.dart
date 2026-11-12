import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../tema/colores.dart';

/// En qué momento de la conversación está la app.
enum EstadoVoz { reposo, escuchando, pensando, hablando }

/// Botón redondo de la conversación.
///
/// Es el elemento central de la app. Cambia de color y de texto según el
/// turno, y mientras escucha su halo crece con el volumen real de la voz.
class BotonVoz extends StatefulWidget {
  const BotonVoz({
    super.key,
    required this.estado,
    required this.onTap,
    this.nivel,
    this.tamano = 124,
  });

  final EstadoVoz estado;
  final VoidCallback onTap;

  /// Volumen del micrófono entre 0 y 1.
  final ValueListenable<double>? nivel;
  final double tamano;

  @override
  State<BotonVoz> createState() => _BotonVozState();
}

class _BotonVozState extends State<BotonVoz> with SingleTickerProviderStateMixin {
  late final AnimationController _pulso = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  );
  static const _quieto = AlwaysStoppedAnimation<double>(0);

  @override
  void didUpdateWidget(BotonVoz oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sincronizar();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sincronizar();
  }

  void _sincronizar() {
    final activo = widget.estado != EstadoVoz.reposo;
    if (activo && !MediaQuery.disableAnimationsOf(context)) {
      if (!_pulso.isAnimating) _pulso.repeat();
    } else {
      _pulso
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _pulso.dispose();
    super.dispose();
  }

  String get _texto => switch (widget.estado) {
        EstadoVoz.reposo => 'Toca para hablar',
        EstadoVoz.escuchando => 'Te escucho',
        EstadoVoz.pensando => 'Pensando…',
        EstadoVoz.hablando => 'Estoy hablando',
      };

  IconData get _icono => switch (widget.estado) {
        EstadoVoz.reposo => Icons.mic_rounded,
        EstadoVoz.escuchando => Icons.graphic_eq_rounded,
        EstadoVoz.pensando => Icons.more_horiz_rounded,
        EstadoVoz.hablando => Icons.volume_up_rounded,
      };

  @override
  Widget build(BuildContext context) {
    final t = widget.tamano;
    final escuchando = widget.estado == EstadoVoz.escuchando;
    final claro = widget.estado == EstadoVoz.reposo || widget.estado == EstadoVoz.hablando;
    return Semantics(
      button: true,
      label: escuchando ? 'Te escucho. Toca para terminar de hablar.' : _texto,
      excludeSemantics: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: t * 1.6,
            height: t * 1.6,
            child: Stack(
              alignment: Alignment.center,
              children: [
                AnimatedBuilder(
                  animation: Listenable.merge([_pulso, widget.nivel ?? _quieto]),
                  builder: (_, _) {
                    final v = _pulso.value;
                    final voz = widget.nivel?.value ?? 0;
                    // Al escuchar el halo sigue la voz; al hablar respira solo.
                    final extra = escuchando ? 0.15 + 0.45 * voz : 0.4 * v;
                    final alfa = switch (widget.estado) {
                      EstadoVoz.reposo => 0.0,
                      EstadoVoz.escuchando => 0.5,
                      _ => 0.4 * (1 - v),
                    };
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 120),
                      width: t * (1 + extra),
                      height: t * (1 + extra),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colores.calendula.withValues(alpha: alfa),
                      ),
                    );
                  },
                ),
                Material(
                  color: claro ? Colores.calendula : Colores.tinta,
                  shape: const CircleBorder(),
                  elevation: 4,
                  shadowColor: const Color(0x55173A35),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: widget.onTap,
                    child: SizedBox(
                      width: t,
                      height: t,
                      child: Icon(
                        _icono,
                        size: t * 0.46,
                        color: claro ? Colores.tinta : Colores.calendula,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Text(_texto, style: Theme.of(context).textTheme.titleLarge),
        ],
      ),
    );
  }
}
