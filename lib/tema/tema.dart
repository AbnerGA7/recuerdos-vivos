import 'package:flutter/material.dart';

import 'colores.dart';

/// Tema global: letra grande, botones altos y formas suaves.
ThemeData crearTema({double escalaTexto = 1.0}) {
  const familia = 'AtkinsonHyperlegible';
  final esquema = ColorScheme.fromSeed(
    seedColor: Colores.tinta,
    surface: Colores.fondo,
  ).copyWith(
    primary: Colores.tinta,
    onPrimary: Colores.papel,
    secondary: Colores.calendula,
    onSecondary: Colores.tinta,
    surface: Colores.fondo,
    onSurface: Colores.tinta,
    error: Colores.error,
  );

  TextStyle t(double size, FontWeight w, {double alto = 1.3}) => TextStyle(
        fontFamily: familia,
        fontSize: size * escalaTexto,
        fontWeight: w,
        height: alto,
        color: Colores.tinta,
      );

  final forma = RoundedRectangleBorder(borderRadius: BorderRadius.circular(20));

  return ThemeData(
    useMaterial3: true,
    colorScheme: esquema,
    fontFamily: familia,
    scaffoldBackgroundColor: Colores.fondo,
    textTheme: TextTheme(
      displaySmall: t(38, FontWeight.w700, alto: 1.15),
      headlineMedium: t(30, FontWeight.w700, alto: 1.2),
      titleLarge: t(24, FontWeight.w700),
      titleMedium: t(20, FontWeight.w700),
      bodyLarge: t(21, FontWeight.w400, alto: 1.45),
      bodyMedium: t(19, FontWeight.w400, alto: 1.45),
      labelLarge: t(21, FontWeight.w700),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colores.fondo,
      foregroundColor: Colores.tinta,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: t(24, FontWeight.w700),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: Colores.tinta,
        foregroundColor: Colores.papel,
        minimumSize: const Size.fromHeight(68),
        textStyle: t(21, FontWeight.w700),
        shape: forma,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: Colores.tinta,
        minimumSize: const Size.fromHeight(64),
        side: const BorderSide(color: Colores.tinta, width: 2),
        textStyle: t(20, FontWeight.w700),
        shape: forma,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: Colores.tinta,
        minimumSize: const Size(64, 56),
        textStyle: t(19, FontWeight.w700),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colores.papel,
      contentPadding: const EdgeInsets.all(20),
      labelStyle: t(19, FontWeight.w700),
      hintStyle: t(19, FontWeight.w400).copyWith(color: Colores.tintaSuave),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colores.linea, width: 2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colores.linea, width: 2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colores.tinta, width: 3),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colores.papel,
      indicatorColor: Colores.calendula,
      height: 84,
      labelTextStyle: WidgetStatePropertyAll(t(17, FontWeight.w700)),
      iconTheme: const WidgetStatePropertyAll(
        IconThemeData(size: 32, color: Colores.tinta),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: Colores.tinta,
      contentTextStyle: t(19, FontWeight.w400).copyWith(color: Colores.papel),
      behavior: SnackBarBehavior.floating,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: Colores.papel,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
    ),
  );
}
