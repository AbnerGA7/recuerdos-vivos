import 'package:flutter/material.dart';

import 'album.dart';
import 'diario.dart';
import 'inicio.dart';

/// Estructura principal con tres secciones fijas en la barra inferior.
/// Las secciones nunca cambian de lugar.
class Navegacion extends StatefulWidget {
  const Navegacion({super.key});

  @override
  State<Navegacion> createState() => _NavegacionState();
}

class _NavegacionState extends State<Navegacion> {
  int _seccion = 0;

  void _ir(int i) => setState(() => _seccion = i);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _seccion,
        children: [
          Inicio(irAlbum: () => _ir(1)),
          const Album(),
          const Diario(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _seccion,
        onDestinationSelected: _ir,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.photo_library_outlined),
            selectedIcon: Icon(Icons.photo_library_rounded),
            label: 'Mis fotos',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book_rounded),
            label: 'Diario',
          ),
        ],
      ),
    );
  }
}
