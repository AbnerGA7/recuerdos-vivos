import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../datos/almacen.dart';

/// Pide el PIN del modo cuidador antes de una acción delicada.
///
/// Devuelve true si no hay PIN configurado o si el PIN es correcto.
Future<bool> pedirPin(BuildContext context) async {
  final pin = AlmacenScope.leer(context).ajustes.pin;
  if (pin.isEmpty) return true;
  final escrito = await _dialogoPin(
    context,
    titulo: 'PIN del cuidador',
    ayuda: 'Esta parte es para el familiar o cuidador.',
  );
  if (escrito == null) return false;
  if (escrito == pin) return true;
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('El PIN no coincide.')),
    );
  }
  return false;
}

/// Pide un PIN nuevo de 4 números. Devuelve null si se cancela.
Future<String?> crearPin(BuildContext context) => _dialogoPin(
      context,
      titulo: 'Nuevo PIN',
      ayuda: 'Escribe 4 números. Se pedirá para editar, borrar y abrir los ajustes.',
    );

Future<String?> _dialogoPin(BuildContext context, {required String titulo, required String ayuda}) {
  final c = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (d) => AlertDialog(
      title: Text(titulo),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(ayuda),
          const SizedBox(height: 16),
          TextField(
            controller: c,
            autofocus: true,
            obscureText: true,
            maxLength: 4,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            textAlign: TextAlign.center,
            style: Theme.of(d).textTheme.headlineMedium?.copyWith(letterSpacing: 12),
            onSubmitted: (v) {
              if (v.length == 4) Navigator.pop(d, v);
            },
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(d), child: const Text('Cancelar')),
        TextButton(
          onPressed: () {
            if (c.text.length == 4) Navigator.pop(d, c.text);
          },
          child: const Text('Aceptar'),
        ),
      ],
    ),
  );
}
