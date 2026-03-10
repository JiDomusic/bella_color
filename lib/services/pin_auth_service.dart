import '../config/app_config.dart';

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

  bool verify(String pin) {
    if (isLocked) return false;

    if (pin == AppConfig.superAdminPin) {
      _failedAttempts = 0;
      _lockedUntil = null;
      return true;
    }

    _failedAttempts++;
    if (_failedAttempts >= maxAttempts) {
      _lockedUntil = DateTime.now().add(const Duration(minutes: lockoutMinutes));
    }
    return false;
  }
}
