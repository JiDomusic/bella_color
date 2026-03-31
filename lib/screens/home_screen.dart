import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/app_config.dart';
import '../config/public_theme.dart';
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
  bool _isVideoPlaying = false;

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

  bool get _hasBannerVideo {
    if (_tenant == null || _tenant!.mostrarBanner != true) return false;
    if (_tenant!.bannerTipo == 'video' || _tenant!.bannerTipo == 'ambos') {
      return _tenant!.bannerVideoUrl.isNotEmpty;
    }
    return false;
  }

  bool get _showTextBanner {
    if (_tenant == null) return false;
    if (_tenant!.mostrarBanner != true) return false;
    final tipo = _tenant!.bannerTipo;
    final hasText = _tenant!.bannerTexto.isNotEmpty;
    return hasText && (tipo == 'texto' || tipo == 'ambos');
  }

  static const _bgWhite = PublicTheme.cream;
  static const _textDark = PublicTheme.ink;
  static const _textMuted = PublicTheme.softMuted;

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
    final hasVideo = _hasBannerVideo;
    final showStrip = _showTextBanner;

    return Scaffold(
      backgroundColor: PublicTheme.cream,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openBooking(),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.calendar_today),
        label: const Text('Reservar Turno'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildTopNav(),
            if (showStrip) _buildBannerStrip(),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildHeroSection(hasVideo),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          if (_services.isNotEmpty) ...[
                            _sectionTitle('Servicios'),
                            _buildServicesGrid(),
                          ],
                          if (_professionals.isNotEmpty) ...[
                            _sectionTitle('Nuestro equipo'),
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
          ],
        ),
      ),
    );
  }

  Widget _buildTopNav() {
    final salonName = (_tenant?.nombreSalon ?? 'Bella Color').toUpperCase();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      color: PublicTheme.nav,
      child: Row(
        children: [
          Text(salonName, style: PublicTheme.navItem.copyWith(letterSpacing: 1.2)),
          const Spacer(),
          GestureDetector(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AdminLoginScreen()),
            ),
            onLongPress: _showSuperAdminAuth,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.admin_panel_settings, color: Colors.white.withAlpha(200), size: 18),
                const SizedBox(width: 8),
                Text('Admin', style: PublicTheme.navItem.copyWith(color: Colors.white70)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBannerStrip() {
    return Container(
      width: double.infinity,
      color: PublicTheme.blush,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Text(
        _tenant?.bannerTexto ?? '',
        style: PublicTheme.banner.copyWith(fontSize: 14),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildHeroSection(bool hasVideo) {
    final headline = _tenant?.subtitulo.isNotEmpty == true
        ? _tenant!.subtitulo
        : 'Colour without bleach?';
    final bodyCopy = _tenant?.slogan.isNotEmpty == true
        ? _tenant!.slogan
        : 'Transformá tu color sin decolorar, con brillo y dimensión.';

    return Container(
      width: double.infinity,
      color: PublicTheme.cream,
      padding: EdgeInsets.fromLTRB(isWideLayout(context) ? 28 : 16, 16, isWideLayout(context) ? 28 : 16, isWideLayout(context) ? 26 : 18),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 900;
              final heroCopy = _buildHeroCopy(headline, bodyCopy, isWide);
              final video = hasVideo ? _buildHeroVideo(isWide) : const SizedBox.shrink();

              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      flex: hasVideo ? 6 : 7,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 540),
                          child: heroCopy,
                        ),
                      ),
                    ),
                    if (hasVideo) const SizedBox(width: 32),
                    if (hasVideo) Expanded(flex: 5, child: video),
                  ],
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  heroCopy,
                  if (hasVideo) const SizedBox(height: 18),
                  video,
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeroCopy(String headline, String bodyCopy, bool isWide) {
    final name = _tenant?.nombreSalon ?? 'Bella Color';
    final slogan = bodyCopy;

    return AnimatedSlide(
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeInOut,
      offset: _isVideoPlaying && isWide ? const Offset(-0.03, 0) : Offset.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildLogoBadge(),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name.toUpperCase(),
                    style: PublicTheme.heroKicker.copyWith(letterSpacing: 1, fontSize: isWide ? 12 : 11),
                  ),
                  if (_tenant?.slogan.isNotEmpty == true)
                    Text(
                      _tenant!.slogan,
                      style: PublicTheme.heroSubtitle.copyWith(
                        color: PublicTheme.softMuted,
                        fontSize: isWide ? 14 : 13,
                      ),
                    ),
                ],
              ),
            ],
          ),
          SizedBox(height: isWide ? 16 : 12),
          Text(
            headline.toUpperCase(),
            style: PublicTheme.heroTitle.copyWith(fontSize: isWide ? 34 : 28),
          ),
          const SizedBox(height: 10),
          Text(
            slogan,
            style: PublicTheme.heroSubtitle.copyWith(fontSize: isWide ? 16 : 15),
          ),
          SizedBox(height: isWide ? 18 : 12),
          if (_tenant?.direccion.isNotEmpty == true)
            GestureDetector(
              onTap: _openMaps,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: isWide ? 16 : 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: PublicTheme.borderMd,
                  border: Border.all(color: PublicTheme.stroke),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withAlpha(14), blurRadius: 10, offset: const Offset(0, 3)),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.place_outlined, size: 16, color: _primary),
                    const SizedBox(width: 6),
                    Text(
                      '${_tenant!.direccion}, ${_tenant!.ciudad}',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: isWide ? 13 : 12,
                        fontWeight: FontWeight.w600,
                        color: PublicTheme.ink,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              ElevatedButton(
                onPressed: _openBooking,
                style: PublicTheme.primaryButton(),
                child: const Text('Reservar ahora'),
              ),
              OutlinedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ConfirmAppointmentScreen()),
                ),
                style: PublicTheme.outlineButton(_primary),
                child: const Text('Tengo un código'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLogoBadge() {
    if (_tenant?.logoUrl != null) {
      return Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: PublicTheme.stroke),
          boxShadow: [BoxShadow(color: Colors.black.withAlpha(12), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Image.network(_tenant!.logoUrl!, width: 70, height: 70, fit: BoxFit.contain),
      );
    }

    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: PublicTheme.stroke),
      ),
      child: Icon(Icons.spa, size: 34, color: _primary),
    );
  }

  Widget _buildHeroVideo(bool isWide) {
    final maxWidth = isWide ? 420.0 : 320.0;
    final maxHeight = isWide ? 620.0 : 360.0;

    return AnimatedSlide(
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeInOut,
      offset: _isVideoPlaying && isWide ? const Offset(0.03, 0) : Offset.zero,
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth, maxHeight: maxHeight),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: PublicTheme.borderLg,
              border: Border.all(color: _primary.withAlpha(60)),
              boxShadow: [
                BoxShadow(color: Colors.black.withAlpha(16), blurRadius: 16, offset: const Offset(0, 6)),
              ],
            ),
            child: VideoBanner(
              videoUrl: _tenant!.bannerVideoUrl,
              borderColor: _primary,
              onPlay: _handleVideoPlay,
              onEnded: _handleVideoEnd,
            ),
          ),
        ),
      ),
    );
  }

  bool isWideLayout(BuildContext context) => MediaQuery.of(context).size.width > 1100;

  void _handleVideoPlay() {
    if (!_isVideoPlaying && mounted) {
      setState(() => _isVideoPlaying = true);
    }
  }

  void _handleVideoEnd() {
    if (mounted) {
      setState(() => _isVideoPlaying = false);
    }
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 18, 4, 10),
      child: Text(
        title.toUpperCase(),
        style: PublicTheme.heroKicker.copyWith(
          letterSpacing: 1.2,
          fontSize: 13,
          color: PublicTheme.ink,
        ),
      ),
    );
  }

  Widget _buildServicesGrid() {
    final isMobile = MediaQuery.of(context).size.width < 640;
    return SizedBox(
      height: isMobile ? 280 : 360,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _services.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) => SizedBox(
          width: isMobile ? 210 : 240,
          child: ServiceCard(
            service: _services[i],
            primary: _primary,
            accent: _accent,
            onTap: () => _openBooking(service: _services[i]),
          ),
        ),
      ),
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
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: PublicTheme.borderLg,
          border: Border.all(color: PublicTheme.stroke),
          boxShadow: [
            BoxShadow(color: Colors.black.withAlpha(12), blurRadius: 14, offset: const Offset(0, 6)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Reserva tu turno ahora', style: PublicTheme.heroTitle.copyWith(fontSize: 22)),
            const SizedBox(height: 10),
            Text(
              'Elegí servicio, profesional y horario sin esperar en el salón.',
              style: PublicTheme.heroSubtitle,
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _openBooking,
                    style: PublicTheme.primaryButton(),
                    icon: const Icon(Icons.calendar_today, size: 18),
                    label: const Text('Reservar turno'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ConfirmAppointmentScreen()),
                    ),
                    style: PublicTheme.outlineButton(_primary),
                    icon: const Icon(Icons.confirmation_number, size: 18),
                    label: const Text('Ya reservé'),
                  ),
                ),
              ],
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
          Divider(color: PublicTheme.stroke),
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
              style: PublicTheme.heroSubtitle.copyWith(fontSize: 11, color: _textMuted.withAlpha(180)),
            ),
          ),
        ],
      ),
    );
  }
}
