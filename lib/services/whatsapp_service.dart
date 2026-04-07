import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/price_format.dart';

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
    String? plantillaPersonalizada,
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
      plantillaPersonalizada: plantillaPersonalizada,
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
  /// Si se pasa plantillaPersonalizada, usa esa plantilla reemplazando variables:
  /// {nombre}, {servicio}, {profesional}, {fecha}, {hora}, {codigo}, {salon}, {direccion}
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
    String? plantillaPersonalizada,
  }) {
    // Si hay plantilla personalizada, usarla
    if (plantillaPersonalizada != null && plantillaPersonalizada.trim().isNotEmpty) {
      String message = plantillaPersonalizada
          .replaceAll('{nombre}', nombreCliente)
          .replaceAll('{servicio}', servicio)
          .replaceAll('{profesional}', profesional)
          .replaceAll('{fecha}', fecha)
          .replaceAll('{hora}', hora)
          .replaceAll('{codigo}', codigo)
          .replaceAll('{salon}', salonName)
          .replaceAll('{direccion}', direccion ?? '');

      // Agregar seña si corresponde
      if (montoSena != null && montoSena > 0) {
        message += '\n\n💰 *SEÑA REQUERIDA:*\nMonto: ${formatPrecioConSigno(montoSena)}';
        if (senaCbu != null && senaCbu.isNotEmpty) message += '\nCBU: $senaCbu';
        if (senaAlias != null && senaAlias.isNotEmpty) message += '\nAlias: $senaAlias';
        if (senaTitular != null && senaTitular.isNotEmpty) message += '\nTitular: $senaTitular';
        message += '\n\nEnvia el comprobante de transferencia en este chat para confirmar tu turno.';
      }

      return message;
    }

    // Plantilla por defecto
    String message = '''✨ *${salonName.toUpperCase()}* ✨

Hola $nombreCliente! 🎉 Tu turno esta confirmado!

💇 *DETALLES DE TU TURNO:*
💈 Servicio: $servicio
👩‍🎨 Profesional: $profesional
📅 Fecha: $fecha
🕐 Hora: $hora
🔑 Codigo: *$codigo*''';

    if (montoSena != null && montoSena > 0) {
      message += '''

💰 *SEÑA REQUERIDA:*
Monto: ${formatPrecioConSigno(montoSena)}''';
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
• 🕐 Llega 10 minutos antes de tu horario
• 🔑 Presentá tu código de confirmación
• ❌ Si no podés asistir, cancelá con anticipación

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
    return '''\u23F0 *RECORDATORIO DE TURNO*

Hola $nombreCliente! \uD83D\uDC4B

Tu turno en *$salonName* es *MA\u00D1ANA*:

\uD83D\uDC88 Servicio: $servicio
\uD83D\uDC69\u200D\uD83C\uDFA8 Profesional: $profesional
\uD83D\uDCC5 Fecha: $fecha
\uD83D\uDD50 Hora: $hora
\uD83D\uDD11 C\u00F3digo: *$codigo*

*RECORD\u00C1:*
\u2022 \u23F0 Llegar 10 minutos antes
\u2022 \uD83D\uDD11 Traer tu c\u00F3digo de confirmaci\u00F3n
\u2022 \u274C Si necesit\u00E1s cancelar, avisanos con tiempo

Te esperamos! \u2728

\uD83C\uDDE6\uD83C\uDDF7 _${salonName}_''';
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
    return '''\u274C *TURNO CANCELADO*

Hola $nombreCliente,

Tu turno ha sido cancelado:

\uD83D\uDD11 C\u00F3digo: *$codigo*
\uD83D\uDC88 Servicio: $servicio
\uD83D\uDCC5 Era para: $fecha a las $hora

\u00BFQuer\u00E9s agendar un nuevo turno? \uD83D\uDC87

\u00A1Esperamos verte pronto! \u2728

\uD83C\uDDE6\uD83C\uDDF7 _${salonName}_''';
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
    return '''\u2728 *${salonName.toUpperCase()}* \u2728

Hola $nombreCliente! Recibimos tu solicitud de turno \uD83D\uDCCB

\uD83D\uDC87 *DETALLES:*
\uD83D\uDC88 Servicio: $servicio
\uD83D\uDC69\u200D\uD83C\uDFA8 Profesional: $profesional
\uD83D\uDCC5 Fecha: $fecha
\uD83D\uDD50 Hora: $hora

\uD83D\uDD11 *CONFIRM\u00C1 TU TURNO:*
Us\u00E1 tu c\u00F3digo: *$codigo*

\u26A0\uFE0F Si no confirm\u00E1s dentro de $confirmationWindowHours horas, el turno se cancelar\u00E1 autom\u00E1ticamente.

\uD83C\uDDE6\uD83C\uDDF7 _${salonName}_''';
  }

  /// Mensaje de lista de espera
  static String buildWaitlistNotificationMessage({
    required String nombreCliente,
    required String servicio,
    required String fecha,
    required String hora,
    required String salonName,
  }) {
    return '''\uD83C\uDF89 *\u00A1BUENAS NOTICIAS!*

Hola $nombreCliente! \uD83D\uDC4B

Se liber\u00F3 un lugar en *$salonName* para:

\uD83D\uDC88 Servicio: $servicio
\uD83D\uDCC5 Fecha: $fecha
\uD83D\uDD50 Hora: $hora

\u00BFQuer\u00E9s que te reservemos? \u00A1Respondenos r\u00E1pido para asegurar tu lugar! \uD83C\uDFC3\u200D\u2640\uFE0F

\uD83C\uDDE6\uD83C\uDDF7 _${salonName}_''';
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
