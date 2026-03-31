import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/app_config.dart';
import '../config/public_theme.dart';
import '../services/supabase_service.dart';
import 'home_screen.dart';

class ConfirmAppointmentScreen extends StatefulWidget {
  final String? initialCode;

  const ConfirmAppointmentScreen({super.key, this.initialCode});

  @override
  State<ConfirmAppointmentScreen> createState() => _ConfirmAppointmentScreenState();
}

class _ConfirmAppointmentScreenState extends State<ConfirmAppointmentScreen> {
  late TextEditingController _codeCtrl;
  bool _loading = false;
  String? _error;
  Map<String, dynamic>? _confirmedData;

  final _svc = SupabaseService.instance;

  Color get _primary {
    final t = _svc.currentTenant;
    return t != null ? AppConfig.hexToColor(t.colorPrimario) : AppConfig.colorPrimario;
  }

  Color get _accent {
    final t = _svc.currentTenant;
    return t != null ? AppConfig.hexToColor(t.colorAcento) : AppConfig.colorAcento;
  }

  @override
  void initState() {
    super.initState();
    _codeCtrl = TextEditingController(text: widget.initialCode ?? '');
    if (widget.initialCode != null && widget.initialCode!.isNotEmpty) {
      _confirm();
    }
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    final code = _codeCtrl.text.trim().toUpperCase();
    if (code.isEmpty) {
      setState(() => _error = 'Ingresá tu código de confirmación');
      return;
    }

    setState(() { _loading = true; _error = null; });

    try {
      final appointment = await _svc.findAppointmentByCode(code);
      if (appointment == null) {
        setState(() { _loading = false; _error = 'No se encontro un turno con ese codigo'; });
        return;
      }

      // Confirmar el turno
      if (appointment.estado == 'pendiente_confirmacion') {
        await _svc.updateAppointmentStatus(appointment.id, 'confirmada');
      }

      if (mounted) {
        setState(() {
          _loading = false;
          _confirmedData = {
            'nombre': appointment.nombreCliente,
            'servicio': appointment.servicioNombre ?? '',
            'profesional': appointment.professionalNombre ?? '',
            'fecha': appointment.fecha,
            'hora': appointment.hora,
            'codigo_confirmacion': appointment.codigoConfirmacion,
            'estado': appointment.estado == 'pendiente_confirmacion' ? 'confirmada' : appointment.estado,
          };
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() { _loading = false; _error = 'Error al buscar el turno'; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PublicTheme.cream,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Confirmar Turno', style: GoogleFonts.sora(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: _confirmedData != null ? _buildSuccess() : _buildForm(),
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.verified_user, color: _accent, size: 56),
        const SizedBox(height: 24),
        Text(
          'Ingresá tu código de confirmación',
          style: GoogleFonts.sora(color: PublicTheme.ink, fontSize: 18, fontWeight: FontWeight.w700),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Lo recibiste por WhatsApp al reservar tu turno',
          style: GoogleFonts.spaceGrotesk(color: PublicTheme.softMuted, fontSize: 13),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        TextField(
          controller: _codeCtrl,
          textCapitalization: TextCapitalization.characters,
          textAlign: TextAlign.center,
          style: GoogleFonts.sora(color: PublicTheme.ink, fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: 6),
          decoration: InputDecoration(
            hintText: 'ABC123',
            hintStyle: GoogleFonts.sora(color: Colors.grey[400], fontSize: 26, letterSpacing: 6),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: PublicTheme.stroke),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: _accent, width: 2),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(_error!, style: GoogleFonts.spaceGrotesk(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.w600)),
        ],
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _loading ? null : _confirm,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: _loading
                ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text('Confirmar', style: GoogleFonts.sora(fontSize: 17, fontWeight: FontWeight.w700)),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccess() {
    final r = _confirmedData!;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 80, height: 80,
          decoration: BoxDecoration(
            color: _accent.withAlpha(40),
            shape: BoxShape.circle,
            border: Border.all(color: _accent.withAlpha(100), width: 2),
          ),
          child: Icon(Icons.check_rounded, color: _accent, size: 48),
        ),
        const SizedBox(height: 24),
        Text(
          r['estado'] == 'confirmada' ? 'Turno Confirmado!' : 'Detalles del Turno',
          style: GoogleFonts.sora(color: PublicTheme.ink, fontSize: 24, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: PublicTheme.stroke),
            boxShadow: [
              BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 12, offset: const Offset(0, 4)),
            ],
          ),
          child: Column(
            children: [
              _infoRow(Icons.person, '${r['nombre']}'),
              _infoRow(Icons.spa, '${r['servicio']}'),
              if ((r['profesional'] as String).isNotEmpty)
                _infoRow(Icons.face, '${r['profesional']}'),
              _infoRow(Icons.calendar_today, _formatDate('${r['fecha']}')),
              _infoRow(Icons.access_time, '${r['hora']}'),
              _infoRow(Icons.confirmation_number, '${r['codigo_confirmacion']}'),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Recorda llegar 10 minutos antes',
          style: GoogleFonts.spaceGrotesk(color: PublicTheme.softMuted, fontSize: 13),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const HomeScreen()),
                (route) => false,
              );
            },
            icon: const Icon(Icons.home, size: 20),
            label: const Text('Volver al inicio'),
            style: OutlinedButton.styleFrom(
              foregroundColor: PublicTheme.ink,
              side: BorderSide(color: PublicTheme.stroke),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: PublicTheme.softMuted, size: 18),
          const SizedBox(width: 12),
          Text(text, style: GoogleFonts.spaceGrotesk(color: PublicTheme.ink, fontSize: 14, fontWeight: FontWeight.w600)),
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
