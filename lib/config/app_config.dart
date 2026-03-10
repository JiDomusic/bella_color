import 'package:flutter/material.dart';

class AppConfig {
  // Supabase config (anon key para cliente; no uses service role en el front).
  static const String supabaseUrl = 'https://unbyowpsmgwdskadwgbi.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVuYnlvd3BzbWd3ZHNrYWR3Z2JpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzMxNTc0NTAsImV4cCI6MjA4ODczMzQ1MH0.h5yPT6NkkzwOKUF1W03PRxx-1Uh7dtqJjEqv6rtekS0';
  static const String superAdminPin = '123456';
  static const String whatsappSoporte = '3413363551';
  static const String nombreEmpresa = 'Programacion JJ';
  static const String storageBucket = 'salon-images';
  static const String publicBaseUrl = 'https://bella-color.web.app'; // dominio de Firebase Hosting

  // Colors
  static const Color colorPrimario = Color(0xFFD4A0A0);
  static const Color colorSecundario = Color(0xFFC48B8B);
  static const Color colorTerciario = Color(0xFFE8C4C4);
  static const Color colorAcento = Color(0xFFD4AF37);
  static const Color colorFondoOscuro = Color(0xFF0A0E14);
  static const Color colorFondoCard = Color(0xFF1A1E24);
  static const Color colorTexto = Color(0xFFF5F5F5);
  static const Color colorTextoSecundario = Color(0xFFAAAAAA);

  static Color hexToColor(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.parse(hex, radix: 16));
  }

  static ThemeData buildTheme({
    Color? primario,
    Color? secundario,
    Color? acento,
  }) {
    final primary = primario ?? colorPrimario;
    final accent = acento ?? colorAcento;

    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: colorFondoOscuro,
      primaryColor: primary,
      colorScheme: ColorScheme.dark(
        primary: primary,
        secondary: accent,
        surface: colorFondoCard,
        onPrimary: Colors.white,
        onSecondary: Colors.black,
        onSurface: colorTexto,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: colorFondoOscuro,
        foregroundColor: colorTexto,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: colorFondoCard,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: BorderSide(color: primary),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorFondoCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primary.withAlpha(80)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primary.withAlpha(80)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primary, width: 2),
        ),
        labelStyle: TextStyle(color: colorTextoSecundario),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(color: colorTexto, fontWeight: FontWeight.bold),
        headlineMedium: TextStyle(color: colorTexto, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(color: colorTexto),
        bodyMedium: TextStyle(color: colorTextoSecundario),
      ),
      dividerColor: primary.withAlpha(40),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: accent,
        foregroundColor: Colors.white,
      ),
    );
  }
}
