import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../models/tenant.dart';
import '../models/service.dart';
import '../models/professional.dart';
import '../services/supabase_service.dart';
import '../services/whatsapp_service.dart';
import '../widgets/service_card.dart';
import '../widgets/professional_card.dart';
import 'booking/booking_flow_screen.dart';
import 'admin/admin_login_screen.dart';
import 'admin/super_admin_screen.dart';

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
      if (mounted) {
        setState(() {
          _tenant = tenant;
          _services = services;
          _professionals = professionals;
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

  void _showSuperAdminAuth() {
    final pinCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppConfig.colorFondoCard,
        title: const Text('Super Admin', style: TextStyle(color: AppConfig.colorTexto)),
        content: TextField(
          controller: pinCtrl,
          obscureText: true,
          keyboardType: TextInputType.number,
          maxLength: 6,
          style: const TextStyle(color: AppConfig.colorTexto, letterSpacing: 6, fontSize: 20),
          textAlign: TextAlign.center,
          decoration: const InputDecoration(labelText: 'PIN'),
          onSubmitted: (_) => _handlePin(pinCtrl.text, ctx),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => _handlePin(pinCtrl.text, ctx),
            child: const Text('Entrar'),
          ),
        ],
      ),
    );
  }

  void _handlePin(String pin, BuildContext ctx) {
    if (pin == AppConfig.superAdminPin) {
      Navigator.pop(ctx);
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SuperAdminScreen()));
    } else {
      Navigator.pop(ctx);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PIN incorrecto'), backgroundColor: Colors.redAccent),
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

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: AppConfig.colorFondoOscuro,
        body: Center(child: CircularProgressIndicator(color: _primary)),
      );
    }

    return Scaffold(
      backgroundColor: AppConfig.colorFondoOscuro,
      body: CustomScrollView(
        slivers: [
          // Hero header
          SliverToBoxAdapter(child: _buildHeader()),
          // Services section
          if (_services.isNotEmpty) ...[
            SliverToBoxAdapter(child: _sectionTitle('Nuestros Servicios')),
            SliverToBoxAdapter(child: _buildServicesGrid()),
          ],
          // Professionals section
          if (_professionals.isNotEmpty) ...[
            SliverToBoxAdapter(child: _sectionTitle('Nuestro Equipo')),
            SliverToBoxAdapter(child: _buildProfessionalsList()),
          ],
          // CTA button
          SliverToBoxAdapter(child: _buildCTA()),
          // Footer
          SliverToBoxAdapter(child: _buildFooter()),
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
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
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_primary.withAlpha(60), AppConfig.colorFondoOscuro],
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
                    onLongPress: _showSuperAdminAuth,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AdminLoginScreen()),
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: _accent.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _accent.withOpacity(0.6)),
                        boxShadow: [
                          BoxShadow(
                            color: _accent.withOpacity(0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
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
                    color: _primary.withAlpha(40),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(Icons.spa, size: 50, color: _primary),
                ),
              const SizedBox(height: 16),
              Text(
                _tenant?.nombreSalon ?? 'Salon de Belleza',
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppConfig.colorTexto),
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
                    Icon(Icons.location_on, size: 14, color: AppConfig.colorTextoSecundario),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        '${_tenant!.direccion}, ${_tenant!.ciudad}',
                        style: const TextStyle(fontSize: 12, color: AppConfig.colorTextoSecundario),
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
          gradient: LinearGradient(colors: [_primary.withAlpha(30), _accent.withAlpha(20)]),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _primary.withAlpha(60)),
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
              style: TextStyle(fontSize: 13, color: AppConfig.colorTextoSecundario),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _openBooking(),
              icon: const Icon(Icons.calendar_today, size: 18),
              label: const Text('Reservar'),
              style: ElevatedButton.styleFrom(backgroundColor: _accent),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
      child: Column(
        children: [
          Divider(color: _primary.withAlpha(40)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_tenant?.whatsappNumero.isNotEmpty == true)
                IconButton(
                  icon: const Icon(Icons.chat, size: 20),
                  color: AppConfig.colorTextoSecundario,
                  onPressed: () => WhatsappService.openChat(
                    phone: _tenant!.whatsappNumero,
                    countryCode: _tenant!.codigoPaisTelefono,
                    message: 'Hola! Quisiera consultar sobre sus servicios.',
                  ),
                ),
              if (_tenant?.telefonoContacto.isNotEmpty == true)
                IconButton(
                  icon: const Icon(Icons.phone, size: 20),
                  color: AppConfig.colorTextoSecundario,
                  onPressed: () {},
                ),
            ],
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => WhatsappService.openSupport(),
            child: Text(
              'Desarrollado por ${AppConfig.nombreEmpresa}',
              style: TextStyle(fontSize: 11, color: _primary.withAlpha(100)),
            ),
          ),
        ],
      ),
    );
  }
}
