import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../models/tenant.dart';
import '../models/service.dart';
import '../models/professional.dart';
import '../services/supabase_service.dart';
import '../services/whatsapp_service.dart';
import '../widgets/service_card.dart';
import '../widgets/professional_card.dart';
import '../widgets/welcome_overlay.dart';
import 'booking/booking_flow_screen.dart';
import 'admin/admin_login_screen.dart';
import 'admin/super_admin_screen.dart';
import 'confirm_appointment_screen.dart';
import '../services/pin_auth_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _svc = SupabaseService.instance;
  Tenant? _tenant;
  List<Service> _services = [];
  List<Professional> _professionals = [];
  bool _loading = true;
  bool _showWelcomeOverlay = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final tenant = _svc.currentTenant ?? await _svc.loadTenant();
      final services = await _svc.loadActiveServices();
      final professionals = await _svc.loadActiveProfessionals();
      final tenantId = _svc.tenantId;
      if (mounted) {
        setState(() {
          _tenant = tenant;
          _services = services;
          _professionals = professionals;
          _showWelcomeOverlay = (tenantId == 'demo' || tenantId.isEmpty);
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Color get _primary => _tenant != null
      ? AppConfig.hexToColor(_tenant!.colorPrimario)
      : AppConfig.colorPrimario;

  Color get _accent => _tenant != null
      ? AppConfig.hexToColor(_tenant!.colorAcento)
      : AppConfig.colorAcento;

  // Colores para tema blanco
  static const _bgWhite = Color(0xFFFAFAFA);
  static const _textDark = Color(0xFF1A1A1A);
  static const _textMuted = Color(0xFF666666);

  void _showSuperAdminAuth() {
    final pin = PinAuthService.instance;

    if (pin.isLocked) {
      final mins = (pin.remainingLockSeconds / 60).ceil();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Demasiados intentos. Espera $mins minuto${mins == 1 ? '' : 's'}.'), backgroundColor: Colors.redAccent),
      );
      return;
    }

    final pinCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Super Admin', style: TextStyle(color: _textDark)),
        content: TextField(
          controller: pinCtrl,
          obscureText: true,
          keyboardType: TextInputType.number,
          maxLength: 6,
          style: const TextStyle(color: _textDark, letterSpacing: 6, fontSize: 20),
          textAlign: TextAlign.center,
          decoration: InputDecoration(
            labelText: 'PIN',
            labelStyle: const TextStyle(color: _textMuted),
            filled: true,
            fillColor: const Color(0xFFF5F5F5),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: _primary.withAlpha(80)),
            ),
          ),
          onSubmitted: (_) => _handlePin(pinCtrl.text, ctx),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancelar', style: TextStyle(color: _textMuted))),
          ElevatedButton(
            onPressed: () => _handlePin(pinCtrl.text, ctx),
            style: ElevatedButton.styleFrom(backgroundColor: _primary),
            child: const Text('Entrar'),
          ),
        ],
      ),
    );
  }

  void _handlePin(String input, BuildContext ctx) {
    final pin = PinAuthService.instance;
    if (pin.verify(input)) {
      Navigator.pop(ctx);
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SuperAdminScreen()));
    } else {
      Navigator.pop(ctx);
      final msg = pin.isLocked
          ? 'Demasiados intentos. Espera ${PinAuthService.lockoutMinutes} minutos.'
          : 'PIN incorrecto. ${pin.remainingAttempts} intento${pin.remainingAttempts == 1 ? '' : 's'} restante${pin.remainingAttempts == 1 ? '' : 's'}.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
      );
    }
  }

  void _openBooking({Service? service, Professional? professional}) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => BookingFlowScreen(
        preselectedService: service,
        preselectedProfessional: professional,
      ),
    ));
  }

  void _openProgramacionJJWhatsApp() {
    WhatsappService.openChat(
      phone: '3413363551',
      countryCode: '54',
      message: 'Hola! Quiero probar Bella Color gratis por 15 dias. Me pasan el link?',
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: _bgWhite,
        body: Center(child: CircularProgressIndicator(color: _primary)),
      );
    }

    return Scaffold(
      backgroundColor: _bgWhite,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _buildHeader()),
              if (_services.isNotEmpty) ...[
                SliverToBoxAdapter(child: _sectionTitle('Nuestros Servicios')),
                SliverToBoxAdapter(child: _buildServicesGrid()),
              ],
              if (_professionals.isNotEmpty) ...[
                SliverToBoxAdapter(child: _sectionTitle('Nuestro Equipo')),
                SliverToBoxAdapter(child: _buildProfessionalsList()),
              ],
              SliverToBoxAdapter(child: _buildCTA()),
              SliverToBoxAdapter(child: _buildSubscribeButton()),
              SliverToBoxAdapter(child: _buildFooter()),
              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          ),
          // Welcome overlay — fijo, solo en tenant demo
          if (_showWelcomeOverlay)
            Positioned(
              top: 70,
              left: 0,
              right: 0,
              bottom: 0,
              child: WelcomeOverlay(
                onSubscribe: _openProgramacionJJWhatsApp,
              ),
            ),
        ],
      ),
      floatingActionButton: _showWelcomeOverlay
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _openBooking(),
              backgroundColor: _accent,
              icon: const Icon(Icons.calendar_today),
              label: const Text('Reservar Turno'),
            ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_primary.withAlpha(25), _bgWhite],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AdminLoginScreen()),
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: _accent.withAlpha(20),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _accent.withAlpha(100)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.admin_panel_settings, color: _accent, size: 18),
                          const SizedBox(width: 8),
                          Text('Admin', style: TextStyle(color: _accent, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Logo
              if (_tenant?.logoUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.network(_tenant!.logoUrl!, width: 100, height: 100, fit: BoxFit.cover),
                )
              else
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: _primary.withAlpha(25),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _primary.withAlpha(60)),
                  ),
                  child: Icon(Icons.spa, size: 50, color: _primary),
                ),
              const SizedBox(height: 16),
              Text(
                _tenant?.nombreSalon ?? 'Salon de Belleza',
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: _textDark),
                textAlign: TextAlign.center,
              ),
              if (_tenant?.slogan.isNotEmpty == true) ...[
                const SizedBox(height: 8),
                Text(
                  _tenant!.slogan,
                  style: TextStyle(fontSize: 14, color: _primary, fontStyle: FontStyle.italic),
                  textAlign: TextAlign.center,
                ),
              ],
              if (_tenant?.direccion.isNotEmpty == true) ...[
                const SizedBox(height: 12),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.location_on, size: 14, color: _textMuted),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        '${_tenant!.direccion}, ${_tenant!.ciudad}',
                        style: const TextStyle(fontSize: 12, color: _textMuted),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
      child: Row(
        children: [
          Container(width: 3, height: 20, decoration: BoxDecoration(color: _accent, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 10),
          Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: _primary)),
        ],
      ),
    );
  }

  Widget _buildServicesGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: _services.map((s) => SizedBox(
          width: (MediaQuery.of(context).size.width - 44) / 2,
          child: ServiceCard(
            service: s,
            primary: _primary,
            accent: _accent,
            onTap: () => _openBooking(service: s),
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildProfessionalsList() {
    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _professionals.length,
        itemBuilder: (_, i) => Padding(
          padding: const EdgeInsets.only(right: 12),
          child: ProfessionalCard(
            professional: _professionals[i],
            primary: _primary,
            onTap: () => _openBooking(professional: _professionals[i]),
          ),
        ),
      ),
    );
  }

  Widget _buildCTA() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [_primary.withAlpha(15), _accent.withAlpha(10)]),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _primary.withAlpha(40)),
        ),
        child: Column(
          children: [
            Text(
              'Reserva tu turno ahora',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: _primary),
            ),
            const SizedBox(height: 8),
            const Text(
              'Elige tu servicio, profesional y horario preferido',
              style: TextStyle(fontSize: 13, color: _textMuted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _openBooking(),
              icon: const Icon(Icons.calendar_today, size: 18),
              label: const Text('Reservar Turno'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _accent,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ConfirmAppointmentScreen()),
              ),
              icon: const Icon(Icons.confirmation_number, size: 18),
              label: const Text('Tengo un codigo de turno'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _primary,
                side: BorderSide(color: _primary.withAlpha(80)),
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubscribeButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: GestureDetector(
        onTap: _openProgramacionJJWhatsApp,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFE53935), Color(0xFFFF5722)],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFE53935).withAlpha(60),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.spa_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              const Flexible(
                child: Text(
                  'Tenes un salon? Proba gratis 15 dias',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
      child: Column(
        children: [
          Divider(color: _primary.withAlpha(30)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_tenant?.whatsappNumero.isNotEmpty == true)
                IconButton(
                  icon: const Icon(Icons.chat, size: 20),
                  color: _textMuted,
                  onPressed: () => WhatsappService.openChat(
                    phone: _tenant!.whatsappNumero,
                    countryCode: _tenant!.codigoPaisTelefono,
                    message: 'Hola! Quisiera consultar sobre sus servicios.',
                  ),
                ),
              if (_tenant?.telefonoContacto.isNotEmpty == true)
                IconButton(
                  icon: const Icon(Icons.phone, size: 20),
                  color: _textMuted,
                  onPressed: () {},
                ),
            ],
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => WhatsappService.openSupport(),
            onLongPress: _showSuperAdminAuth,
            child: Text(
              'Desarrollado por ${AppConfig.nombreEmpresa}',
              style: TextStyle(fontSize: 11, color: _textMuted.withAlpha(150)),
            ),
          ),
        ],
      ),
    );
  }
}
