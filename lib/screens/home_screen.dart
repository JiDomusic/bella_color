import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/app_config.dart';
import '../models/tenant.dart';
import '../models/service.dart';
import '../models/professional.dart';
import '../services/supabase_service.dart';
import '../services/whatsapp_service.dart';
import '../widgets/service_card.dart';
import '../widgets/professional_card.dart';
import '../widgets/welcome_overlay.dart';
import '../widgets/page_background.dart';
import '../widgets/video_banner.dart';
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
  bool _isLanding = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final tenantId = _svc.tenantId;
    debugPrint('[HOME] Cargando tenantId=$tenantId');

    // 1. Cargar tenant primero (tabla pública)
    try {
      final tenant = await _svc.loadTenant();
      debugPrint('[HOME] Tenant cargado: nombre=${tenant.nombreSalon}, logo=${tenant.logoUrl}, onboarding=${tenant.onboardingCompleted}');
      if (mounted) setState(() => _tenant = tenant);
    } catch (e) {
      debugPrint('[HOME] Error loading tenant: $e');
      if (mounted) setState(() { _isLanding = true; _loading = false; });
      return;
    }

    // 2. Cargar servicios y profesionales (puede fallar por RLS sin auth)
    List<Service> services = [];
    List<Professional> professionals = [];
    try {
      services = await _svc.loadActiveServices();
      professionals = await _svc.loadActiveProfessionals();
      debugPrint('[HOME] Servicios=${services.length}, Profesionales=${professionals.length}');
    } catch (e) {
      debugPrint('[HOME] Error loading services/professionals (RLS?): $e');
    }

    // 3. Determinar si mostrar landing o vista del salón
    if (mounted) {
      setState(() {
        _services = services;
        _professionals = professionals;
        final tieneContenido = services.isNotEmpty || professionals.isNotEmpty;
        final tieneConfig = (_tenant!.logoUrl != null && _tenant!.logoUrl!.isNotEmpty) || _tenant!.onboardingCompleted;
        _isLanding = (tenantId == 'demo' || tenantId.isEmpty || (!tieneConfig && !tieneContenido));
        debugPrint('[HOME] _isLanding=$_isLanding (tieneConfig=$tieneConfig, tieneContenido=$tieneContenido)');
        _loading = false;
      });
    }
  }

  Color get _primary => _tenant != null
      ? AppConfig.hexToColor(_tenant!.colorPrimario)
      : AppConfig.colorPrimario;

  Color get _accent => _tenant != null
      ? AppConfig.hexToColor(_tenant!.colorAcento)
      : AppConfig.colorAcento;

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

  Future<void> _handlePin(String input, BuildContext ctx) async {
    final pin = PinAuthService.instance;
    final ok = await pin.verifyAsync(input);
    if (!mounted) return;
    if (ok) {
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

  void _openMaps() {
    final query = _tenant?.googleMapsQuery.isNotEmpty == true
        ? _tenant!.googleMapsQuery
        : '${_tenant!.direccion}, ${_tenant!.ciudad}';
    final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(query)}');
    launchUrl(url, mode: LaunchMode.externalApplication);
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

    // ─── Landing pública: solo overlay + super admin ───
    if (_isLanding) {
      return Scaffold(
        backgroundColor: _bgWhite,
        body: Stack(
          children: [
            // Super admin button (long press) arriba
            Positioned(
              top: 40,
              right: 16,
              child: GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminLoginScreen()),
                ),
                onLongPress: _showSuperAdminAuth,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: _accent,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [BoxShadow(color: _accent.withAlpha(80), blurRadius: 8)],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.admin_panel_settings, color: Colors.white, size: 16),
                      SizedBox(width: 6),
                      Text('Admin', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12)),
                    ],
                  ),
                ),
              ),
            ),
            // Overlay fijo ocupa todo
            Positioned(
              top: 70,
              left: 0,
              right: 0,
              bottom: 0,
              child: WelcomeOverlay(
                onSubscribe: _openProgramacionJJWhatsApp,
                mostrarAvisoPendiente: _svc.tenantId != 'demo' &&
                    _svc.tenantId.isNotEmpty &&
                    _tenant != null &&
                    !_tenant!.onboardingCompleted,
              ),
            ),
          ],
        ),
      );
    }

    // ─── Home normal del salón configurado ───
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: PageBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                _buildHeader(),
                // Banner promocional del salon (texto, video o ambos)
                if (_tenant?.mostrarBanner == true) ...[
                  // Video banner
                  if ((_tenant!.bannerTipo == 'video' || _tenant!.bannerTipo == 'ambos') && _tenant!.bannerVideoUrl.isNotEmpty)
                    VideoBanner(videoUrl: _tenant!.bannerVideoUrl, borderColor: _primary),
                  // Texto banner
                  if ((_tenant!.bannerTipo == 'texto' || _tenant!.bannerTipo == 'ambos') && _tenant!.bannerTexto.isNotEmpty)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(200),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _primary.withAlpha(60)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.auto_awesome, color: _accent, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _tenant!.bannerTexto,
                              style: TextStyle(color: _primary, fontSize: 13, fontWeight: FontWeight.w600, height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      if (_services.isNotEmpty) ...[
                        _sectionTitle('Nuestros Servicios'),
                        _buildServicesGrid(),
                      ],
                      if (_professionals.isNotEmpty) ...[
                        _sectionTitle('Nuestro Equipo'),
                        _buildProfessionalsList(),
                      ],
                      _buildCTA(),
                      _buildFooter(),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openBooking(),
        backgroundColor: _accent,
        icon: const Icon(Icons.calendar_today),
        label: const Text('Reservar Turno'),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
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
                    color: Colors.white.withAlpha(180),
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
          if (_tenant?.logoUrl != null)
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 200, maxHeight: 200),
              child: Image.network(
                _tenant!.logoUrl!,
                fit: BoxFit.contain,
              ),
            )
          else
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(200),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: _primary.withAlpha(60)),
              ),
              child: Icon(Icons.spa, size: 60, color: _primary),
            ),
          const SizedBox(height: 16),
          // Nombre, slogan y dirección sobre el fondo
          if (_tenant?.mostrarNombreSalon != false)
            Text(
              _tenant?.nombreSalon ?? 'Salon de Belleza',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: _textDark,
                shadows: [Shadow(color: Colors.white.withAlpha(200), blurRadius: 10)],
              ),
              textAlign: TextAlign.center,
            ),
          if (_tenant?.slogan.isNotEmpty == true) ...[
            const SizedBox(height: 4),
            Text(
              _tenant!.slogan,
              style: TextStyle(
                fontSize: 13,
                color: _primary,
                fontStyle: FontStyle.italic,
                shadows: [Shadow(color: Colors.white.withAlpha(200), blurRadius: 8)],
              ),
              textAlign: TextAlign.center,
            ),
          ],
          if (_tenant?.direccion.isNotEmpty == true) ...[
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => _openMaps(),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(160),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.location_on, size: 14, color: _primary),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        '${_tenant!.direccion}, ${_tenant!.ciudad}',
                        style: TextStyle(fontSize: 12, color: _textDark),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Container(
      margin: const EdgeInsets.fromLTRB(0, 12, 0, 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(180),
        borderRadius: BorderRadius.circular(12),
      ),
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width > 900 ? 4 : width > 600 ? 3 : 2;
        final spacing = 12.0;
        final padding = 16.0;
        final totalSpacing = spacing * (columns - 1) + padding * 2;
        final cardWidth = (width - totalSpacing) / columns;
        final maxCard = 200.0;
        final finalWidth = cardWidth > maxCard ? maxCard : cardWidth;

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: padding),
          child: Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: _services.map((s) => SizedBox(
              width: finalWidth,
              child: ServiceCard(
                service: s,
                primary: _primary,
                accent: _accent,
                onTap: () => _openBooking(service: s),
              ),
            )).toList(),
          ),
        );
      },
    );
  }

  Widget _buildProfessionalsList() {
    return SizedBox(
      height: 240,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: _professionals.length,
        itemBuilder: (_, i) => Padding(
          padding: const EdgeInsets.only(right: 12),
          child: ProfessionalCard(
            professional: _professionals[i],
            primary: _primary,
            cardColor: _tenant?.colorCardProfesional.isNotEmpty == true
                ? AppConfig.hexToColor(_tenant!.colorCardProfesional)
                : null,
            onTap: () => _openBooking(professional: _professionals[i]),
          ),
        ),
      ),
    );
  }

  Widget _buildCTA() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 0),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(210),
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
              label: const Text('Tengo un código de turno'),
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

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 4, 0, 0),
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
