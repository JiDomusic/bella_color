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
    String message = '*${salonName.toUpperCase()}*\n\n'
        'Hola $nombreCliente! Tu turno esta confirmado!\n\n'
        '*DETALLES DE TU TURNO:*\n'
        'Servicio: $servicio\n'
        'Profesional: $profesional\n'
        'Fecha: $fecha\n'
        'Hora: $hora\n'
        'Codigo: *$codigo*';

    if (montoSena != null && montoSena > 0) {
      message += '\n\n*SE\u00D1A REQUERIDA:*\n'
          'Monto: ${formatPrecioConSigno(montoSena)}';
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
      message += '\n\n*UBICACION:*\n$direccion';
    }

    message += '\n\n*IMPORTANTE:*\n'
        'Llega 10 minutos antes de tu horario\n'
        'Presenta tu codigo de confirmacion\n'
        'Si no podes asistir, cancela con anticipacion\n\n'
        '_Mensaje automatico de ${salonName}_';

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
    return '*RECORDATORIO DE TURNO*\n\n'
        'Hola $nombreCliente!\n\n'
        'Tu turno en *$salonName* es *MA\u00D1ANA*:\n\n'
        'Servicio: $servicio\n'
        'Profesional: $profesional\n'
        'Fecha: $fecha\n'
        'Hora: $hora\n'
        'C\u00F3digo: *$codigo*\n\n'
        '*RECORDA:*\n'
        'Llegar 10 minutos antes\n'
        'Traer tu c\u00F3digo de confirmaci\u00F3n\n'
        'Si necesit\u00E1s cancelar, avisanos con tiempo\n\n'
        'Te esperamos!\n\n'
        '_${salonName}_';
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
    return '*TURNO CANCELADO*\n\n'
        'Hola $nombreCliente,\n\n'
        'Tu turno ha sido cancelado:\n\n'
        'C\u00F3digo: *$codigo*\n'
        'Servicio: $servicio\n'
        'Era para: $fecha a las $hora\n\n'
        'Queres agendar un nuevo turno?\n\n'
        'Esperamos verte pronto!\n\n'
        '_${salonName}_';
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
    return '*${salonName.toUpperCase()}*\n\n'
        'Hola $nombreCliente! Recibimos tu solicitud de turno\n\n'
        '*DETALLES:*\n'
        'Servicio: $servicio\n'
        'Profesional: $profesional\n'
        'Fecha: $fecha\n'
        'Hora: $hora\n\n'
        '*CONFIRMA TU TURNO:*\n'
        'Usa tu codigo: *$codigo*\n\n'
        'Si no confirmas dentro de $confirmationWindowHours horas, el turno se cancelara automaticamente.\n\n'
        '_${salonName}_';
  }

  /// Mensaje de lista de espera
  static String buildWaitlistNotificationMessage({
    required String nombreCliente,
    required String servicio,
    required String fecha,
    required String hora,
    required String salonName,
  }) {
    return '*BUENAS NOTICIAS!*\n\n'
        'Hola $nombreCliente!\n\n'
        'Se libero un lugar en *$salonName* para:\n\n'
        'Servicio: $servicio\n'
        'Fecha: $fecha\n'
        'Hora: $hora\n\n'
        'Queres que te reservemos? Respondenos rapido para asegurar tu lugar!\n\n'
        '_${salonName}_';
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
