import 'dart:math';

class ConfirmationCodeService {
  static String generate() {
    final random = Random();
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    return List.generate(6, (_) => chars[random.nextInt(chars.length)]).join();
  }
}
