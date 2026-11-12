import 'package:flutter/material.dart';

import '../componentes/campo_dictado.dart';
import '../datos/almacen.dart';
import '../servicios/voz.dart';
import '../tema/colores.dart';

/// Presentación de tres pasos la primera vez que se abre la app.
class Bienvenida extends StatefulWidget {
  const Bienvenida({super.key});

  @override
  State<Bienvenida> createState() => _BienvenidaState();
}

class _BienvenidaState extends State<Bienvenida> {
  final _paginas = PageController();
  final _nombre = TextEditingController();
  int _paso = 0;

  static const _textos = [
    'Hola. Esta app te ayuda a recordar momentos bonitos con tus fotos. '
        'Yo te leo todo en voz alta y tú puedes responder hablando.',
    '¿Cómo te llamas? Toca el micrófono y dímelo, o escríbelo.',
    'Un familiar puede agregar fotos y contar quién sale en ellas. '
        'Así te daré pistas cuando las necesites.',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _leerPaso());
  }

  @override
  void dispose() {
    _paginas.dispose();
    _nombre.dispose();
    super.dispose();
  }

  Future<void> _leerPaso() async {
    final almacen = AlmacenScope.leer(context);
    if (!almacen.ajustes.leerEnVozAlta) return;
    await VozScope.leer(context).decir(_textos[_paso]);
  }

  Future<void> _siguiente() async {
    if (_paso < 2) {
      setState(() => _paso++);
      await _paginas.animateToPage(
        _paso,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
      if (!mounted) return;
      await _leerPaso();
      return;
    }
    final almacen = AlmacenScope.leer(context);
    await VozScope.leer(context).callar();
    await almacen.actualizarAjustes((a) {
      a.nombre = _nombre.text.trim();
      a.bienvenidaVista = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final estilos = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                label: 'Paso ${_paso + 1} de 3',
                child: Row(
                  children: List.generate(3, (i) {
                    return Expanded(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        height: 8,
                        margin: EdgeInsets.only(right: i < 2 ? 8 : 0),
                        decoration: BoxDecoration(
                          color: i <= _paso ? Colores.tinta : Colores.linea,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              Expanded(
                child: PageView(
                  controller: _paginas,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _Pagina(
                      icono: Icons.auto_stories_rounded,
                      titulo: 'Recuerdos Vivos',
                      texto: _textos[0],
                    ),
                    ListView(
                      padding: const EdgeInsets.only(top: 48),
                      children: [
                        Text('¿Cómo te llamas?', style: estilos.displaySmall),
                        const SizedBox(height: 16),
                        Text('Así podré saludarte por tu nombre.', style: estilos.bodyLarge),
                        const SizedBox(height: 32),
                        CampoDictado(
                          controlador: _nombre,
                          etiqueta: 'Tu nombre',
                          ejemplo: 'Por ejemplo: Rosa',
                        ),
                      ],
                    ),
                    _Pagina(
                      icono: Icons.volunteer_activism_rounded,
                      titulo: 'Con ayuda de tu familia',
                      texto: _textos[2],
                    ),
                  ],
                ),
              ),
              FilledButton(
                onPressed: _siguiente,
                child: Text(_paso < 2 ? 'Continuar' : 'Empezar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Pagina extends StatelessWidget {
  const _Pagina({required this.icono, required this.titulo, required this.texto});

  final IconData icono;
  final String titulo;
  final String texto;

  @override
  Widget build(BuildContext context) {
    final estilos = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.only(top: 48),
      children: [
        Container(
          width: 112,
          height: 112,
          alignment: Alignment.center,
          decoration: const BoxDecoration(color: Colores.calendula, shape: BoxShape.circle),
          child: Icon(icono, size: 56, color: Colores.tinta),
        ),
        const SizedBox(height: 32),
        Text(titulo, style: estilos.displaySmall),
        const SizedBox(height: 16),
        Text(texto, style: estilos.bodyLarge),
      ],
    );
  }
}
