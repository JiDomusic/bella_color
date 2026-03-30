import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class WhatsappService {
  static Future<bool> _openUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        return await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
    } catch (_) {
      return false;
    }
  }

  static String _generateWhatsAppUrl(String phoneNumber, String message, {String countryCode = '54'}) {
    String cleanPhone = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
    if (!cleanPhone.startsWith(countryCode)) {
      if (cleanPhone.startsWith('0')) {
        cleanPhone = '$countryCode${cleanPhone.substring(1)}';
      } else if (cleanPhone.startsWith('15')) {
        cleanPhone = '${countryCode}9${cleanPhone.substring(2)}';
      } else {
        cleanPhone = '${countryCode}9$cleanPhone';
      }
    }
    final encodedMessage = Uri.encodeComponent(message);
    return 'https://wa.me/$cleanPhone?text=$encodedMessage';
  }

  /// Abrir chat genérico
  static Future<void> openChat({
    required String phone,
    String countryCode = '54',
    String message = '',
  }) async {
    final url = _generateWhatsAppUrl(phone, message, countryCode: countryCode);
    await _openUrl(url);
  }

  /// Soporte técnico
  static Future<void> openSupport() async {
    await openChat(
      phone: '3413363551',
      countryCode: '54',
      message: 'Hola, necesito ayuda con Bella Color',
    );
  }

  /// Enviar confirmación de turno por WhatsApp
  static Future<void> sendConfirmation({
    required String phone,
    required String countryCode,
    required String nombreCliente,
    required String servicio,
    required String profesional,
    required String fecha,
    required String hora,
    required String codigo,
    required String salonName,
    String? direccion,
    double? montoSena,
    String? senaCbu,
    String? senaAlias,
    String? senaTitular,
  }) async {
    final message = buildConfirmationMessage(
      nombreCliente: nombreCliente,
      servicio: servicio,
      profesional: profesional,
      fecha: fecha,
      hora: hora,
      codigo: codigo,
      salonName: salonName,
      direccion: direccion,
      montoSena: montoSena,
      senaCbu: senaCbu,
      senaAlias: senaAlias,
      senaTitular: senaTitular,
    );
    final url = _generateWhatsAppUrl(phone, message, countryCode: countryCode);
    await _openUrl(url);
  }

  /// Copiar mensaje de confirmación al portapapeles
  static Future<void> copyConfirmationToClipboard({
    required String nombreCliente,
    required String servicio,
    required String profesional,
    required String fecha,
    required String hora,
    required String codigo,
    required String salonName,
    String? direccion,
  }) async {
    final message = buildConfirmationMessage(
      nombreCliente: nombreCliente,
      servicio: servicio,
      profesional: profesional,
      fecha: fecha,
      hora: hora,
      codigo: codigo,
      salonName: salonName,
      direccion: direccion,
    );
    await Clipboard.setData(ClipboardData(text: message));
  }

  /// Construir mensaje de confirmación de turno
  static String buildConfirmationMessage({
    required String nombreCliente,
    required String servicio,
    required String profesional,
    required String fecha,
    required String hora,
    required String codigo,
    required String salonName,
    String? direccion,
    double? montoSena,
    String? senaCbu,
    String? senaAlias,
    String? senaTitular,
  }) {
    String message = '''✨ *${salonName.toUpperCase()}* ✨

Hola $nombreCliente! 🎉 Tu turno esta confirmado!

💇 *DETALLES DE TU TURNO:*
🪞 Servicio: $servicio
👩‍🎨 Profesional: $profesional
📅 Fecha: $fecha
🕐 Hora: $hora
🔑 Codigo: *$codigo*''';

    if (montoSena != null && montoSena > 0) {
      message += '''

💰 *SEÑA REQUERIDA:*
Monto: \$${montoSena.toStringAsFixed(2)}''';
      if (senaCbu != null && senaCbu.isNotEmpty) {
        message += '\nCBU: $senaCbu';
      }
      if (senaAlias != null && senaAlias.isNotEmpty) {
        message += '\nAlias: $senaAlias';
      }
      if (senaTitular != null && senaTitular.isNotEmpty) {
        message += '\nTitular: $senaTitular';
      }
      message += '\n\nEnvia el comprobante de transferencia en este chat para confirmar tu turno.';
    }

    if (direccion != null && direccion.isNotEmpty) {
      message += '''

📍 *UBICACION:*
$direccion''';
    }

    message += '''

⚡ *IMPORTANTE:*
- ⏰ Llega 10 minutos antes de tu horario
- 🔑 Presenta tu codigo de confirmacion
- ❌ Si no podes asistir, cancela con anticipacion

🇦🇷 _Hecho con amor en Argentina_ 💜
_Mensaje automatico de ${salonName}_''';

    return message;
  }

  /// Mensaje de recordatorio (24h antes)
  static String buildReminderMessage({
    required String nombreCliente,
    required String servicio,
    required String profesional,
    required String fecha,
    required String hora,
    required String codigo,
    required String salonName,
  }) {
    return '''*RECORDATORIO DE TURNO*

Hola $nombreCliente!

Tu turno en $salonName es *MANANA*:

Servicio: $servicio
Profesional: $profesional
Fecha: $fecha
Hora: $hora
Codigo: *$codigo*

*RECORDA:*
- Llegar 10 minutos antes
- Traer tu codigo de confirmacion
- Si necesitas cancelar, avisanos con tiempo

Te esperamos!

_${salonName}_''';
  }

  /// Mensaje de cancelación
  static String buildCancellationMessage({
    required String nombreCliente,
    required String servicio,
    required String fecha,
    required String hora,
    required String codigo,
    required String salonName,
  }) {
    return '''*TURNO CANCELADO*

Hola $nombreCliente,

Tu turno ha sido cancelado:

Codigo: *$codigo*
Servicio: $servicio
Era para: $fecha a las $hora

Queres agendar un nuevo turno?

Esperamos verte pronto!

_${salonName}_''';
  }

  /// Mensaje pidiendo confirmación al cliente
  static String buildConfirmationRequestMessage({
    required String nombreCliente,
    required String servicio,
    required String profesional,
    required String fecha,
    required String hora,
    required String codigo,
    required String salonName,
    int confirmationWindowHours = 2,
  }) {
    return '''*${salonName.toUpperCase()}*

Hola $nombreCliente! Recibimos tu solicitud de turno

*DETALLES:*
Servicio: $servicio
Profesional: $profesional
Fecha: $fecha
Hora: $hora

*CONFIRMA TU TURNO:*
Usa tu codigo: *$codigo*

Si no confirmas dentro de $confirmationWindowHours horas, el turno se cancelara automaticamente.

_${salonName}_''';
  }

  /// Mensaje de lista de espera
  static String buildWaitlistNotificationMessage({
    required String nombreCliente,
    required String servicio,
    required String fecha,
    required String hora,
    required String salonName,
  }) {
    return '''*BUENAS NOTICIAS!*

Hola $nombreCliente!

Se libero un lugar en $salonName para:

Servicio: $servicio
Fecha: $fecha
Hora: $hora

Queres que te reservemos? Respondenos rapido para asegurar tu lugar!

_${salonName}_''';
  }

  /// Enviar mensaje genérico
  static Future<void> sendMessage({
    required String phoneNumber,
    required String message,
    String countryCode = '54',
  }) async {
    final url = _generateWhatsAppUrl(phoneNumber, message, countryCode: countryCode);
    final success = await _openUrl(url);
    if (!success) {
      throw Exception('No se pudo abrir WhatsApp');
    }
  }

  /// Validar formato de teléfono
  static bool isValidPhone(String phone) {
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d]'), '');
    return cleanPhone.length >= 8 && cleanPhone.length <= 15;
  }

  /// Formatear teléfono para mostrar
  static String formatPhoneForDisplay(String phone) {
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d]'), '');
    if (cleanPhone.length == 10) {
      return '${cleanPhone.substring(0, 3)}-${cleanPhone.substring(3, 6)}-${cleanPhone.substring(6)}';
    } else if (cleanPhone.length == 11) {
      return '${cleanPhone.substring(0, 2)}-${cleanPhone.substring(2, 6)}-${cleanPhone.substring(6)}';
    }
    return phone;
  }
}
