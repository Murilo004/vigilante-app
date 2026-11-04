// Cores e tema visual do app.

import 'package:flutter/material.dart';

/// Cores da identidade do app.
const Color corPanico = Color(0xFFD32F2F);
const Color corAlerta = Color(0xFFF57C00);
const Color corConcluido = Color(0xFF2E7D32);

/// Tema do app (azul, cantos arredondados, botões altos).
ThemeData temaDoApp() {
  final esquema = ColorScheme.fromSeed(seedColor: Colors.blue);
  final cantos = RoundedRectangleBorder(borderRadius: BorderRadius.circular(12));
  final tamanhoBotao = Size(64, 48);

  return ThemeData(
    useMaterial3: true,
    colorScheme: esquema,
    scaffoldBackgroundColor: esquema.surface,
    appBarTheme: AppBarTheme(
      centerTitle: false,
      backgroundColor: esquema.surface,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: esquema.onSurface,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: esquema.surfaceContainerHighest.withValues(alpha: 0.4),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: esquema.outlineVariant),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(minimumSize: tamanhoBotao, shape: cantos),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(minimumSize: tamanhoBotao, shape: cantos),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(minimumSize: tamanhoBotao, shape: cantos),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: esquema.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: esquema.outlineVariant.withValues(alpha: 0.5)),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: cantos,
    ),
  );
}
