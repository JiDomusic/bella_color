import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../config/app_config.dart';
import '../models/appointment.dart';
import '../services/supabase_service.dart';
import '../services/whatsapp_service.dart';

class ConfirmationScreen extends StatelessWidget {
  final Appointment appointment;

  const ConfirmationScreen({super.key, required this.appointment});

  @override
  Widget build(BuildContext context) {
    final tenant = SupabaseService.instance.currentTenant;
    final primary = tenant != null ? AppConfig.hexToColor(tenant.colorPrimario) : AppConfig.colorPrimario;
    final accent = tenant != null ? AppConfig.hexToColor(tenant.colorAcento) : AppConfig.colorAcento;
    final salonName = tenant?.nombreSalon ?? 'Salon';

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 20),
                  // Success animation
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [primary.withAlpha(40), accent.withAlpha(30)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.check_rounded, size: 48, color: primary),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Listo, reservamos tu turno!',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.grey[800]),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    salonName,
                    style: TextStyle(fontSize: 14, color: primary, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 24),

                  // Details card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withAlpha(12), blurRadius: 16, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Column(
                      children: [
                        _detailRow(Icons.spa_outlined, appointment.servicioNombre ?? '', primary),
                        if (appointment.professionalNombre != null)
                          _detailRow(Icons.person_outline, appointment.professionalNombre!, primary),
                        _detailRow(Icons.calendar_today_outlined, _formatDate(appointment.fecha), primary),
                        _detailRow(Icons.schedule_outlined, appointment.hora, primary),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Confirmation code card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: accent.withAlpha(40)),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 12, offset: const Offset(0, 2)),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Tu código de confirmación',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey[500]),
                        ),
                        const SizedBox(height: 10),
                        GestureDetector(
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: appointment.codigoConfirmacion));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Código copiado!'),
                                backgroundColor: primary,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                            decoration: BoxDecoration(
                              color: accent.withAlpha(15),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  appointment.codigoConfirmacion,
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w800,
                                    color: accent,
                                    letterSpacing: 5,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Icon(Icons.copy_rounded, size: 18, color: accent.withAlpha(120)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tocá para copiar',
                          style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // WhatsApp: enviarse a sí mismo
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: () => _sendToMyWhatsApp(tenant, primary),
                      icon: const Icon(Icons.chat_rounded, size: 20),
                      label: const Text('Guardar en mi WhatsApp', style: TextStyle(fontWeight: FontWeight.w600)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF25D366),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),

                  // WhatsApp: enviar al salón
                  if (tenant?.whatsappNumero.isNotEmpty == true) ...[
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton.icon(
                        onPressed: () => WhatsappService.sendConfirmation(
                          phone: tenant!.whatsappNumero,
                          countryCode: tenant.codigoPaisTelefono,
                          nombreCliente: appointment.nombreCliente,
                          servicio: appointment.servicioNombre ?? '',
                          profesional: appointment.professionalNombre ?? '',
                          fecha: _formatDate(appointment.fecha),
                          hora: appointment.hora,
                          codigo: appointment.codigoConfirmacion,
                          salonName: tenant.nombreSalon,
                          direccion: tenant.direccion,
                        ),
                        icon: Icon(Icons.storefront_outlined, size: 20, color: Colors.grey[600]),
                        label: Text('Confirmar con el salón', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey[700])),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.grey[300]!),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: TextButton(
                      onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
                      style: TextButton.styleFrom(
                        foregroundColor: primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('Volver al inicio', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _sendToMyWhatsApp(dynamic tenant, Color primary) {
    final salonName = tenant?.nombreSalon ?? 'Salon';
    final direccion = tenant?.direccion ?? '';
    final countryCode = tenant?.codigoPaisTelefono ?? '54';

    final message = WhatsappService.buildConfirmationMessage(
      nombreCliente: appointment.nombreCliente,
      servicio: appointment.servicioNombre ?? '',
      profesional: appointment.professionalNombre ?? '',
      fecha: _formatDate(appointment.fecha),
      hora: appointment.hora,
      codigo: appointment.codigoConfirmacion,
      salonName: salonName,
      direccion: direccion,
    );

    WhatsappService.openChat(
      phone: appointment.telefono,
      countryCode: countryCode,
      message: message,
    );
  }

  Widget _detailRow(IconData icon, String value, Color primary) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: primary.withAlpha(15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.grey[800]),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String fecha) {
    try {
      final parts = fecha.split('-');
      return '${parts[2]}/${parts[1]}/${parts[0]}';
    } catch (_) {
      return fecha;
    }
  }
}
