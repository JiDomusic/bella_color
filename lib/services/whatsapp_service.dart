import 'package:url_launcher/url_launcher.dart';

class WhatsappService {
  static Future<void> openChat({
    required String phone,
    String countryCode = '54',
    String message = '',
  }) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d]'), '');
    final fullPhone = cleanPhone.startsWith(countryCode) ? cleanPhone : '$countryCode$cleanPhone';
    final encoded = Uri.encodeComponent(message);
    final url = Uri.parse('https://wa.me/$fullPhone?text=$encoded');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  static Future<void> openSupport() async {
    await openChat(
      phone: '3413363551',
      countryCode: '54',
      message: 'Hola, necesito ayuda con Bella Color',
    );
  }

  static Future<void> sendConfirmation({
    required String phone,
    required String countryCode,
    required String nombreCliente,
    required String servicio,
    required String fecha,
    required String hora,
    required String codigo,
    required String salonName,
  }) async {
    final msg = 'Hola $nombreCliente! Tu turno en $salonName:\n'
        'Servicio: $servicio\n'
        'Fecha: $fecha\n'
        'Hora: $hora\n'
        'Codigo: $codigo\n\n'
        'Por favor confirma tu turno respondiendo SI.';
    await openChat(phone: phone, countryCode: countryCode, message: msg);
  }
}
