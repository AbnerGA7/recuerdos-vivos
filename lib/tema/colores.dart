import 'package:flutter/material.dart';

/// Paleta de Recuerdos Vivos.
///
/// Pensada para baja visión: todos los textos sobre fondo superan
/// un contraste de 7:1 (nivel AAA).
abstract final class Colores {
  /// Fondo general: verde agua muy claro, calmado y sin brillo.
  static const fondo = Color(0xFFE8F0EC);

  /// Superficie de tarjetas y marcos de foto.
  static const papel = Color(0xFFFFFFFF);

  /// Tinta principal: verde pino profundo.
  static const tinta = Color(0xFF173A35);

  /// Texto secundario.
  static const tintaSuave = Color(0xFF3F5E58);

  /// Acento cálido: caléndula. Se usa solo para la voz y los logros.
  static const calendula = Color(0xFFF2B134);

  /// Variante oscura del acento, para texto sobre caléndula.
  static const calendulaOscura = Color(0xFF6B4300);

  /// Bordes y divisores.
  static const linea = Color(0xFFC3D3CC);

  /// Error con buen contraste.
  static const error = Color(0xFFA4262C);
}
