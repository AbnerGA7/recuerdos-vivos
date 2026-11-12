import 'package:flutter/material.dart';

import '../tema/colores.dart';

/// Botón redondo para responder hablando.
///
/// Es el elemento central de la app: grande, de color caléndula y con
/// un halo que respira mientras escucha, para que se note que está activo.
class BotonVoz extends StatefulWidget {
  const BotonVoz({
    super.key,
    required this.escuchando,
    required this.onTap,
    this.tamano = 132,
    this.habilitado = true,
  });

  final bool escuchando;
  final VoidCallback onTap;
  final double tamano;
  final bool habilitado;

  @override
  State<BotonVoz> createState() => _BotonVozState();
}

class _BotonVozState extends State<BotonVoz>
    with SingleTickerProviderStateMixin {
  late final AnimationController _halo = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

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
    final sinMovimiento = MediaQuery.disableAnimationsOf(context);
    if (widget.escuchando && !sinMovimiento) {
      if (!_halo.isAnimating) _halo.repeat();
    } else {
      _halo
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _halo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.tamano;
    final etiqueta = widget.escuchando ? 'Te escucho' : 'Responder hablando';
    return Semantics(
      button: true,
      enabled: widget.habilitado,
      label: widget.escuchando
          ? 'Escuchando. Toca para terminar.'
          : 'Responder hablando',
      excludeSemantics: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: t * 1.5,
            height: t * 1.5,
            child: Stack(
              alignment: Alignment.center,
              children: [
                AnimatedBuilder(
                  animation: _halo,
                  builder: (_, _) {
                    final v = _halo.value;
                    return Container(
                      width: t * (1 + 0.45 * v),
                      height: t * (1 + 0.45 * v),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colores.calendula
                            .withValues(alpha: widget.escuchando ? 0.45 * (1 - v) : 0),
                      ),
                    );
                  },
                ),
                Material(
                  color: widget.habilitado
                      ? (widget.escuchando ? Colores.tinta : Colores.calendula)
                      : Colores.linea,
                  shape: const CircleBorder(),
                  elevation: 4,
                  shadowColor: const Color(0x55173A35),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: widget.habilitado ? widget.onTap : null,
                    child: SizedBox(
                      width: t,
                      height: t,
                      child: Icon(
                        widget.escuchando
                            ? Icons.graphic_eq_rounded
                            : Icons.mic_rounded,
                        size: t * 0.46,
                        color: widget.escuchando
                            ? Colores.calendula
                            : Colores.tinta,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Text(etiqueta, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}
