import 'package:flutter/material.dart';

/// Paleta de la maqueta: azul marino y dorado (plan, decisión pendiente 5).
class Marca {
  static const azulMarino = Color(0xFF1B2A4A);
  static const dorado = Color(0xFFC9A227);
}

ThemeData temaBellezaValiente() {
  final colores = ColorScheme.fromSeed(
    seedColor: Marca.azulMarino,
    primary: Marca.azulMarino,
    secondary: Marca.dorado,
  );

  return ThemeData(
    colorScheme: colores,
    appBarTheme: const AppBarTheme(
      backgroundColor: Marca.azulMarino,
      foregroundColor: Colors.white,
    ),
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
      ),
    ),
  );
}
