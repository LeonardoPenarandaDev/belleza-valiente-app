import 'package:flutter/material.dart';

/// Paleta de la marca: azul marino y dorado.
class Marca {
  static const azulMarino = Color(0xFF14213D);
  static const azulProfundo = Color(0xFF0D1728);
  static const dorado = Color(0xFFC9A227);
  static const doradoOscuro = Color(0xFFA68218);
  static const doradoClaro = Color(0xFFFDF8E7);
  static const fondo = Color(0xFFF8F9FC);
  static const superficie = Colors.white;
  static const textoPrincipal = Color(0xFF1E293B);
  static const textoSecundario = Color(0xFF64748B);
  static const bordeSuave = Color(0xFFE2E8F0);
}

ThemeData temaBellezaValiente() {
  final colores = ColorScheme.fromSeed(
    seedColor: Marca.azulMarino,
    primary: Marca.azulMarino,
    secondary: Marca.dorado,
    surface: Marca.superficie,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colores,
    scaffoldBackgroundColor: Marca.fondo,
    appBarTheme: const AppBarTheme(
      backgroundColor: Marca.azulMarino,
      foregroundColor: Colors.white,
      centerTitle: true,
      elevation: 0,
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 19,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.3,
      ),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 1.5,
      shadowColor: Colors.black.withValues(alpha: 0.06),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Marca.bordeSuave, width: 0.8),
      ),
      margin: const EdgeInsets.symmetric(vertical: 6),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Marca.bordeSuave),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Marca.bordeSuave),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Marca.azulMarino, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: Marca.azulMarino,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
        elevation: 1,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: Marca.azulMarino,
        minimumSize: const Size.fromHeight(48),
        side: const BorderSide(color: Marca.azulMarino, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: const Color(0xFFF1F5F9),
      side: const BorderSide(color: Marca.bordeSuave, width: 0.8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      labelStyle: const TextStyle(fontSize: 13, color: Marca.textoPrincipal),
    ),
  );
}
