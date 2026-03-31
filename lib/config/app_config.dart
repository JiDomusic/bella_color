import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppConfig {
  // Supabase config (anon key para cliente; no uses service role en el front).
  static const String supabaseUrl = 'https://unbyowpsmgwdskadwgbi.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVuYnlvd3BzbWd3ZHNrYWR3Z2JpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzMxNTc0NTAsImV4cCI6MjA4ODczMzQ1MH0.h5yPT6NkkzwOKUF1W03PRxx-1Uh7dtqJjEqv6rtekS0';
  // PIN se verifica server-side via verify_super_admin_pin (tabla app_secrets)
  static const String whatsappSoporte = '3413363551';
  static const String nombreEmpresa = 'Programacion JJ';
  static const String storageBucket = 'salon-images';
  static const String publicBaseUrl = 'https://bella-color.web.app'; // dominio de Firebase Hosting

  // Colors — Paleta premium salon de belleza 2026
  static const Color colorPrimario = Color(0xFFE8A0BF);     // Rosa dorado
  static const Color colorSecundario = Color(0xFFB8A9C9);   // Lavanda suave
  static const Color colorTerciario = Color(0xFFE8C4D8);    // Rosa claro
  static const Color colorAcento = Color(0xFFD4AF37);       // Dorado
  static const Color colorFondoOscuro = Color(0xFF0D0B0E);  // Negro cálido
  static const Color colorFondoCard = Color(0xFF1A1720);    // Plum oscuro
  static const Color colorSurfaceVariant = Color(0xFF2A2530); // Mauve gris
  static const Color colorTexto = Color(0xFFF0ECF4);        // Blanco cálido
  static const Color colorTextoSecundario = Color(0xFF9890A8); // Lavanda muted

  // Status colors
  static const Color colorConfirmado = Color(0xFF7FB685);
  static const Color colorPendiente = Color(0xFFF0C674);
  static const Color colorCancelado = Color(0xFFE06C75);
  static const Color colorEnAtencion = Color(0xFFB8A9C9);

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
    final baseText = ThemeData.dark().textTheme;
    final textTheme = baseText.copyWith(
      headlineLarge: GoogleFonts.sora(color: colorTexto, fontWeight: FontWeight.w800, fontSize: 26, letterSpacing: -0.5),
      headlineMedium: GoogleFonts.sora(color: colorTexto, fontWeight: FontWeight.w700, fontSize: 20, letterSpacing: -0.2),
      titleLarge: GoogleFonts.sora(color: colorTexto, fontWeight: FontWeight.w700, fontSize: 16),
      bodyLarge: GoogleFonts.spaceGrotesk(color: colorTexto, fontSize: 14, height: 1.45),
      bodyMedium: GoogleFonts.spaceGrotesk(color: colorTextoSecundario, fontSize: 14, height: 1.45),
      bodySmall: GoogleFonts.spaceGrotesk(color: colorTextoSecundario, fontSize: 12, height: 1.4),
      labelLarge: GoogleFonts.sora(color: colorTexto, fontWeight: FontWeight.w700, fontSize: 13, letterSpacing: 0.3),
    );

    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: colorFondoOscuro,
      primaryColor: primary,
      colorScheme: ColorScheme.dark(
        primary: primary,
        secondary: accent,
        surface: colorFondoCard,
        surfaceContainerHighest: colorSurfaceVariant,
        onPrimary: Colors.white,
        onSecondary: Colors.black,
        onSurface: colorTexto,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: colorFondoOscuro,
        foregroundColor: colorTexto,
        elevation: 0,
        titleTextStyle: GoogleFonts.dmSans(
          color: colorTexto,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        color: colorFondoCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colorSurfaceVariant.withAlpha(80)),
        ),
        margin: const EdgeInsets.only(bottom: 12),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: BorderSide(color: primary.withAlpha(120)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorSurfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primary, width: 1.5),
        ),
        labelStyle: const TextStyle(color: colorTextoSecundario),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      textTheme: textTheme.copyWith(
        headlineLarge: GoogleFonts.dmSans(color: colorTexto, fontWeight: FontWeight.bold, fontSize: 24),
        headlineMedium: GoogleFonts.dmSans(color: colorTexto, fontWeight: FontWeight.w600, fontSize: 18),
        titleLarge: GoogleFonts.dmSans(color: colorTexto, fontWeight: FontWeight.w600, fontSize: 16),
        bodyLarge: GoogleFonts.dmSans(color: colorTexto, fontSize: 14),
        bodyMedium: GoogleFonts.dmSans(color: colorTextoSecundario, fontSize: 14),
        bodySmall: GoogleFonts.dmSans(color: colorTextoSecundario, fontSize: 12),
        labelLarge: GoogleFonts.dmSans(color: colorTexto, fontWeight: FontWeight.w500, fontSize: 14),
      ),
      dividerColor: colorSurfaceVariant.withAlpha(80),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: accent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colorFondoCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colorSurfaceVariant,
        contentTextStyle: GoogleFonts.dmSans(color: colorTexto, fontSize: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: primary,
        unselectedLabelColor: colorTextoSecundario,
        indicatorColor: primary,
        labelStyle: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.dmSans(fontSize: 12),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: colorFondoCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      ),
    );
  }
}
