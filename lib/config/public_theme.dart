import 'package:flutter/material.dart';

/// Paleta y tipografías públicas estilo Bleach London.
/// Usa la familia Termina (cargada como asset local) con fallback en Sora/sans.
class PublicTheme {
  // Colores principales (los colores de cada tenant se siguen leyendo de Supabase).
  static const Color cream = Color(0xFFF7F2EE);
  static const Color paper = Color(0xFFFFFFFF);
  static const Color ink = Color(0xFF0F0F0F);
  static const Color muted = Color(0xFF3C3C3C);
  static const Color softMuted = Color(0xFF6B6B6B);
  static const Color blush = Color(0xFFF7A0B5);
  static const Color blushDark = Color(0xFFE77998);
  static const Color stroke = Color(0xFFE6DBD3);
  static const Color nav = Colors.black;

  static const BorderRadius borderMd = BorderRadius.all(Radius.circular(14));
  static const BorderRadius borderLg = BorderRadius.all(Radius.circular(18));

  // Fallback suave para cuando no está Termina disponible.
  static const List<String> _fallback = ['Sora', 'sans-serif'];

  static TextStyle get heroTitle => const TextStyle(
        fontFamily: 'Termina',
        fontFamilyFallback: _fallback,
        fontSize: 30,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
        height: 1.05,
        color: ink,
      );

  static TextStyle get heroSubtitle => const TextStyle(
        fontFamily: 'Termina',
        fontFamilyFallback: _fallback,
        fontSize: 16,
        fontWeight: FontWeight.w500,
        height: 1.55,
        color: muted,
      );

  static TextStyle get heroKicker => const TextStyle(
        fontFamily: 'Termina',
        fontFamilyFallback: _fallback,
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
        color: ink,
      );

  static TextStyle get button => const TextStyle(
        fontFamily: 'Termina',
        fontFamilyFallback: _fallback,
        fontSize: 14,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.4,
      );

  static TextStyle get navItem => const TextStyle(
        fontFamily: 'Termina',
        fontFamilyFallback: _fallback,
        fontSize: 13,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.7,
        color: Colors.white,
      );

  static TextStyle get banner => const TextStyle(
        fontFamily: 'Termina',
        fontFamilyFallback: _fallback,
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        color: nav,
      );

  static TextStyle get italicKicker => const TextStyle(
        fontFamily: 'AntiqueOliveNord',
        fontFamilyFallback: _fallback,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        fontStyle: FontStyle.italic,
        letterSpacing: 0.4,
        color: ink,
      );

  static ButtonStyle primaryButton() {
    return ElevatedButton.styleFrom(
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
      elevation: 0,
      textStyle: button,
    );
  }

  static ButtonStyle outlineButton(Color color) {
    return OutlinedButton.styleFrom(
      foregroundColor: color,
      side: BorderSide(color: color, width: 1.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      textStyle: button,
    );
  }
}
