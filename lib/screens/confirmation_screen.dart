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

    return Scaffold(
      backgroundColor: AppConfig.colorFondoOscuro,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Success icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: accent.withAlpha(30),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.check, size: 40, color: accent),
                ),
                const SizedBox(height: 20),
                Text(
                  'Turno Reservado!',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: primary),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Tu turno fue registrado correctamente',
                  style: TextStyle(fontSize: 14, color: AppConfig.colorTextoSecundario),
                ),
                const SizedBox(height: 24),
                // Details card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppConfig.colorFondoCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: primary.withAlpha(40)),
                  ),
                  child: Column(
                    children: [
                      _detailRow(Icons.spa, 'Servicio', appointment.servicioNombre ?? ''),
                      if (appointment.professionalNombre != null)
                        _detailRow(Icons.person, 'Profesional', appointment.professionalNombre!),
                      _detailRow(Icons.calendar_today, 'Fecha', _formatDate(appointment.fecha)),
                      _detailRow(Icons.access_time, 'Hora', appointment.hora),
                      const Divider(height: 24, color: Colors.white12),
                      // Confirmation code
                      Text('Codigo de confirmacion', style: TextStyle(fontSize: 12, color: AppConfig.colorTextoSecundario)),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: appointment.codigoConfirmacion));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: const Text('Codigo copiado!'), backgroundColor: primary),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(
                            color: accent.withAlpha(20),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: accent.withAlpha(60)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                appointment.codigoConfirmacion,
                                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: accent, letterSpacing: 4),
                              ),
                              const SizedBox(width: 8),
                              Icon(Icons.copy, size: 18, color: accent.withAlpha(150)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Guarda este codigo para confirmar tu turno',
                        style: TextStyle(fontSize: 12, color: primary.withAlpha(150)),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // Actions
                if (tenant?.whatsappNumero.isNotEmpty == true)
                  ElevatedButton.icon(
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
                    icon: const Icon(Icons.chat),
                    label: const Text('Confirmar por WhatsApp'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF25D366),
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: primary,
                    side: BorderSide(color: primary),
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  child: const Text('Volver al inicio'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppConfig.colorTextoSecundario),
          const SizedBox(width: 10),
          Text('$label: ', style: const TextStyle(fontSize: 13, color: AppConfig.colorTextoSecundario)),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13, color: AppConfig.colorTexto, fontWeight: FontWeight.w500))),
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
