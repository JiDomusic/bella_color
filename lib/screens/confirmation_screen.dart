import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../config/app_config.dart';
import '../models/appointment.dart';
import '../services/supabase_service.dart';
import '../services/whatsapp_service.dart';
import '../utils/price_format.dart';
import '../widgets/page_background.dart';

class ConfirmationScreen extends StatelessWidget {
  final Appointment appointment;
  final double? precioServicio;
  final bool requiereSena;
  final String? comprobanteUrl;

  const ConfirmationScreen({
    super.key,
    required this.appointment,
    this.precioServicio,
    this.requiereSena = false,
    this.comprobanteUrl,
  });

  @override
  Widget build(BuildContext context) {
    final tenant = SupabaseService.instance.currentTenant;
    final primary = tenant != null ? AppConfig.hexToColor(tenant.colorPrimario) : AppConfig.colorPrimario;
    final accent = tenant != null ? AppConfig.hexToColor(tenant.colorAcento) : AppConfig.colorAcento;
    final salonName = tenant?.nombreSalon ?? 'Salon';

    // Calcular seña
    final precio = precioServicio ?? 0;
    final mostrarSena = tenant != null &&
        tenant.senaHabilitada &&
        requiereSena &&
        precio > 0 &&
        tenant.senaPorcentaje > 0;
    final montoSena = mostrarSena ? precio * tenant!.senaPorcentaje / 100 : 0.0;
    final esPagoTotal = tenant?.senaPorcentaje == 100;

    return Scaffold(
      backgroundColor: Colors.transparent,
      resizeToAvoidBottomInset: false,
      body: PageBackground(child: SafeArea(
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

                  // Seña card
                  if (mostrarSena) ...[
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFFF9800).withAlpha(60)),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 12, offset: const Offset(0, 2)),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF9800).withAlpha(25),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.account_balance_outlined, size: 18, color: Color(0xFFFF9800)),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                esPagoTotal ? 'Pago anticipado requerido' : 'Seña requerida',
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFFE65100)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF9800).withAlpha(15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  formatPrecioConSigno(montoSena),
                                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Color(0xFFE65100)),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  esPagoTotal
                                      ? '100% del servicio'
                                      : '${tenant.senaPorcentaje}% del servicio (${formatPrecioConSigno(precio)})',
                                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (tenant.senaCbu.isNotEmpty)
                            _copiableRow(context, 'CBU', tenant.senaCbu, primary),
                          if (tenant.senaAlias.isNotEmpty)
                            _copiableRow(context, 'Alias', tenant.senaAlias, primary),
                          if (tenant.senaTitular.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: [
                                  Text('Titular: ', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.grey[600])),
                                  Expanded(child: Text(tenant.senaTitular, style: TextStyle(fontSize: 13, color: Colors.grey[800]))),
                                ],
                              ),
                            ),
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: comprobanteUrl != null ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  comprobanteUrl != null ? Icons.check_circle : Icons.info_outline,
                                  size: 16,
                                  color: comprobanteUrl != null ? const Color(0xFF4CAF50) : Colors.orange[700],
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    comprobanteUrl != null
                                        ? 'Comprobante enviado. Confirma tu turno por WhatsApp.'
                                        : 'Envia el comprobante por WhatsApp para confirmar tu turno',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: comprobanteUrl != null ? const Color(0xFF2E7D32) : Colors.orange[800],
                                      height: 1.3,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

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
                      onPressed: () => _sendToMyWhatsApp(tenant, primary, mostrarSena ? montoSena : null),
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

                  // WhatsApp: enviar al salón (con seña si aplica)
                  if (tenant?.whatsappNumero.isNotEmpty == true) ...[
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: mostrarSena
                          ? ElevatedButton.icon(
                              onPressed: () => _sendToSalon(tenant, mostrarSena ? montoSena : null),
                              icon: Icon(comprobanteUrl != null ? Icons.chat_rounded : Icons.account_balance_outlined, size: 20),
                              label: Text(
                                comprobanteUrl != null ? 'Confirmar turno por WhatsApp' : 'Enviar comprobante al salon',
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: comprobanteUrl != null ? const Color(0xFF25D366) : const Color(0xFFFF9800),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                            )
                          : OutlinedButton.icon(
                              onPressed: () => _sendToSalon(tenant!, null),
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
      )),
    );
  }

  void _sendToSalon(dynamic tenant, double? montoSena) {
    WhatsappService.sendConfirmation(
      phone: tenant.whatsappNumero,
      countryCode: tenant.codigoPaisTelefono,
      nombreCliente: appointment.nombreCliente,
      servicio: appointment.servicioNombre ?? '',
      profesional: appointment.professionalNombre ?? '',
      fecha: _formatDate(appointment.fecha),
      hora: appointment.hora,
      codigo: appointment.codigoConfirmacion,
      salonName: tenant.nombreSalon,
      direccion: tenant.direccion,
      montoSena: montoSena,
      senaCbu: tenant.senaCbu,
      senaAlias: tenant.senaAlias,
      senaTitular: tenant.senaTitular,
      plantillaPersonalizada: tenant.mensajeWhatsappConfirmacion,
    );
  }

  void _sendToMyWhatsApp(dynamic tenant, Color primary, double? montoSena) {
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
      montoSena: montoSena,
      senaCbu: tenant?.senaCbu,
      senaAlias: tenant?.senaAlias,
      senaTitular: tenant?.senaTitular,
      plantillaPersonalizada: tenant?.mensajeWhatsappConfirmacion,
    );

    WhatsappService.openChat(
      phone: appointment.telefono,
      countryCode: countryCode,
      message: message,
    );
  }

  Widget _copiableRow(BuildContext context, String label, String value, Color primary) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text('$label: ', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.grey[600])),
          Expanded(
            child: Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey[800])),
          ),
          GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: value));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$label copiado!'),
                  backgroundColor: primary,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              );
            },
            child: Icon(Icons.copy_rounded, size: 16, color: Colors.grey[400]),
          ),
        ],
      ),
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
