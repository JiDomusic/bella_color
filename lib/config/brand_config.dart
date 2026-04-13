import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

/// Detecta la marca (salon de belleza o barberia) segun el dominio/URL.
/// No modifica nada de Bella Color: solo agrega una capa de deteccion.
enum BrandType { salon, barberia }

class BrandConfig {
  static BrandConfig? _instance;
  static BrandConfig get instance => _instance ??= BrandConfig._detect();

  final BrandType type;
  final String nombre;
  final String subtituloGenerico;
  final String publicBaseUrl;
  final IconData iconoGenerico;
  final String whatsappMensajeDemo;

  // Colores default del splash/demo (cuando no hay tenant configurado)
  final Color colorSplashPrimario;
  final Color colorSplashGlow;
  final List<Color> gradienteSplash;
  final Color colorHelperBannerStart;
  final Color colorHelperBannerEnd;

  BrandConfig._({
    required this.type,
    required this.nombre,
    required this.subtituloGenerico,
    required this.publicBaseUrl,
    required this.iconoGenerico,
    required this.whatsappMensajeDemo,
    required this.colorSplashPrimario,
    required this.colorSplashGlow,
    required this.gradienteSplash,
    required this.colorHelperBannerStart,
    required this.colorHelperBannerEnd,
  });

  bool get esBarberia => type == BrandType.barberia;
  bool get esSalon => type == BrandType.salon;

  /// Detecta la marca desde la URL del navegador.
  factory BrandConfig._detect() {
    var esBarberia = false;

    if (kIsWeb) {
      try {
        final host = Uri.base.host.toLowerCase();
        // Si el dominio contiene "juke-box" o "barber", es barberia
        if (host.contains('juke-box') || host.contains('barber')) {
          esBarberia = true;
        }
      } catch (_) {}
    }

    // Tambien se puede forzar por variable de entorno en el build
    const envBrand = String.fromEnvironment('BRAND', defaultValue: '');
    if (envBrand == 'barberia') esBarberia = true;

    if (esBarberia) {
      return BrandConfig._(
        type: BrandType.barberia,
        nombre: 'JUKE-BOX RESERVA',
        subtituloGenerico: 'Sistema de turnos para barberias',
        publicBaseUrl: 'https://juke-box-reserva.web.app',
        iconoGenerico: Icons.content_cut,
        whatsappMensajeDemo: 'Hola! Quiero probar Juke-Box Reserva gratis por 15 dias para mi barberia.',
        // Estetica Breaking Bad / Western / Tarantino
        colorSplashPrimario: const Color(0xFF4CAF50),    // Verde quimico
        colorSplashGlow: const Color(0xFF2E7D32),        // Verde oscuro
        gradienteSplash: const [
          Color(0xFF0D0D0D),  // Negro puro
          Color(0xFF1A1A0A),  // Negro con tinte verde
          Color(0xFF0D0D0D),  // Negro puro
        ],
        colorHelperBannerStart: const Color(0xFF1B2A1B),
        colorHelperBannerEnd: const Color(0xFF4CAF50),
      );
    }

    return BrandConfig._(
      type: BrandType.salon,
      nombre: 'BELLA COLOR',
      subtituloGenerico: 'Sistema de turnos para salones de belleza',
      publicBaseUrl: 'https://bella-color.web.app',
      iconoGenerico: Icons.spa,
      whatsappMensajeDemo: 'Hola! Quiero probar Bella Color gratis por 15 dias. Me pasan el link?',
      // Estetica actual de Bella Color (rosa/dorado)
      colorSplashPrimario: const Color(0xFFD4A0A0),
      colorSplashGlow: const Color(0xFFD4A0A0),
      gradienteSplash: const [
        Color(0xFF1A0A14),
        Color(0xFF0E0610),
        Color(0xFF140A10),
      ],
      colorHelperBannerStart: const Color(0xFF2A1520),
      colorHelperBannerEnd: const Color(0xFFF5A0B8),
    );
  }

  /// Reiniciar singleton (para tests)
  static void reset() => _instance = null;
}
