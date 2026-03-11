import 'dart:math';
import 'supabase_service.dart';

class ConfirmationCodeService {
  static const String _chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  static const int _codeLength = 6;
  static final Random _random = Random();
  static final Set<String> _recentCodes = {};

  /// Genera un código único de 6 caracteres
  static Future<String> generateUniqueCode() async {
    String code;
    bool isUnique = false;
    int attempts = 0;
    const maxAttempts = 50;

    do {
      code = generate();
      attempts++;

      if (attempts > maxAttempts) {
        throw Exception('No se pudo generar un codigo unico despues de $maxAttempts intentos');
      }

      if (_recentCodes.contains(code)) continue;

      // Verificar contra la base de datos
      final existing = await SupabaseService.instance.findAppointmentByCode(code);
      isUnique = existing == null;
    } while (!isUnique);

    _recentCodes.add(code);
    if (_recentCodes.length > 1000) _recentCodes.clear();

    return code;
  }

  /// Genera un código aleatorio simple
  static String generate() {
    return String.fromCharCodes(
      Iterable.generate(
        _codeLength,
        (_) => _chars.codeUnitAt(_random.nextInt(_chars.length)),
      ),
    );
  }

  /// Valida formato del código
  static bool isValidCodeFormat(String code) {
    if (code.length != _codeLength) return false;
    for (int i = 0; i < code.length; i++) {
      if (!_chars.contains(code[i])) return false;
    }
    return true;
  }

  /// Busca turno por código
  static Future<Map<String, dynamic>?> findAppointmentByCode(String code) async {
    if (!isValidCodeFormat(code.toUpperCase())) return null;
    final appointment = await SupabaseService.instance.findAppointmentByCode(code.toUpperCase());
    return appointment?.toJson();
  }

  static void markCodeAsUsed(String code) {
    _recentCodes.add(code.toUpperCase());
  }

  static void clearCache() {
    _recentCodes.clear();
  }
}
