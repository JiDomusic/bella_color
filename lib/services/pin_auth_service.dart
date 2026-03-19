import 'package:supabase_flutter/supabase_flutter.dart';

class PinAuthService {
  static final PinAuthService _instance = PinAuthService._();
  static PinAuthService get instance => _instance;
  PinAuthService._();

  int _failedAttempts = 0;
  DateTime? _lockedUntil;

  static const int maxAttempts = 3;
  static const int lockoutMinutes = 5;

  bool get isLocked {
    if (_lockedUntil == null) return false;
    if (DateTime.now().isAfter(_lockedUntil!)) {
      _lockedUntil = null;
      _failedAttempts = 0;
      return false;
    }
    return true;
  }

  int get remainingLockSeconds {
    if (_lockedUntil == null) return 0;
    return _lockedUntil!.difference(DateTime.now()).inSeconds;
  }

  int get remainingAttempts => maxAttempts - _failedAttempts;

  /// Verifica PIN server-side via verify_super_admin_pin (SECURITY DEFINER).
  /// El PIN real esta en la tabla app_secrets, no en el codigo.
  Future<bool> verifyAsync(String pin) async {
    if (isLocked) return false;

    try {
      final result = await Supabase.instance.client
          .rpc('verify_super_admin_pin', params: {'p_pin': pin});
      if (result == true) {
        _failedAttempts = 0;
        _lockedUntil = null;
        return true;
      }
    } catch (_) {
      // Si la funcion no existe, no conceder acceso
    }

    _failedAttempts++;
    if (_failedAttempts >= maxAttempts) {
      _lockedUntil = DateTime.now().add(const Duration(minutes: lockoutMinutes));
    }
    return false;
  }

  /// Verificacion sincrona (fallback, NO recomendado).
  bool verify(String pin) {
    if (isLocked) return false;

    // Ya no verificamos client-side. Usar verifyAsync.
    _failedAttempts++;
    if (_failedAttempts >= maxAttempts) {
      _lockedUntil = DateTime.now().add(const Duration(minutes: lockoutMinutes));
    }
    return false;
  }
}
