import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
import '../../config/app_config.dart';
import '../../models/tenant.dart';
import '../../models/professional.dart';
import '../../models/service.dart';
import '../../models/appointment.dart';
import '../../models/operating_hours.dart';
import '../../models/block.dart';
import '../../models/waitlist_entry.dart';
import '../../services/supabase_service.dart';
import '../../services/subscription_service.dart';
import '../../services/whatsapp_service.dart';
import '../../services/notification_service.dart';
import 'admin_login_screen.dart';
import 'reports_tab.dart';
import 'clientes_tab.dart';
import 'stock_tab.dart';
import '../home_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> with TickerProviderStateMixin {
  final _svc = SupabaseService.instance;
  late TabController _tabController;

  Tenant? _tenant;
  List<Professional> _professionals = [];
  List<Service> _services = [];
  List<Appointment> _appointments = [];
  List<OperatingHours> _hours = [];
  List<Block> _blocks = [];
  List<WaitlistEntry> _waitlist = [];
  Set<String> _frequentPhones = {};
  bool _loading = true;
  bool _changingPassword = false;
  NotificationService? _notifService;

  String _selectedDate = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 10, vsync: this);
    final now = DateTime.now();
    _selectedDate = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    _loadAll();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _notifService?.dispose();
    super.dispose();
  }

  Color get _primaryRaw => _tenant != null ? AppConfig.hexToColor(_tenant!.colorPrimario) : AppConfig.colorPrimario;
  Color get _primary {
    final c = _primaryRaw;
    if (c.computeLuminance() < 0.15) {
      return Color.lerp(c, Colors.white, 0.5)!;
    }
    return c;
  }
  Color get _accentRaw => _tenant != null ? AppConfig.hexToColor(_tenant!.colorAcento) : AppConfig.colorAcento;
  /// Acento con contraste garantizado sobre fondo oscuro del admin.
  Color get _accent {
    final c = _accentRaw;
    // Si el color es muy oscuro (luminancia < 0.15), usar versión clara
    if (c.computeLuminance() < 0.15) {
      return Color.lerp(c, Colors.white, 0.5)!;
    }
    return c;
  }

  Future<void> _loadAll() async {
    try {
      _tenant = await _svc.loadTenant();
    } catch (_) {}

    // Si el onboarding no esta completo, no cargar el resto
    if (_tenant != null && !_tenant!.onboardingCompleted) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    try {
      _professionals = await _svc.loadProfessionals();
      _services = await _svc.loadServices();
      _appointments = await _svc.loadAppointments(fecha: _selectedDate);
      _hours = await _svc.loadOperatingHours();
      _blocks = await _svc.loadBlocks();
      _waitlist = await _svc.loadWaitlist();
      _frequentPhones = await _svc.loadFrequentClientPhones();
    } catch (_) {}

    // Inicializar notificaciones de cierre y stock bajo
    if (_hours.isNotEmpty && mounted) {
      _notifService?.dispose();
      _notifService = NotificationService(
        onNotification: (title, message) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(message, style: const TextStyle(fontSize: 12)),
                  ],
                ),
                duration: const Duration(minutes: 10),
                backgroundColor: _accent,
                action: SnackBarAction(label: 'OK', textColor: Colors.white, onPressed: () {}),
              ),
            );
          }
        },
        onLowStock: (productos) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Stock bajo en: ${productos.map((p) => '${p.nombre} (${p.cantidad})').join(', ')}'),
                duration: const Duration(seconds: 10),
                backgroundColor: Colors.redAccent,
              ),
            );
          }
        },
      );
      _notifService!.scheduleClosingAlerts(_hours);
      // Chequear stock bajo al cargar
      try {
        final bajoStock = await _svc.loadProductosBajoStock();
        _notifService!.checkLowStock(bajoStock);
      } catch (_) {}
    }

    if (mounted) setState(() => _loading = false);
  }

  Future<void> _refreshAppointments() async {
    final appts = await _svc.loadAppointments(fecha: _selectedDate);
    if (mounted) setState(() => _appointments = appts);
  }

  void _showTrialGiftDialog(BuildContext ctx) {
    showDialog(
      context: ctx,
      barrierDismissible: false,
      builder: (dlg) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppConfig.colorPrimario.withAlpha(30),
              ),
              child: const Icon(Icons.card_giftcard, color: AppConfig.colorPrimario, size: 48),
            ),
            const SizedBox(height: 20),
            const Text(
              'Te ganaste 5 dias mas!',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF1A1A1A), fontSize: 22, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            const Text(
              'Por completar tu configuracion, Programacion JJ te regala 5 dias extra de prueba.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF666666), fontSize: 15, height: 1.5),
            ),
            const SizedBox(height: 8),
            const Text(
              'En total tenes 20 dias para probar el sistema.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppConfig.colorPrimario, fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(dlg),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConfig.colorPrimario,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Genial, gracias!', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: AppConfig.colorFondoOscuro,
        body: Center(child: CircularProgressIndicator(color: _primary)),
      );
    }

    // Si el onboarding no esta completo, mostrar pantalla de configuracion inicial
    if (_tenant != null && !_tenant!.onboardingCompleted) {
      return _buildOnboardingScreen();
    }

    return Scaffold(
      backgroundColor: AppConfig.colorFondoOscuro,
      appBar: AppBar(
        title: Text(_tenant?.nombreSalon ?? 'Admin'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline, color: AppConfig.colorPrimario),
            tooltip: 'Guia de uso',
            onPressed: _showHelp,
          ),
          IconButton(
            icon: Icon(Icons.home, color: _accent),
            tooltip: 'Ir al inicio',
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const HomeScreen()),
                (route) => false,
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.lock_outline, color: Colors.white70),
            tooltip: 'Cambiar contraseña',
            onPressed: _promptChangePassword,
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white70),
            tooltip: 'Cerrar sesion',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Cerrar sesion'),
                  content: const Text('Vas a salir del panel de administracion.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
                    TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Salir')),
                  ],
                ),
              );
              if (confirm == true && mounted) {
                await _svc.signOut();
                if (mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const HomeScreen()),
                    (route) => false,
                  );
                }
              }
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: _accent,
          labelColor: _accent,
          unselectedLabelColor: AppConfig.colorTextoSecundario,
          tabs: const [
            Tab(icon: Icon(Icons.calendar_today, size: 16), text: 'Turnos'),
            Tab(icon: Icon(Icons.people, size: 16), text: 'Equipo'),
            Tab(icon: Icon(Icons.spa, size: 16), text: 'Servicios'),
            Tab(icon: Icon(Icons.schedule, size: 16), text: 'Horarios'),
            Tab(icon: Icon(Icons.event_busy, size: 16), text: 'Cerrar dias'),
            Tab(icon: Icon(Icons.hourglass_top, size: 16), text: 'Espera'),
            Tab(icon: Icon(Icons.people_alt, size: 16), text: 'Clientes'),
            Tab(icon: Icon(Icons.inventory_2, size: 16), text: 'Stock'),
            Tab(icon: Icon(Icons.bar_chart, size: 16), text: 'Reportes'),
            Tab(icon: Icon(Icons.store, size: 16), text: 'Mi Salon'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Subscription warning banner
          if (_tenant != null) _buildSubscriptionBanner(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAppointmentsTab(),
                _buildProfessionalsTab(),
                _buildServicesTab(),
                _buildHoursTab(),
                _buildBlocksTab(),
                _buildWaitlistTab(),
                ClientesTab(primary: _primary, accent: _accent),
                StockTab(primary: _primary, accent: _accent),
                ReportsTab(primary: _primary, accent: _accent),
                _buildSalonTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showHelp() {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: AppConfig.colorFondoCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [_primary.withAlpha(40), _accent.withAlpha(20)]),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.favorite, color: Colors.pink.shade200, size: 28),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text('Guia de Uso', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppConfig.colorTexto)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppConfig.colorTextoSecundario),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              // Content
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    _helpSection('Profesionales', Icons.person, [
                      'Anda a la pestana "Profesionales"',
                      'Toca "Agregar Profesional"',
                      'Pone nombre y especialidad',
                      'Usa el switch para activar/desactivar',
                    ]),
                    _helpSection('Servicios', Icons.spa, [
                      'Anda a la pestana "Servicios"',
                      'Toca "Agregar Servicio"',
                      'Pone nombre, categoria, duracion y precio',
                      'Usa el switch para activar/desactivar',
                    ]),
                    _helpSection('Horarios', Icons.access_time, [
                      'Anda a la pestana "Horarios"',
                      'Toca "Editar Horarios"',
                      'Pone hora inicio, hora fin e intervalo',
                      'Selecciona los dias que abris',
                    ]),
                    _helpSection('Turnos', Icons.calendar_today, [
                      'Anda a la pestana "Turnos"',
                      'Selecciona la fecha para ver los turnos del dia',
                      'Confirmar: cuando la clienta confirma que va',
                      'Atender: cuando llega y empieza el servicio',
                      'Completar: cuando termino',
                      'No Show: si no vino',
                      'Cancelar: si cancela',
                    ]),
                    _helpSection('Bloqueos', Icons.block, [
                      'Anda a "Bloqueos" para cerrar dias u horas',
                      'Dia completo: feriados, vacaciones',
                      'Hora especifica: si necesitas cerrar un rato',
                    ]),
                    _helpSection('Lista de espera', Icons.people, [
                      'Cuando no hay turnos, las clientas se anotan',
                      'Vos ves la lista en "Espera"',
                      'Toca el icono de WhatsApp para avisarles',
                    ]),
                    _helpSection('Tu suscripcion', Icons.favorite, [
                      'Tenes 15 dias gratis para probar',
                      'Despues, el pago se vence el dia ${_tenant?.subscriptionDueDay ?? 18} de cada mes',
                      'Si no pagas, tenes 5 dias de gracia',
                      'Pasados los 5 dias, el sistema se bloquea',
                      'Contacta a soporte para reactivar',
                    ]),
                    const SizedBox(height: 16),
                    const Divider(color: Colors.white12),
                    const SizedBox(height: 8),
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          WhatsappService.openSupport();
                        },
                        icon: const Icon(Icons.chat, size: 18),
                        label: const Text('Contactar Soporte'),
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF25D366)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        '${AppConfig.nombreEmpresa} - WhatsApp ${AppConfig.whatsappSoporte}',
                        style: TextStyle(fontSize: 11, color: _primary.withAlpha(100)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _helpSection(String title, IconData icon, List<String> steps) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: _accent),
              const SizedBox(width: 8),
              Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _primary)),
            ],
          ),
          const SizedBox(height: 6),
          ...steps.map((s) => Padding(
            padding: const EdgeInsets.only(left: 26, bottom: 3),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('- ', style: TextStyle(color: AppConfig.colorTextoSecundario, fontSize: 13)),
                Expanded(child: Text(s, style: const TextStyle(color: AppConfig.colorTextoSecundario, fontSize: 13))),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildSubscriptionBanner() {
    final status = SubscriptionService.check(_tenant!);
    if (status.message.isEmpty) return const SizedBox.shrink();

    final Color bannerColor;
    final IconData icon;
    if (status.isBlocked || !status.isActive) {
      bannerColor = Colors.red;
      icon = Icons.heart_broken;
    } else if (status.isTrial && status.daysRemaining <= 3) {
      bannerColor = Colors.orange;
      icon = Icons.timer;
    } else if (status.isTrial) {
      bannerColor = Colors.amber;
      icon = Icons.card_giftcard;
    } else if (status.daysRemaining <= 5) {
      bannerColor = Colors.orange;
      icon = Icons.warning_amber;
    } else {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: bannerColor.withAlpha(25),
        border: Border(bottom: BorderSide(color: bannerColor.withAlpha(60))),
      ),
      child: Row(
        children: [
          Icon(icon, color: bannerColor, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              status.message,
              style: TextStyle(color: bannerColor, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
          if (!status.isActive)
            GestureDetector(
              onTap: () => WhatsappService.openSupport(),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF25D366).withAlpha(30),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('Soporte', style: TextStyle(color: Color(0xFF25D366), fontSize: 11, fontWeight: FontWeight.w600)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _tabHint(String emoji, String text) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppConfig.colorPrimario.withAlpha(15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppConfig.colorPrimario.withAlpha(40)),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(color: AppConfig.colorTerciario, fontSize: 12, height: 1.4))),
        ],
      ),
    );
  }

  // ==== TAB 0: TURNOS ====
  Widget _buildAppointmentsTab() {
    return Column(
      children: [
        _tabHint('📅', 'Aca ves los turnos del dia. Podes confirmar, atender, completar o cancelar cada turno.'),
        // Date selector
        Padding(
          padding: const EdgeInsets.all(12),
          child: GestureDetector(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                locale: const Locale('es', ''),
                initialDate: DateTime.tryParse(_selectedDate) ?? DateTime.now(),
                firstDate: DateTime.now().subtract(const Duration(days: 90)),
                lastDate: DateTime.now().add(const Duration(days: 90)),
                builder: (ctx, child) => Theme(
                  data: Theme.of(ctx).copyWith(colorScheme: ColorScheme.dark(primary: _primary, secondary: _accent, surface: AppConfig.colorFondoCard)),
                  child: child!,
                ),
              );
              if (picked != null) {
                _selectedDate = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
                _refreshAppointments();
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppConfig.colorFondoCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _primary.withAlpha(60)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.calendar_today, color: _primary, size: 18),
                  const SizedBox(width: 8),
                  Text(_selectedDate, style: const TextStyle(color: AppConfig.colorTexto, fontSize: 15)),
                  const SizedBox(width: 8),
                  Icon(Icons.arrow_drop_down, color: _primary),
                ],
              ),
            ),
          ),
        ),
        // Reminder button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _showRemindersDialog,
              icon: const Icon(Icons.notifications_active, size: 18),
              label: const Text('Enviar recordatorios de mañana'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _accent,
                side: BorderSide(color: _accent.withAlpha(100)),
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Appointments list
        Expanded(
          child: _appointments.isEmpty
              ? Center(child: Text('Sin turnos para esta fecha', style: TextStyle(color: AppConfig.colorTextoSecundario)))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: _appointments.length,
                  itemBuilder: (_, i) => _appointmentCard(_appointments[i]),
                ),
        ),
      ],
    );
  }

  Widget _appointmentCard(Appointment a) {
    final stateColor = _stateColor(a.estado);
    final tenantCountry = _tenant?.codigoPaisTelefono ?? '54';
    final hasPhone = a.telefono.trim().isNotEmpty;
    final hasPrecio = a.precio != null;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(a.hora, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _primary)),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: stateColor.withAlpha(30), borderRadius: BorderRadius.circular(8)),
                  child: Text(Appointment.estadoLabel(a.estado), style: TextStyle(fontSize: 11, color: stateColor, fontWeight: FontWeight.w600)),
                ),
                const Spacer(),
                Text(a.codigoConfirmacion, style: TextStyle(fontSize: 12, color: _accent, fontWeight: FontWeight.w600, letterSpacing: 1)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Flexible(child: Text(a.nombreCliente, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppConfig.colorTexto), overflow: TextOverflow.ellipsis)),
                if (_frequentPhones.contains(a.telefono)) ...[
                  const SizedBox(width: 6),
                  Tooltip(message: 'Clienta frecuente', child: Icon(Icons.favorite, size: 14, color: Colors.pink.shade300)),
                ],
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: Text('${a.servicioNombre ?? ''} ${a.professionalNombre != null ? '- ${a.professionalNombre}' : ''}',
                      style: const TextStyle(fontSize: 12, color: AppConfig.colorTextoSecundario), overflow: TextOverflow.ellipsis),
                ),
                if (hasPrecio)
                  Text(
                    '\$${a.precio!.toStringAsFixed(0)}',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _primary),
                  ),
              ],
            ),
            Text(a.telefono, style: const TextStyle(fontSize: 12, color: AppConfig.colorTextoSecundario)),
            const SizedBox(height: 8),
            // Action buttons
            Wrap(
              spacing: 6,
              children: [
                if (a.isPending) _stateBtn('Confirmar', Icons.check, Colors.green, () => _changeState(a.id, 'confirmada')),
                if (a.isConfirmed) _stateBtn('Atender', Icons.play_arrow, Colors.blue, () => _changeState(a.id, 'en_atencion')),
                if (a.isInProgress) _stateBtn('Completar', Icons.done_all, Colors.green, () => _changeState(a.id, 'completada')),
                if (!a.isCancelled && !a.isCompleted && !a.isNoShow) ...[
                  _stateBtn('No Show', Icons.person_off, Colors.orange, () => _changeState(a.id, 'no_show')),
                  _stateBtn('Cancelar', Icons.close, Colors.red, () => _changeState(a.id, 'cancelada')),
                ],
                if (hasPhone)
                  _stateBtn('WhatsApp', Icons.chat, Colors.green.shade600, () {
                    WhatsappService.openChat(
                      phone: a.telefono,
                      countryCode: tenantCountry,
                      message: 'Hola ${a.nombreCliente}, soy del salon ${_tenant?.nombreSalon ?? ''}.',
                    );
                  }),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _stateBtn(String label, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(color: color.withAlpha(20), borderRadius: BorderRadius.circular(8), border: Border.all(color: color.withAlpha(80))),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Future<void> _changeState(String id, String estado) async {
    await _svc.updateAppointmentStatus(id, estado);
    // Auto-crear cliente al completar un turno
    if (estado == 'completada') {
      try {
        final appt = _appointments.firstWhere((a) => a.id == id);
        await _svc.getOrCreateCliente(
          appt.nombreCliente,
          appt.telefono,
          email: appt.email,
        );
      } catch (_) {}
    }
    _refreshAppointments();
  }

  Future<void> _showRemindersDialog() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(child: CircularProgressIndicator(color: _accent)),
    );

    try {
      final appointments = await _svc.loadTomorrowConfirmedAppointments();
      if (!mounted) return;
      Navigator.pop(context); // close loading

      if (appointments.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No hay turnos confirmados para mañana')),
        );
        return;
      }

      final tomorrow = DateTime.now().add(const Duration(days: 1));
      final fechaStr = '${tomorrow.day.toString().padLeft(2, '0')}/${tomorrow.month.toString().padLeft(2, '0')}/${tomorrow.year}';
      final salonName = _tenant?.nombreSalon ?? '';

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: AppConfig.colorFondoCard,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (ctx) => _RemindersSheet(
          appointments: appointments,
          fechaStr: fechaStr,
          salonName: salonName,
          tenant: _tenant,
          primary: _primary,
          accent: _accent,
          svc: _svc,
        ),
      );
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  Color _stateColor(String estado) {
    switch (estado) {
      case 'pendiente_confirmacion': return Colors.amber;
      case 'confirmada': return Colors.green;
      case 'en_atencion': return Colors.blue;
      case 'completada': return Colors.teal;
      case 'no_show': return Colors.orange;
      case 'cancelada': return Colors.red;
      default: return Colors.grey;
    }
  }

  // ==== TAB 1: PROFESIONALES ====
  Widget _buildProfessionalsTab() {
    return Column(
      children: [
        _tabHint('💇‍♀️', 'Agrega a las personas que atienden en tu salon. Podes subir foto, nombre y especialidad. Usa el switch para activar o desactivar.'),
        Padding(
          padding: const EdgeInsets.all(12),
          child: ElevatedButton.icon(
            onPressed: _addProfessionalDialog,
            icon: const Icon(Icons.person_add),
            label: const Text('Agregar Profesional'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConfig.colorPrimario,
              foregroundColor: Colors.white,
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: _professionals.length,
            itemBuilder: (_, i) {
              final p = _professionals[i];
              return Card(
                child: ListTile(
                  onTap: () => _editProfessionalDialog(p),
                  leading: CircleAvatar(
                    backgroundColor: _primary.withAlpha(30),
                    backgroundImage: p.fotoUrl != null ? NetworkImage(p.fotoUrl!) : null,
                    child: p.fotoUrl == null ? Text(p.nombre[0], style: TextStyle(color: _primary)) : null,
                  ),
                  title: Text(p.nombre, style: const TextStyle(color: AppConfig.colorTexto)),
                  subtitle: Text(p.especialidad, style: const TextStyle(color: AppConfig.colorTextoSecundario, fontSize: 12)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.history, color: _accent, size: 20),
                        tooltip: 'Historial',
                        onPressed: () => _showProfessionalHistory(p),
                      ),
                      Switch(
                        value: p.activo,
                        activeColor: _primary,
                        onChanged: (v) async {
                          await _svc.updateProfessional(p.id, {'activo': v});
                          _professionals = await _svc.loadProfessionals();
                          setState(() {});
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.redAccent, size: 20),
                        onPressed: () async {
                          await _svc.deleteProfessional(p.id);
                          _professionals = await _svc.loadProfessionals();
                          setState(() {});
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showProfessionalHistory(Professional p) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppConfig.colorFondoCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (ctx, scrollCtrl) => FutureBuilder<List<Appointment>>(
          future: _svc.loadAppointments().then((all) =>
            all.where((a) => a.professionalId == p.id).toList()
              ..sort((a, b) => '${b.fecha}${b.hora}'.compareTo('${a.fecha}${a.hora}'))
          ),
          builder: (ctx, snap) {
            final turnos = snap.data ?? [];
            final completados = turnos.where((t) => t.estado == 'completada').toList();
            return ListView(
              controller: scrollCtrl,
              padding: const EdgeInsets.all(16),
              children: [
                Center(child: Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 16), decoration: BoxDecoration(color: Colors.grey[600], borderRadius: BorderRadius.circular(2)))),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: _primary.withAlpha(40),
                      backgroundImage: p.fotoUrl != null ? NetworkImage(p.fotoUrl!) : null,
                      child: p.fotoUrl == null ? Text(p.nombre[0], style: TextStyle(color: _primary, fontWeight: FontWeight.bold, fontSize: 20)) : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.nombre, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        Text(p.especialidad, style: const TextStyle(color: AppConfig.colorTextoSecundario, fontSize: 13)),
                      ],
                    )),
                  ],
                ),
                const SizedBox(height: 16),
                // Resumen
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppConfig.colorSurfaceVariant, borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _statBadge('Total', '${turnos.length}', _primary),
                      _statBadge('Completados', '${completados.length}', Colors.green),
                      _statBadge('No show', '${turnos.where((t) => t.estado == 'no_show').length}', Colors.orange),
                      _statBadge('Cancelados', '${turnos.where((t) => t.estado == 'cancelada').length}', Colors.redAccent),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text('Historial de trabajos (${completados.length})', style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                if (!snap.hasData)
                  const Center(child: CircularProgressIndicator())
                else if (completados.isEmpty)
                  const Text('No hay turnos completados aun.', style: TextStyle(color: AppConfig.colorTextoSecundario))
                else
                  ...completados.take(50).map((t) => Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(color: AppConfig.colorSurfaceVariant, borderRadius: BorderRadius.circular(10)),
                    child: Row(
                      children: [
                        Text(t.fecha, style: const TextStyle(color: AppConfig.colorTextoSecundario, fontSize: 12)),
                        const SizedBox(width: 6),
                        Text(t.hora, style: const TextStyle(color: AppConfig.colorTextoSecundario, fontSize: 12)),
                        const SizedBox(width: 10),
                        Expanded(child: Text(t.servicioNombre ?? '-', style: const TextStyle(color: Colors.white, fontSize: 13))),
                        Text(t.nombreCliente, style: TextStyle(color: _accent, fontSize: 12)),
                      ],
                    ),
                  )),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _statBadge(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: AppConfig.colorTextoSecundario, fontSize: 10)),
      ],
    );
  }

  void _addProfessionalDialog() {
    final nameCtrl = TextEditingController();
    final specCtrl = TextEditingController();
    Uint8List? imageBytes;
    String? imageName;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDState) => AlertDialog(
          backgroundColor: AppConfig.colorFondoCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Nuevo Profesional', style: TextStyle(color: AppConfig.colorTexto)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () async {
                    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 800, imageQuality: 85);
                    if (picked != null) {
                      final bytes = await picked.readAsBytes();
                      setDState(() { imageBytes = bytes; imageName = picked.name; });
                    }
                  },
                  child: CircleAvatar(
                    radius: 40,
                    backgroundColor: _primary.withAlpha(30),
                    backgroundImage: imageBytes != null ? MemoryImage(imageBytes!) : null,
                    child: imageBytes == null
                        ? Column(mainAxisSize: MainAxisSize.min, children: [
                            Icon(Icons.camera_alt, color: _primary, size: 24),
                            Text('Foto', style: TextStyle(color: _primary, fontSize: 10)),
                          ])
                        : null,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nombre'), style: const TextStyle(color: AppConfig.colorTexto)),
                const SizedBox(height: 8),
                TextField(controller: specCtrl, decoration: const InputDecoration(labelText: 'Especialidad'), style: const TextStyle(color: AppConfig.colorTexto)),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty) return;
                String? fotoUrl;
                if (imageBytes != null) {
                  fotoUrl = await _svc.uploadImage('professionals/${DateTime.now().millisecondsSinceEpoch}_$imageName', imageBytes!);
                }
                await _svc.createProfessional({
                  'nombre': nameCtrl.text.trim(),
                  'especialidad': specCtrl.text.trim(),
                  if (fotoUrl != null) 'foto_url': fotoUrl,
                });
                _professionals = await _svc.loadProfessionals();
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) setState(() {});
              },
              child: const Text('Crear'),
            ),
          ],
        ),
      ),
    );
  }

  void _editProfessionalDialog(Professional p) {
    final nameCtrl = TextEditingController(text: p.nombre);
    final specCtrl = TextEditingController(text: p.especialidad);
    Uint8List? imageBytes;
    String? imageName;
    String? currentFotoUrl = p.fotoUrl;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDState) => AlertDialog(
          backgroundColor: AppConfig.colorFondoCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Editar Profesional', style: TextStyle(color: AppConfig.colorTexto)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () async {
                    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 800, imageQuality: 85);
                    if (picked != null) {
                      final bytes = await picked.readAsBytes();
                      setDState(() { imageBytes = bytes; imageName = picked.name; });
                    }
                  },
                  child: CircleAvatar(
                    radius: 40,
                    backgroundColor: _primary.withAlpha(30),
                    backgroundImage: imageBytes != null
                        ? MemoryImage(imageBytes!) as ImageProvider
                        : (currentFotoUrl != null ? NetworkImage(currentFotoUrl!) : null),
                    child: (imageBytes == null && currentFotoUrl == null)
                        ? Column(mainAxisSize: MainAxisSize.min, children: [
                            Icon(Icons.camera_alt, color: _primary, size: 24),
                            Text('Foto', style: TextStyle(color: _primary, fontSize: 10)),
                          ])
                        : null,
                  ),
                ),
                if (currentFotoUrl != null && imageBytes == null)
                  TextButton(
                    onPressed: () => setDState(() => currentFotoUrl = null),
                    child: const Text('Quitar foto', style: TextStyle(color: Colors.redAccent, fontSize: 12)),
                  ),
                const SizedBox(height: 12),
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nombre'), style: const TextStyle(color: AppConfig.colorTexto)),
                const SizedBox(height: 8),
                TextField(controller: specCtrl, decoration: const InputDecoration(labelText: 'Especialidad'), style: const TextStyle(color: AppConfig.colorTexto)),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty) return;
                String? fotoUrl = currentFotoUrl;
                if (imageBytes != null) {
                  fotoUrl = await _svc.uploadImage('professionals/${DateTime.now().millisecondsSinceEpoch}_$imageName', imageBytes!);
                }
                await _svc.updateProfessional(p.id, {
                  'nombre': nameCtrl.text.trim(),
                  'especialidad': specCtrl.text.trim(),
                  'foto_url': fotoUrl,
                });
                _professionals = await _svc.loadProfessionals();
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) setState(() {});
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  // ==== TAB 2: SERVICIOS ====
  Widget _buildServicesTab() {
    return Column(
      children: [
        _tabHint('💅', 'Agrega los servicios que ofrece tu salon: corte, color, manicura, etc. Pone el nombre, cuanto dura, el precio y una foto linda.'),
        Padding(
          padding: const EdgeInsets.all(12),
          child: ElevatedButton.icon(
            onPressed: _addServiceDialog,
            icon: const Icon(Icons.add),
            label: const Text('Agregar Servicio'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConfig.colorPrimario,
              foregroundColor: Colors.white,
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: _services.length,
            itemBuilder: (_, i) {
              final s = _services[i];
              return Card(
                child: ListTile(
                  onTap: () => _editServiceDialog(s),
                  leading: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: _primary.withAlpha(20),
                      borderRadius: BorderRadius.circular(10),
                      image: s.imagenUrl != null ? DecorationImage(image: NetworkImage(s.imagenUrl!), fit: BoxFit.cover) : null,
                    ),
                    child: s.imagenUrl == null ? Icon(Icons.spa, color: _primary) : null,
                  ),
                  title: Text(s.nombre, style: const TextStyle(color: AppConfig.colorTexto)),
                  subtitle: Text('${s.duracionMinutos} min - ${Service.categoriaLabel(s.categoria)}${s.precio != null ? ' - \$${s.precio!.toStringAsFixed(0)}' : ''}',
                      style: const TextStyle(color: AppConfig.colorTextoSecundario, fontSize: 12)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Switch(
                        value: s.activo,
                        activeColor: _primary,
                        onChanged: (v) async {
                          await _svc.updateService(s.id, {'activo': v});
                          _services = await _svc.loadServices();
                          setState(() {});
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.redAccent, size: 20),
                        onPressed: () async {
                          await _svc.deleteService(s.id);
                          _services = await _svc.loadServices();
                          setState(() {});
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _addServiceDialog() {
    final nameCtrl = TextEditingController();
    final durCtrl = TextEditingController(text: '60');
    final priceEfectivoCtrl = TextEditingController();
    final priceTarjetaCtrl = TextEditingController();
    final descEfectivoCtrl = TextEditingController();
    final descTarjetaCtrl = TextEditingController();
    String selectedCat = 'otro';
    Uint8List? imageBytes;
    String? imageName;
    bool requiereSena = false;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDState) => AlertDialog(
          backgroundColor: AppConfig.colorFondoCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Nuevo Servicio', style: TextStyle(color: AppConfig.colorTexto)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () async {
                    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1200, imageQuality: 85);
                    if (picked != null) {
                      final bytes = await picked.readAsBytes();
                      setDState(() { imageBytes = bytes; imageName = picked.name; });
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    height: 120,
                    decoration: BoxDecoration(
                      color: _primary.withAlpha(20),
                      borderRadius: BorderRadius.circular(12),
                      image: imageBytes != null ? DecorationImage(image: MemoryImage(imageBytes!), fit: BoxFit.cover) : null,
                    ),
                    child: imageBytes == null
                        ? Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Icon(Icons.add_photo_alternate, color: _primary, size: 32),
                            const SizedBox(height: 4),
                            Text('Agregar imagen', style: TextStyle(color: _primary, fontSize: 12)),
                          ])
                        : null,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nombre'), style: const TextStyle(color: AppConfig.colorTexto)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: selectedCat,
                  decoration: const InputDecoration(labelText: 'Categoria'),
                  dropdownColor: AppConfig.colorFondoCard,
                  items: Service.categorias.map((c) => DropdownMenuItem(value: c, child: Text(Service.categoriaLabel(c), style: const TextStyle(color: AppConfig.colorTexto)))).toList(),
                  onChanged: (v) => setDState(() => selectedCat = v!),
                ),
                const SizedBox(height: 8),
                TextField(controller: durCtrl, decoration: const InputDecoration(labelText: 'Duracion (min)'), keyboardType: TextInputType.number, style: const TextStyle(color: AppConfig.colorTexto)),
                const SizedBox(height: 12),
                const Text('Precios', style: TextStyle(color: AppConfig.colorTexto, fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 6),
                Row(children: [
                  Expanded(child: TextField(controller: priceEfectivoCtrl, decoration: const InputDecoration(labelText: 'Efectivo \$', labelStyle: TextStyle(fontSize: 12)), keyboardType: TextInputType.number, style: const TextStyle(color: AppConfig.colorTexto))),
                  const SizedBox(width: 8),
                  Expanded(child: TextField(controller: priceTarjetaCtrl, decoration: const InputDecoration(labelText: 'Tarjeta \$', labelStyle: TextStyle(fontSize: 12)), keyboardType: TextInputType.number, style: const TextStyle(color: AppConfig.colorTexto))),
                ]),
                const SizedBox(height: 6),
                Row(children: [
                  Expanded(child: TextField(controller: descEfectivoCtrl, decoration: const InputDecoration(labelText: 'Desc. efectivo %', labelStyle: TextStyle(fontSize: 12)), keyboardType: TextInputType.number, style: const TextStyle(color: AppConfig.colorTexto))),
                  const SizedBox(width: 8),
                  Expanded(child: TextField(controller: descTarjetaCtrl, decoration: const InputDecoration(labelText: 'Desc. tarjeta %', labelStyle: TextStyle(fontSize: 12)), keyboardType: TextInputType.number, style: const TextStyle(color: AppConfig.colorTexto))),
                ]),
                if (_tenant?.senaHabilitada == true) ...[
                  const SizedBox(height: 8),
                  SwitchListTile(
                    value: requiereSena,
                    onChanged: (v) => setDState(() => requiereSena = v),
                    title: const Text('Requiere seña', style: TextStyle(color: AppConfig.colorTexto, fontSize: 14)),
                    subtitle: Text('${_tenant!.senaPorcentaje}% del precio', style: const TextStyle(color: AppConfig.colorTextoSecundario, fontSize: 12)),
                    activeColor: _accent,
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty) return;
                String? imagenUrl;
                if (imageBytes != null) {
                  imagenUrl = await _svc.uploadImage('services/${DateTime.now().millisecondsSinceEpoch}_$imageName', imageBytes!);
                }
                final precioEf = priceEfectivoCtrl.text.isNotEmpty ? double.tryParse(priceEfectivoCtrl.text) : null;
                await _svc.createService({
                  'nombre': nameCtrl.text.trim(),
                  'categoria': selectedCat,
                  'duracion_minutos': int.tryParse(durCtrl.text) ?? 60,
                  'precio': precioEf,
                  'precio_efectivo': precioEf,
                  'precio_tarjeta': priceTarjetaCtrl.text.isNotEmpty ? double.tryParse(priceTarjetaCtrl.text) : null,
                  'descuento_efectivo_pct': int.tryParse(descEfectivoCtrl.text) ?? 0,
                  'descuento_tarjeta_pct': int.tryParse(descTarjetaCtrl.text) ?? 0,
                  if (imagenUrl != null) 'imagen_url': imagenUrl,
                  'requiere_sena': requiereSena,
                });
                _services = await _svc.loadServices();
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) setState(() {});
              },
              child: const Text('Crear'),
            ),
          ],
        ),
      ),
    );
  }

  void _editServiceDialog(Service s) {
    final nameCtrl = TextEditingController(text: s.nombre);
    final durCtrl = TextEditingController(text: s.duracionMinutos.toString());
    final priceEfectivoCtrl = TextEditingController(text: s.precioEfectivoFinal?.toStringAsFixed(0) ?? '');
    final priceTarjetaCtrl = TextEditingController(text: s.precioTarjetaFinal?.toStringAsFixed(0) ?? '');
    final descEfectivoCtrl = TextEditingController(text: s.descuentoEfectivoPct > 0 ? s.descuentoEfectivoPct.toString() : '');
    final descTarjetaCtrl = TextEditingController(text: s.descuentoTarjetaPct > 0 ? s.descuentoTarjetaPct.toString() : '');
    String selectedCat = s.categoria;
    Uint8List? imageBytes;
    String? imageName;
    String? currentImageUrl = s.imagenUrl;
    bool requiereSena = s.requiereSena;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDState) => AlertDialog(
          backgroundColor: AppConfig.colorFondoCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Editar Servicio', style: TextStyle(color: AppConfig.colorTexto)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () async {
                    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1200, imageQuality: 85);
                    if (picked != null) {
                      final bytes = await picked.readAsBytes();
                      setDState(() { imageBytes = bytes; imageName = picked.name; });
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    height: 120,
                    decoration: BoxDecoration(
                      color: _primary.withAlpha(20),
                      borderRadius: BorderRadius.circular(12),
                      image: imageBytes != null
                          ? DecorationImage(image: MemoryImage(imageBytes!), fit: BoxFit.cover)
                          : (currentImageUrl != null ? DecorationImage(image: NetworkImage(currentImageUrl!), fit: BoxFit.cover) : null),
                    ),
                    child: (imageBytes == null && currentImageUrl == null)
                        ? Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Icon(Icons.add_photo_alternate, color: _primary, size: 32),
                            const SizedBox(height: 4),
                            Text('Agregar imagen', style: TextStyle(color: _primary, fontSize: 12)),
                          ])
                        : null,
                  ),
                ),
                if (currentImageUrl != null && imageBytes == null)
                  TextButton(
                    onPressed: () => setDState(() => currentImageUrl = null),
                    child: const Text('Quitar imagen', style: TextStyle(color: Colors.redAccent, fontSize: 12)),
                  ),
                const SizedBox(height: 12),
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nombre'), style: const TextStyle(color: AppConfig.colorTexto)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: selectedCat,
                  decoration: const InputDecoration(labelText: 'Categoria'),
                  dropdownColor: AppConfig.colorFondoCard,
                  items: Service.categorias.map((c) => DropdownMenuItem(value: c, child: Text(Service.categoriaLabel(c), style: const TextStyle(color: AppConfig.colorTexto)))).toList(),
                  onChanged: (v) => setDState(() => selectedCat = v!),
                ),
                const SizedBox(height: 8),
                TextField(controller: durCtrl, decoration: const InputDecoration(labelText: 'Duracion (min)'), keyboardType: TextInputType.number, style: const TextStyle(color: AppConfig.colorTexto)),
                const SizedBox(height: 12),
                const Text('Precios', style: TextStyle(color: AppConfig.colorTexto, fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 6),
                Row(children: [
                  Expanded(child: TextField(controller: priceEfectivoCtrl, decoration: const InputDecoration(labelText: 'Efectivo \$', labelStyle: TextStyle(fontSize: 12)), keyboardType: TextInputType.number, style: const TextStyle(color: AppConfig.colorTexto))),
                  const SizedBox(width: 8),
                  Expanded(child: TextField(controller: priceTarjetaCtrl, decoration: const InputDecoration(labelText: 'Tarjeta \$', labelStyle: TextStyle(fontSize: 12)), keyboardType: TextInputType.number, style: const TextStyle(color: AppConfig.colorTexto))),
                ]),
                const SizedBox(height: 6),
                Row(children: [
                  Expanded(child: TextField(controller: descEfectivoCtrl, decoration: const InputDecoration(labelText: 'Desc. efectivo %', labelStyle: TextStyle(fontSize: 12)), keyboardType: TextInputType.number, style: const TextStyle(color: AppConfig.colorTexto))),
                  const SizedBox(width: 8),
                  Expanded(child: TextField(controller: descTarjetaCtrl, decoration: const InputDecoration(labelText: 'Desc. tarjeta %', labelStyle: TextStyle(fontSize: 12)), keyboardType: TextInputType.number, style: const TextStyle(color: AppConfig.colorTexto))),
                ]),
                if (_tenant?.senaHabilitada == true) ...[
                  const SizedBox(height: 8),
                  SwitchListTile(
                    value: requiereSena,
                    onChanged: (v) => setDState(() => requiereSena = v),
                    title: const Text('Requiere seña', style: TextStyle(color: AppConfig.colorTexto, fontSize: 14)),
                    subtitle: Text('${_tenant!.senaPorcentaje}% del precio', style: const TextStyle(color: AppConfig.colorTextoSecundario, fontSize: 12)),
                    activeColor: _accent,
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty) return;
                String? imagenUrl = currentImageUrl;
                if (imageBytes != null) {
                  imagenUrl = await _svc.uploadImage('services/${DateTime.now().millisecondsSinceEpoch}_$imageName', imageBytes!);
                }
                final precioEf = priceEfectivoCtrl.text.isNotEmpty ? double.tryParse(priceEfectivoCtrl.text) : null;
                await _svc.updateService(s.id, {
                  'nombre': nameCtrl.text.trim(),
                  'categoria': selectedCat,
                  'duracion_minutos': int.tryParse(durCtrl.text) ?? 60,
                  'precio': precioEf,
                  'precio_efectivo': precioEf,
                  'precio_tarjeta': priceTarjetaCtrl.text.isNotEmpty ? double.tryParse(priceTarjetaCtrl.text) : null,
                  'descuento_efectivo_pct': int.tryParse(descEfectivoCtrl.text) ?? 0,
                  'descuento_tarjeta_pct': int.tryParse(descTarjetaCtrl.text) ?? 0,
                  'imagen_url': imagenUrl,
                  'requiere_sena': requiereSena,
                });
                _services = await _svc.loadServices();
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) setState(() {});
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  // ==== TAB 3: HORARIOS ====
  Widget _buildHoursTab() {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _tabHint('🕐', 'Configura los dias y horarios que tu salon esta abierto. Pone hora de inicio, fin y cada cuantos minutos queres los turnos.'),
        for (int day = 1; day <= 6; day++) ...[
          _hoursDayRow(day),
        ],
        _hoursDayRow(0), // Domingo
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: _editHoursDialog,
          icon: const Icon(Icons.edit),
          label: const Text('Editar Horarios'),
        ),
      ],
    );
  }

  Widget _hoursDayRow(int day) {
    final dayHours = _hours.where((h) => h.diaSemana == day).toList();
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: dayHours.isNotEmpty ? _primary.withAlpha(30) : Colors.white.withAlpha(10),
          child: Text(OperatingHours.dayShort(day), style: TextStyle(fontSize: 12, color: dayHours.isNotEmpty ? _primary : AppConfig.colorTextoSecundario)),
        ),
        title: Text(OperatingHours.dayName(day), style: const TextStyle(color: AppConfig.colorTexto)),
        subtitle: dayHours.isNotEmpty
            ? Text(dayHours.map((h) => '${h.horaInicio} - ${h.horaFin}').join(', '), style: const TextStyle(color: AppConfig.colorTextoSecundario, fontSize: 12))
            : const Text('Cerrado', style: TextStyle(color: Colors.redAccent, fontSize: 12)),
      ),
    );
  }

  void _editHoursDialog() {
    // Simple hours editor - sets same hours for all open days
    final startCtrl = TextEditingController(text: '09:00');
    final endCtrl = TextEditingController(text: '18:00');
    final intervalCtrl = TextEditingController(text: '30');
    final openDays = <int>{1, 2, 3, 4, 5, 6}; // Lun-Sab

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDState) => AlertDialog(
          backgroundColor: AppConfig.colorFondoCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Editar Horarios', style: TextStyle(color: AppConfig.colorTexto)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: startCtrl, decoration: const InputDecoration(labelText: 'Hora inicio (HH:MM)'), style: const TextStyle(color: AppConfig.colorTexto)),
                const SizedBox(height: 8),
                TextField(controller: endCtrl, decoration: const InputDecoration(labelText: 'Hora fin (HH:MM)'), style: const TextStyle(color: AppConfig.colorTexto)),
                const SizedBox(height: 8),
                TextField(controller: intervalCtrl, decoration: const InputDecoration(labelText: 'Intervalo (min)'), keyboardType: TextInputType.number, style: const TextStyle(color: AppConfig.colorTexto)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  children: [for (int d = 0; d <= 6; d++)
                    FilterChip(
                      label: Text(OperatingHours.dayShort(d)),
                      selected: openDays.contains(d),
                      selectedColor: _primary.withAlpha(60),
                      onSelected: (v) => setDState(() => v ? openDays.add(d) : openDays.remove(d)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () async {
                final hours = <Map<String, dynamic>>[];
                for (final day in openDays) {
                  hours.add({
                    'dia_semana': day,
                    'hora_inicio': startCtrl.text.trim(),
                    'hora_fin': endCtrl.text.trim(),
                    'intervalo_minutos': int.tryParse(intervalCtrl.text) ?? 30,
                  });
                }
                await _svc.setOperatingHours(hours);
                _hours = await _svc.loadOperatingHours();
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) setState(() {});
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  // ==== TAB 4: BLOQUEOS ====
  Widget _buildBlocksTab() {
    return Column(
      children: [
        _tabHint('🚫', '¿Necesitás cerrar un día por feriado o vacaciones? ¿O cerrar una hora específica? Agregá un bloqueo y tus clientas no podrán sacar turno en ese momento.'),
        Padding(
          padding: const EdgeInsets.all(12),
          child: ElevatedButton.icon(
            onPressed: _addBlockDialog,
            icon: const Icon(Icons.event_busy),
            label: const Text('Cerrar un dia u hora'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent.withAlpha(180),
              foregroundColor: Colors.white,
            ),
          ),
        ),
        Expanded(
          child: _blocks.isEmpty
              ? const Center(child: Text('Sin bloqueos', style: TextStyle(color: AppConfig.colorTextoSecundario)))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: _blocks.length,
                  itemBuilder: (_, i) {
                    final b = _blocks[i];
                    return Card(
                      child: ListTile(
                        leading: Icon(b.diaCompleto ? Icons.calendar_today : Icons.access_time, color: Colors.redAccent),
                        title: Text(
                          b.diaCompleto ? 'Dia completo - ${b.fecha ?? ''}' : '${b.fecha ?? ''} ${b.hora ?? ''}',
                          style: const TextStyle(color: AppConfig.colorTexto),
                        ),
                        subtitle: Text(b.motivo, style: const TextStyle(color: AppConfig.colorTextoSecundario, fontSize: 12)),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.redAccent, size: 20),
                          onPressed: () async {
                            await _svc.deleteBlock(b.id);
                            _blocks = await _svc.loadBlocks();
                            setState(() {});
                          },
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _addBlockDialog() {
    DateTime? blockDate;
    String? blockHour;
    bool fullDay = false;
    final motivoCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDState) => AlertDialog(
          backgroundColor: AppConfig.colorFondoCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Nuevo Bloqueo', style: TextStyle(color: AppConfig.colorTexto)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(blockDate != null ? '${blockDate!.day}/${blockDate!.month}/${blockDate!.year}' : 'Seleccionar fecha', style: const TextStyle(color: AppConfig.colorTexto)),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final d = await showDatePicker(
                    context: ctx,
                    locale: const Locale('es', ''),
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (d != null) setDState(() => blockDate = d);
                },
              ),
              SwitchListTile(
                title: const Text('Dia completo', style: TextStyle(color: AppConfig.colorTexto)),
                value: fullDay,
                activeColor: _primary,
                onChanged: (v) => setDState(() => fullDay = v),
              ),
              if (!fullDay)
                TextField(
                  decoration: const InputDecoration(labelText: 'Hora (HH:MM)'),
                  style: const TextStyle(color: AppConfig.colorTexto),
                  onChanged: (v) => blockHour = v,
                ),
              const SizedBox(height: 8),
              TextField(controller: motivoCtrl, decoration: const InputDecoration(labelText: 'Motivo'), style: const TextStyle(color: AppConfig.colorTexto)),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () async {
                if (blockDate == null) return;
                final dateStr = '${blockDate!.year}-${blockDate!.month.toString().padLeft(2, '0')}-${blockDate!.day.toString().padLeft(2, '0')}';
                await _svc.createBlock({
                  'fecha': dateStr,
                  'hora': fullDay ? null : blockHour,
                  'dia_completo': fullDay,
                  'motivo': motivoCtrl.text.trim(),
                });
                _blocks = await _svc.loadBlocks();
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) setState(() {});
              },
              child: const Text('Crear'),
            ),
          ],
        ),
      ),
    );
  }

  // ==== TAB 5: LISTA DE ESPERA ====
  Widget _buildWaitlistTab() {
    return Column(
      children: [
        _tabHint('⏳', 'Cuando no hay turnos disponibles, tus clientas se pueden anotar en la lista de espera. Vos les podes avisar por WhatsApp cuando se libere un lugar.'),
        Expanded(child: _waitlist.isEmpty
        ? const Center(child: Text('Todavia nadie se anoto en la lista de espera', style: TextStyle(color: AppConfig.colorTextoSecundario)))
        : ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: _waitlist.length,
            itemBuilder: (_, i) {
              final w = _waitlist[i];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _primary.withAlpha(30),
                    child: Text(w.nombre[0], style: TextStyle(color: _primary)),
                  ),
                  title: Text(w.nombre, style: const TextStyle(color: AppConfig.colorTexto)),
                  subtitle: Text('${w.fecha} - ${w.telefono}', style: const TextStyle(color: AppConfig.colorTextoSecundario, fontSize: 12)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chat, color: Color(0xFF25D366), size: 20),
                        onPressed: () => WhatsappService.openChat(
                          phone: w.telefono,
                          countryCode: _tenant?.codigoPaisTelefono ?? '54',
                          message: 'Hola ${w.nombre}! Se libero un turno en ${_tenant?.nombreSalon ?? 'nuestro salon'}. Reservalo ahora!',
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.redAccent, size: 20),
                        onPressed: () async {
                          await _svc.deleteWaitlistEntry(w.id);
                          _waitlist = await _svc.loadWaitlist();
                          setState(() {});
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ==== ONBOARDING SCREEN ====
  Widget _buildOnboardingScreen() {
    final nombreCtrl = TextEditingController(text: _tenant!.nombreSalon);
    final subtituloCtrl = TextEditingController(text: _tenant!.subtitulo);
    final direccionCtrl = TextEditingController(text: _tenant!.direccion);
    final ciudadCtrl = TextEditingController(text: _tenant!.ciudad);
    final provinciaCtrl = TextEditingController(text: _tenant!.provincia);
    final emailCtrl = TextEditingController(text: _tenant!.emailContacto);
    final telefonoCtrl = TextEditingController(text: _tenant!.telefonoContacto);
    final whatsappCtrl = TextEditingController(text: _tenant!.whatsappNumero);
    final sloganCtrl = TextEditingController(text: _tenant!.slogan);
    final anticipacionCtrl = TextEditingController(text: _tenant!.minAnticipacionHoras.toString());
    final maxDiasCtrl = TextEditingController(text: _tenant!.maxAnticipacionDias.toString());
    final autoReleaseCtrl = TextEditingController(text: _tenant!.minutosAutoLiberacion.toString());
    final confirmacionCtrl = TextEditingController(text: _tenant!.ventanaConfirmacionHoras.toString());
    final recordatorioCtrl = TextEditingController(text: _tenant!.recordatorioHorasAntes.toString());
    bool saving = false;

    // Imágenes
    Uint8List? logoBytes;
    String? logoName;
    Uint8List? logoBlancoBytes;
    String? logoBlancoName;
    Uint8List? fondoBytes;
    String? fondoName;

    // Colores
    Color colorPrimario = AppConfig.hexToColor(_tenant!.colorPrimario);
    Color colorSecundario = AppConfig.hexToColor(_tenant!.colorSecundario);
    Color colorTerciario = AppConfig.hexToColor(_tenant!.colorTerciario);
    Color colorAcento = AppConfig.hexToColor(_tenant!.colorAcento);

    int diaCerrado = _tenant!.diaCerrado;

    String _colorToHex(Color c) {
      return '#${c.value.toRadixString(16).substring(2)}';
    }

    Future<void> _pickColor(BuildContext ctx, void Function(void Function()) setLocal, Color current, String label, void Function(Color) onPicked) async {
      Color picked = current;
      await showDialog(
        context: ctx,
        builder: (dCtx) => AlertDialog(
          backgroundColor: AppConfig.colorFondoCard,
          title: Text(label, style: const TextStyle(color: AppConfig.colorTexto)),
          content: SingleChildScrollView(
            child: ColorPicker(
              color: current,
              onColorChanged: (c) => picked = c,
              heading: Text('Elige un color', style: TextStyle(color: AppConfig.colorTextoSecundario)),
              subheading: Text('Tono', style: TextStyle(color: AppConfig.colorTextoSecundario)),
              pickersEnabled: const <ColorPickerType, bool>{
                ColorPickerType.wheel: true,
                ColorPickerType.accent: false,
                ColorPickerType.primary: false,
              },
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dCtx), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () { onPicked(picked); Navigator.pop(dCtx); },
              child: const Text('Aceptar'),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppConfig.colorFondoOscuro,
      appBar: AppBar(
        title: const Text('Configuracion inicial'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _svc.signOut();
              if (mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const AdminLoginScreen()),
                );
              }
            },
          ),
        ],
      ),
      body: StatefulBuilder(
        builder: (ctx, setLocalState) => SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // === HEADER ===
              Center(
                child: Text(
                  'Bienvenido a ${_tenant!.nombreSalon.isNotEmpty ? _tenant!.nombreSalon : "tu salon"}',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: _primary),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 8),
              const Center(
                child: Text(
                  'Completa los datos de tu salon para empezar',
                  style: TextStyle(fontSize: 14, color: AppConfig.colorTextoSecundario),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 28),

              // === SECCION 1: IMAGENES ===
              _onboardingSection('IMAGENES DE TU SALON', Icons.image),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _imageUploadBox(
                    label: 'Logo color',
                    bytes: logoBytes,
                    onTap: () async {
                      final picked = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 800, imageQuality: 85);
                      if (picked != null) {
                        final bytes = await picked.readAsBytes();
                        setLocalState(() { logoBytes = bytes; logoName = picked.name; });
                      }
                    },
                  ),
                  _imageUploadBox(
                    label: 'Logo blanco',
                    bytes: logoBlancoBytes,
                    onTap: () async {
                      final picked = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 800, imageQuality: 85);
                      if (picked != null) {
                        final bytes = await picked.readAsBytes();
                        setLocalState(() { logoBlancoBytes = bytes; logoBlancoName = picked.name; });
                      }
                    },
                  ),
                  _imageUploadBox(
                    label: 'Fondo',
                    bytes: fondoBytes,
                    onTap: () async {
                      final picked = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1200, imageQuality: 85);
                      if (picked != null) {
                        final bytes = await picked.readAsBytes();
                        setLocalState(() { fondoBytes = bytes; fondoName = picked.name; });
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Toca cada cuadro para subir una imagen. PNG para logos, JPG para fondo.',
                  style: TextStyle(fontSize: 11, color: AppConfig.colorTextoSecundario),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24),

              // === SECCION 2: INFO BASICA ===
              _onboardingSection('DATOS DEL SALON', Icons.store),
              const SizedBox(height: 12),
              _editField(nombreCtrl, 'Nombre del salon *', Icons.store),
              _editField(subtituloCtrl, 'Subtitulo (ej: Peluqueria & Estetica)', Icons.short_text),
              _editField(sloganCtrl, 'Slogan', Icons.format_quote),
              _editField(direccionCtrl, 'Direccion', Icons.location_on),
              Row(
                children: [
                  Expanded(child: _editField(ciudadCtrl, 'Ciudad', Icons.location_city)),
                  const SizedBox(width: 10),
                  Expanded(child: _editField(provinciaCtrl, 'Provincia', Icons.map)),
                ],
              ),
              _editField(emailCtrl, 'Email de contacto', Icons.email),
              _editField(telefonoCtrl, 'Telefono', Icons.phone),
              _editField(whatsappCtrl, 'WhatsApp (con codigo de pais)', Icons.chat),
              const SizedBox(height: 24),

              // === SECCION 3: COLORES ===
              _onboardingSection('COLORES DE TU MARCA', Icons.palette),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _onboardingColorButton(ctx, setLocalState, 'Primario', colorPrimario, (c) { colorPrimario = c; }),
                  _onboardingColorButton(ctx, setLocalState, 'Secundario', colorSecundario, (c) { colorSecundario = c; }),
                  _onboardingColorButton(ctx, setLocalState, 'Terciario', colorTerciario, (c) { colorTerciario = c; }),
                  _onboardingColorButton(ctx, setLocalState, 'Acento', colorAcento, (c) { colorAcento = c; }),
                ],
              ),
              const SizedBox(height: 24),

              // === SECCION 4: REGLAS OPERATIVAS ===
              _onboardingSection('REGLAS DE TURNOS', Icons.settings),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _editField(anticipacionCtrl, 'Anticipacion min (hs)', Icons.timer, isNumber: true)),
                  const SizedBox(width: 10),
                  Expanded(child: _editField(maxDiasCtrl, 'Dias maximo adelanto', Icons.date_range, isNumber: true)),
                ],
              ),
              Row(
                children: [
                  Expanded(child: _editField(autoReleaseCtrl, 'Auto-release (min)', Icons.timer_off, isNumber: true)),
                  const SizedBox(width: 10),
                  Expanded(child: _editField(confirmacionCtrl, 'Confirmacion (hs)', Icons.check_circle, isNumber: true)),
                ],
              ),
              _editField(recordatorioCtrl, 'Recordatorio antes (hs)', Icons.notifications, isNumber: true),
              const SizedBox(height: 12),
              // Día cerrado
              Row(
                children: [
                  const Icon(Icons.event_busy, size: 18, color: AppConfig.colorTextoSecundario),
                  const SizedBox(width: 10),
                  const Text('Dia cerrado:', style: TextStyle(color: AppConfig.colorTextoSecundario, fontSize: 14)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButton<int>(
                      value: diaCerrado,
                      dropdownColor: AppConfig.colorFondoCard,
                      isExpanded: true,
                      style: const TextStyle(color: AppConfig.colorTexto),
                      items: const [
                        DropdownMenuItem(value: 0, child: Text('Ninguno')),
                        DropdownMenuItem(value: 1, child: Text('Lunes')),
                        DropdownMenuItem(value: 2, child: Text('Martes')),
                        DropdownMenuItem(value: 3, child: Text('Miercoles')),
                        DropdownMenuItem(value: 4, child: Text('Jueves')),
                        DropdownMenuItem(value: 5, child: Text('Viernes')),
                        DropdownMenuItem(value: 6, child: Text('Sabado')),
                        DropdownMenuItem(value: 7, child: Text('Domingo')),
                      ],
                      onChanged: (v) => setLocalState(() => diaCerrado = v ?? 0),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // === BOTON GUARDAR ===
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: saving ? null : () async {
                    if (nombreCtrl.text.trim().isEmpty) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(content: Text('El nombre del salon es obligatorio')),
                      );
                      return;
                    }
                    setLocalState(() => saving = true);
                    try {
                      // Subir imágenes
                      String? logoUrl;
                      String? logoBlancoUrl;
                      String? fondoUrl;
                      final ts = DateTime.now().millisecondsSinceEpoch;
                      if (logoBytes != null) {
                        logoUrl = await _svc.uploadImage('logo_${ts}_$logoName', logoBytes!);
                      }
                      if (logoBlancoBytes != null) {
                        logoBlancoUrl = await _svc.uploadImage('logo_blanco_${ts}_$logoBlancoName', logoBlancoBytes!);
                      }
                      if (fondoBytes != null) {
                        fondoUrl = await _svc.uploadImage('fondo_${ts}_$fondoName', fondoBytes!);
                      }
                      await _svc.updateTenant({
                        'nombre_salon': nombreCtrl.text.trim(),
                        'subtitulo': subtituloCtrl.text.trim(),
                        'slogan': sloganCtrl.text.trim(),
                        'direccion': direccionCtrl.text.trim(),
                        'ciudad': ciudadCtrl.text.trim(),
                        'provincia': provinciaCtrl.text.trim(),
                        'email_contacto': emailCtrl.text.trim(),
                        'telefono_contacto': telefonoCtrl.text.trim(),
                        'whatsapp_numero': whatsappCtrl.text.trim(),
                        if (logoUrl != null) 'logo_url': logoUrl,
                        if (logoBlancoUrl != null) 'logo_blanco_url': logoBlancoUrl,
                        if (fondoUrl != null) 'fondo_url': fondoUrl,
                        'color_primario': _colorToHex(colorPrimario),
                        'color_secundario': _colorToHex(colorSecundario),
                        'color_terciario': _colorToHex(colorTerciario),
                        'color_acento': _colorToHex(colorAcento),
                        'min_anticipacion_horas': int.tryParse(anticipacionCtrl.text) ?? 2,
                        'max_anticipacion_dias': int.tryParse(maxDiasCtrl.text) ?? 60,
                        'minutos_auto_liberacion': int.tryParse(autoReleaseCtrl.text) ?? 15,
                        'ventana_confirmacion_horas': int.tryParse(confirmacionCtrl.text) ?? 2,
                        'recordatorio_horas_antes': int.tryParse(recordatorioCtrl.text) ?? 24,
                        'dia_cerrado': diaCerrado,
                        'onboarding_completed': true,
                      });

                      // Bonus: +5 días de prueba por completar onboarding
                      final wasFirst = !(_tenant?.trialExtended ?? false);
                      if (wasFirst) {
                        final extended = await SupabaseService.instance.extendTrialForOnboarding();
                        if (extended && ctx.mounted) {
                          _showTrialGiftDialog(ctx);
                        }
                      }

                      setState(() => _loading = true);
                      await _loadAll();
                    } catch (e) {
                      if (ctx.mounted) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          SnackBar(content: Text('Error al guardar: $e')),
                        );
                      }
                    } finally {
                      if (ctx.mounted) setLocalState(() => saving = false);
                    }
                  },
                  icon: saving
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.check),
                  label: Text(saving ? 'Guardando...' : 'Completar configuracion'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // Helpers del onboarding
  Widget _onboardingSection(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppConfig.colorAcento),
        const SizedBox(width: 8),
        Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppConfig.colorAcento, letterSpacing: 1)),
      ],
    );
  }

  Widget _imageUploadBox({required String label, Uint8List? bytes, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 90,
        height: 90,
        decoration: BoxDecoration(
          color: _primary.withAlpha(20),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _primary.withAlpha(60)),
          image: bytes != null ? DecorationImage(image: MemoryImage(bytes), fit: BoxFit.cover) : null,
        ),
        child: bytes == null
            ? Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.add_a_photo, size: 24, color: _primary.withAlpha(150)),
                const SizedBox(height: 4),
                Text(label, style: TextStyle(color: _primary, fontSize: 10), textAlign: TextAlign.center),
              ])
            : null,
      ),
    );
  }

  Widget _onboardingColorButton(BuildContext ctx, void Function(void Function()) setLocal, String label, Color color, void Function(Color) onPicked) {
    return GestureDetector(
      onTap: () async {
        Color picked = color;
        await showDialog(
          context: ctx,
          builder: (dCtx) => AlertDialog(
            backgroundColor: AppConfig.colorFondoCard,
            title: Text(label, style: const TextStyle(color: AppConfig.colorTexto)),
            content: SingleChildScrollView(
              child: ColorPicker(
                color: color,
                onColorChanged: (c) => picked = c,
                heading: Text('Elige un color', style: TextStyle(color: AppConfig.colorTextoSecundario)),
                subheading: Text('Tono', style: TextStyle(color: AppConfig.colorTextoSecundario)),
                pickersEnabled: const <ColorPickerType, bool>{
                  ColorPickerType.wheel: true,
                  ColorPickerType.accent: false,
                  ColorPickerType.primary: false,
                },
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dCtx), child: const Text('Cancelar')),
              ElevatedButton(
                onPressed: () { setLocal(() => onPicked(picked)); Navigator.pop(dCtx); },
                child: const Text('Aceptar'),
              ),
            ],
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppConfig.colorFondoCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color, width: 2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 20, height: 20, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(color: AppConfig.colorTexto, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  // ==== TAB 7: SALON (settings) ====
  Widget _buildSalonTab() {
    if (_tenant == null) return const Center(child: Text('Sin datos'));
    return _SalonConfigTab(
      tenant: _tenant!,
      primary: _primary,
      accent: _accent,
      svc: _svc,
      onSaved: () async {
        await _svc.loadTenant();
        setState(() => _tenant = _svc.currentTenant);
      },
      onChangePassword: _promptChangePassword,
      changingPassword: _changingPassword,
    );
  }

  Widget _editField(TextEditingController ctrl, String label, IconData icon, {bool isNumber = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: ctrl,
        style: const TextStyle(color: AppConfig.colorTexto),
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 18),
          isDense: true,
        ),
      ),
    );
  }

  Future<void> _promptChangePassword() async {
    final pass1 = TextEditingController();
    final pass2 = TextEditingController();
    String? error;

    String? validatedValue(String v1, String v2) {
      if (v1.isEmpty || v2.isEmpty) return 'Completa ambos campos';
      if (v1.length < 8) return 'Minimo 8 caracteres';
      if (v1 != v2) return 'Las contraseñas no coinciden';
      return null;
    }

    final newPass = await showDialog<String>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (_, setState) => AlertDialog(
            backgroundColor: AppConfig.colorFondoCard,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Cambiar contraseña', style: TextStyle(color: AppConfig.colorTexto)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: pass1,
                  decoration: const InputDecoration(labelText: 'Nueva contraseña'),
                  obscureText: true,
                  style: const TextStyle(color: AppConfig.colorTexto),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: pass2,
                  decoration: const InputDecoration(labelText: 'Repetir contraseña'),
                  obscureText: true,
                  style: const TextStyle(color: AppConfig.colorTexto),
                ),
                if (error != null) ...[
                  const SizedBox(height: 8),
                  Text(error!, style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
                ]
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
              ElevatedButton(
                onPressed: () {
                  final err = validatedValue(pass1.text.trim(), pass2.text.trim());
                  if (err != null) {
                    setState(() => error = err);
                    return;
                  }
                  Navigator.pop(ctx, pass1.text.trim());
                },
                child: const Text('Guardar'),
              ),
            ],
          ),
        );
      },
    );

    if (newPass == null) return;
    setState(() => _changingPassword = true);
    try {
      await _svc.changePassword(newPass);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Contraseña actualizada')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo cambiar la contraseña')),
        );
      }
    } finally {
      if (mounted) setState(() => _changingPassword = false);
    }
  }
}

// ============================================================
// SALON CONFIG TAB (with image uploads + color pickers)
// ============================================================
class _SalonConfigTab extends StatefulWidget {
  final Tenant tenant;
  final Color primary;
  final Color accent;
  final SupabaseService svc;
  final VoidCallback onSaved;
  final VoidCallback onChangePassword;
  final bool changingPassword;

  const _SalonConfigTab({
    required this.tenant,
    required this.primary,
    required this.accent,
    required this.svc,
    required this.onSaved,
    required this.onChangePassword,
    required this.changingPassword,
  });

  @override
  State<_SalonConfigTab> createState() => _SalonConfigTabState();
}

class _SalonConfigTabState extends State<_SalonConfigTab> {
  late TextEditingController _nombreCtrl;
  late TextEditingController _subtituloCtrl;
  late TextEditingController _sloganCtrl;
  late TextEditingController _direccionCtrl;
  late TextEditingController _ciudadCtrl;
  late TextEditingController _provinciaCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _telefonoCtrl;
  late TextEditingController _whatsappCtrl;
  late TextEditingController _codigoPaisCtrl;
  late TextEditingController _mapsQueryCtrl;
  late TextEditingController _bannerCtrl;

  String? _logoUrl;
  String? _logoBlancoUrl;
  String? _fondoUrl;
  late bool _mostrarNombreSalon;
  late bool _mostrarBanner;
  late String _bannerTipo;
  String _bannerVideoUrl = '';
  late Color _primaryColor;
  late Color _secondaryColor;
  late Color _tertiaryColor;
  late Color _accentColor;
  late Color _cardProfColor;
  late int _minAnticipacion;
  late int _maxAnticipacion;
  late int _autoRelease;
  late int _ventanaConfirmacion;
  late int _recordatorio;
  late int _diaCerrado;
  late bool _senaHabilitada;
  late int _senaPorcentaje;
  late TextEditingController _senaCbuCtrl;
  late TextEditingController _senaAliasCtrl;
  late TextEditingController _senaTitularCtrl;
  // _fondoPaginaUrl eliminado - se usa _fondoUrl para todo
  Color? _colorFondoPagina;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final t = widget.tenant;
    _nombreCtrl = TextEditingController(text: t.nombreSalon);
    _subtituloCtrl = TextEditingController(text: t.subtitulo);
    _sloganCtrl = TextEditingController(text: t.slogan);
    _direccionCtrl = TextEditingController(text: t.direccion);
    _ciudadCtrl = TextEditingController(text: t.ciudad);
    _provinciaCtrl = TextEditingController(text: t.provincia);
    _emailCtrl = TextEditingController(text: t.emailContacto);
    _telefonoCtrl = TextEditingController(text: t.telefonoContacto);
    _whatsappCtrl = TextEditingController(text: t.whatsappNumero);
    _codigoPaisCtrl = TextEditingController(text: t.codigoPaisTelefono);
    _mapsQueryCtrl = TextEditingController(text: t.googleMapsQuery);
    _bannerCtrl = TextEditingController(text: t.bannerTexto);
    _logoUrl = t.logoUrl;
    _logoBlancoUrl = t.logoBlancoUrl;
    _fondoUrl = t.fondoUrl;
    _mostrarNombreSalon = t.mostrarNombreSalon;
    _mostrarBanner = t.mostrarBanner;
    _bannerTipo = t.bannerTipo;
    _bannerVideoUrl = t.bannerVideoUrl;
    _primaryColor = AppConfig.hexToColor(t.colorPrimario);
    _secondaryColor = AppConfig.hexToColor(t.colorSecundario);
    _tertiaryColor = AppConfig.hexToColor(t.colorTerciario);
    _accentColor = AppConfig.hexToColor(t.colorAcento);
    _cardProfColor = t.colorCardProfesional.isNotEmpty
        ? AppConfig.hexToColor(t.colorCardProfesional)
        : AppConfig.colorFondoCard;
    _minAnticipacion = t.minAnticipacionHoras;
    _maxAnticipacion = t.maxAnticipacionDias;
    _autoRelease = t.minutosAutoLiberacion;
    _ventanaConfirmacion = t.ventanaConfirmacionHoras;
    _recordatorio = t.recordatorioHorasAntes;
    _diaCerrado = t.diaCerrado;
    _senaHabilitada = t.senaHabilitada;
    _senaPorcentaje = t.senaPorcentaje > 0 ? t.senaPorcentaje : 30;
    _senaCbuCtrl = TextEditingController(text: t.senaCbu);
    _senaAliasCtrl = TextEditingController(text: t.senaAlias);
    _senaTitularCtrl = TextEditingController(text: t.senaTitular);
    // fondoPaginaUrl eliminado - se usa fondoUrl para todo
    _colorFondoPagina = t.colorFondoPagina.isNotEmpty ? AppConfig.hexToColor(t.colorFondoPagina) : null;
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _subtituloCtrl.dispose();
    _sloganCtrl.dispose();
    _direccionCtrl.dispose();
    _ciudadCtrl.dispose();
    _provinciaCtrl.dispose();
    _emailCtrl.dispose();
    _telefonoCtrl.dispose();
    _whatsappCtrl.dispose();
    _codigoPaisCtrl.dispose();
    _mapsQueryCtrl.dispose();
    _bannerCtrl.dispose();
    _senaCbuCtrl.dispose();
    _senaAliasCtrl.dispose();
    _senaTitularCtrl.dispose();
    super.dispose();
  }

  String _colorToHex(Color c) => '#${c.red.toRadixString(16).padLeft(2, '0')}${c.green.toRadixString(16).padLeft(2, '0')}${c.blue.toRadixString(16).padLeft(2, '0')}'.toUpperCase();

  Future<void> _pickColor(String label, Color current, ValueChanged<Color> onPick) async {
    Color picked = current;
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppConfig.colorFondoCard,
        title: Text(label, style: const TextStyle(color: AppConfig.colorTexto)),
        content: ColorPicker(
          color: current,
          onColorChanged: (c) => picked = c,
          pickersEnabled: const {ColorPickerType.wheel: true},
          width: 36,
          height: 36,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          TextButton(
            onPressed: () { onPick(picked); Navigator.pop(context); },
            child: Text('OK', style: TextStyle(color: widget.accent)),
          ),
        ],
      ),
    );
  }

  Future<void> _pickAndUploadImage(String label, String fileName, ValueChanged<String?> onDone) async {
    try {
      final picked = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1200, imageQuality: 85);
      if (picked == null) return;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Subiendo imagen...'), duration: Duration(seconds: 10)),
        );
      }

      final bytes = await picked.readAsBytes();
      final ts = DateTime.now().millisecondsSinceEpoch;
      final uniqueName = '${ts}_$fileName';
      final url = await widget.svc.uploadImage(uniqueName, Uint8List.fromList(bytes));

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        setState(() => onDone(url));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Imagen subida'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _uploadBannerVideo() async {
    try {
      final picked = await ImagePicker().pickVideo(source: ImageSource.gallery);
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      // Limite 30MB
      if (bytes.length > 30 * 1024 * 1024) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('El video es muy grande. Maximo 30MB.'), backgroundColor: Colors.red),
          );
        }
        return;
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Subiendo video...'), duration: Duration(seconds: 30)),
        );
      }
      final url = await widget.svc.uploadVideo('banner_video.mp4', Uint8List.fromList(bytes));
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        setState(() => _bannerVideoUrl = url);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Video subido!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showTrialGiftDialog(BuildContext ctx) {
    showDialog(
      context: ctx,
      barrierDismissible: false,
      builder: (dlg) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppConfig.colorPrimario.withAlpha(30),
              ),
              child: const Icon(Icons.card_giftcard, color: AppConfig.colorPrimario, size: 48),
            ),
            const SizedBox(height: 20),
            const Text(
              'Te ganaste 5 dias mas!',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF1A1A1A), fontSize: 22, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            const Text(
              'Por completar tu configuracion, Programacion JJ te regala 5 dias extra de prueba.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF666666), fontSize: 15, height: 1.5),
            ),
            const SizedBox(height: 8),
            const Text(
              'En total tenes 20 dias para probar el sistema.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppConfig.colorPrimario, fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(dlg),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConfig.colorPrimario,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Genial, gracias!', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await widget.svc.updateTenant({
        'nombre_salon': _nombreCtrl.text.trim(),
        'subtitulo': _subtituloCtrl.text.trim(),
        'slogan': _sloganCtrl.text.trim(),
        'direccion': _direccionCtrl.text.trim(),
        'ciudad': _ciudadCtrl.text.trim(),
        'provincia': _provinciaCtrl.text.trim(),
        'email_contacto': _emailCtrl.text.trim(),
        'telefono_contacto': _telefonoCtrl.text.trim(),
        'whatsapp_numero': _whatsappCtrl.text.trim(),
        'codigo_pais_telefono': _codigoPaisCtrl.text.trim(),
        'google_maps_query': _mapsQueryCtrl.text.trim(),
        'banner_texto': _mostrarBanner ? _bannerCtrl.text.trim() : '',
        'mostrar_banner': _mostrarBanner,
        'banner_tipo': _bannerTipo,
        'banner_video_url': _bannerVideoUrl,
        'logo_url': _logoUrl,
        'logo_blanco_url': _logoBlancoUrl,
        'fondo_url': _fondoUrl,
        'mostrar_nombre_salon': _mostrarNombreSalon,
        'color_primario': _colorToHex(_primaryColor),
        'color_secundario': _colorToHex(_secondaryColor),
        'color_terciario': _colorToHex(_tertiaryColor),
        'color_acento': _colorToHex(_accentColor),
        'color_card_profesional': _colorToHex(_cardProfColor),
        'min_anticipacion_horas': _minAnticipacion,
        'max_anticipacion_dias': _maxAnticipacion,
        'minutos_auto_liberacion': _autoRelease,
        'ventana_confirmacion_horas': _ventanaConfirmacion,
        'recordatorio_horas_antes': _recordatorio,
        'dia_cerrado': _diaCerrado,
        'sena_habilitada': _senaHabilitada,
        'sena_porcentaje': _senaHabilitada ? _senaPorcentaje : 0,
        'sena_cbu': _senaCbuCtrl.text.trim(),
        'sena_alias': _senaAliasCtrl.text.trim(),
        'sena_titular': _senaTitularCtrl.text.trim(),
        'color_fondo_pagina': _colorFondoPagina != null ? _colorToHex(_colorFondoPagina!) : '',
        'onboarding_completed': true,
      });

      // Bonus: +5 días de prueba por completar onboarding
      final extended = await SupabaseService.instance.extendTrialForOnboarding();

      widget.onSaved();
      if (mounted) {
        if (extended) {
          _showTrialGiftDialog(context);
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('Configuracion guardada'), backgroundColor: widget.accent),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _sectionTitle('Informacion Basica'),
        _textField('Nombre del salon', _nombreCtrl),
        _textField('Subtitulo', _subtituloCtrl),
        _textField('Slogan', _sloganCtrl),
        _textField('Direccion', _direccionCtrl),
        Row(children: [
          Expanded(child: _textField('Ciudad', _ciudadCtrl)),
          const SizedBox(width: 8),
          Expanded(child: _textField('Provincia', _provinciaCtrl)),
        ]),
        Row(children: [
          SizedBox(width: 80, child: _textField('Cod. Pais', _codigoPaisCtrl)),
          const SizedBox(width: 8),
          Expanded(child: _textField('Telefono', _telefonoCtrl)),
        ]),
        _textField('WhatsApp', _whatsappCtrl),
        _textField('Email', _emailCtrl),
        _textField('Google Maps query', _mapsQueryCtrl),

        const SizedBox(height: 24),
        _sectionTitle('Aviso en tu pagina'),
        Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppConfig.colorPrimario.withAlpha(10),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppConfig.colorPrimario.withAlpha(30)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Escribi un mensaje y tus clientas lo van a ver en la pagina principal de tu salon. Por ejemplo: "Este mes 20% off en coloracion!" o "Nuevos horarios de atencion".',
                style: TextStyle(color: AppConfig.colorTerciario, fontSize: 12, height: 1.4),
              ),
              const SizedBox(height: 8),
              const Text(
                'Si lo dejas vacio, no se muestra nada.',
                style: TextStyle(color: AppConfig.colorTextoSecundario, fontSize: 11),
              ),
            ],
          ),
        ),
        SwitchListTile(
          title: const Text('Mostrar aviso en el home', style: TextStyle(color: Colors.white, fontSize: 14)),
          subtitle: const Text('Activa esto para mostrar un cartel con un mensaje en tu pagina (ej: descuentos, promos, avisos)', style: TextStyle(color: AppConfig.colorTextoSecundario, fontSize: 12)),
          value: _mostrarBanner,
          onChanged: (v) => setState(() => _mostrarBanner = v),
          activeColor: widget.primary,
        ),
        if (_mostrarBanner) ...[
          const SizedBox(height: 8),
          const Text('Tipo de aviso', style: TextStyle(color: Colors.white, fontSize: 13)),
          const SizedBox(height: 6),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'texto', label: Text('Texto', style: TextStyle(fontSize: 12))),
              ButtonSegment(value: 'video', label: Text('Video', style: TextStyle(fontSize: 12))),
              ButtonSegment(value: 'ambos', label: Text('Ambos', style: TextStyle(fontSize: 12))),
            ],
            selected: {_bannerTipo},
            onSelectionChanged: (v) => setState(() => _bannerTipo = v.first),
          ),
          const SizedBox(height: 8),
          if (_bannerTipo == 'texto' || _bannerTipo == 'ambos')
            _textField('Texto del aviso (ej: "20% OFF en alisados este mes!")', _bannerCtrl),
          if (_bannerTipo == 'video' || _bannerTipo == 'ambos') ...[
            const SizedBox(height: 8),
            if (_bannerVideoUrl.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppConfig.colorSurfaceVariant,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.videocam, color: Colors.green, size: 20),
                    const SizedBox(width: 8),
                    const Expanded(child: Text('Video cargado', style: TextStyle(color: Colors.white, fontSize: 13))),
                    TextButton(
                      onPressed: () => setState(() => _bannerVideoUrl = ''),
                      child: const Text('Quitar', style: TextStyle(color: Colors.redAccent, fontSize: 12)),
                    ),
                  ],
                ),
              ),
            if (_bannerVideoUrl.isEmpty)
              ElevatedButton.icon(
                onPressed: _uploadBannerVideo,
                icon: const Icon(Icons.video_library, size: 18),
                label: const Text('Subir video MP4 (max 30MB)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.primary,
                  foregroundColor: Colors.white,
                ),
              ),
          ],
        ],

        const SizedBox(height: 24),
        _sectionTitle('Imagenes'),
        _imageUploadField('Logo color', _logoUrl, 'logo_color.png', (url) => _logoUrl = url),
        _imageUploadField('Logo blanco', _logoBlancoUrl, 'logo_blanco.png', (url) => _logoBlancoUrl = url),
        const SizedBox(height: 12),
        SwitchListTile(
          title: const Text('Mostrar nombre del salon debajo del logo', style: TextStyle(color: Colors.white, fontSize: 14)),
          subtitle: const Text('Desactivalo si tu logo ya incluye el nombre', style: TextStyle(color: AppConfig.colorTextoSecundario, fontSize: 12)),
          value: _mostrarNombreSalon,
          onChanged: (v) => setState(() => _mostrarNombreSalon = v),
          activeColor: widget.primary,
        ),
        const SizedBox(height: 24),
        _sectionTitle('Fondo de tu Pagina'),
        Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: widget.accent.withAlpha(10),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: widget.accent.withAlpha(30)),
          ),
          child: const Text(
            'Elegí como se ve el fondo de toda tu pagina publica.\nPodes subir una foto o elegir un color.\nSi no elegis nada, se usa un degradado suave con tus colores de marca.',
            style: TextStyle(color: AppConfig.colorTextoSecundario, fontSize: 12, height: 1.4),
          ),
        ),
        _imageUploadField(
          'Foto de fondo',
          _fondoUrl,
          'fondo.jpg',
          (url) => _fondoUrl = url,
        ),
        if (_fondoUrl == null || _fondoUrl!.isEmpty) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Text('O elegí un color de fondo: ', style: TextStyle(color: Colors.white.withAlpha(150), fontSize: 13)),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _pickColor(
                  'Color de fondo',
                  _colorFondoPagina ?? Colors.white,
                  (c) => setState(() => _colorFondoPagina = c),
                ),
                child: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: _colorFondoPagina ?? Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withAlpha(80), width: 2),
                  ),
                  child: _colorFondoPagina == null
                      ? Icon(Icons.add, color: Colors.grey[400], size: 20)
                      : null,
                ),
              ),
              if (_colorFondoPagina != null) ...[
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => setState(() => _colorFondoPagina = null),
                  icon: const Icon(Icons.close, size: 18, color: Colors.redAccent),
                  tooltip: 'Quitar color',
                ),
              ],
            ],
          ),
        ],

        const SizedBox(height: 24),
        _sectionTitle('Colores de Marca'),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _colorButton('Primario', _primaryColor, (c) => setState(() => _primaryColor = c)),
            _colorButton('Secundario', _secondaryColor, (c) => setState(() => _secondaryColor = c)),
            _colorButton('Terciario', _tertiaryColor, (c) => setState(() => _tertiaryColor = c)),
            _colorButton('Botones', _accentColor, (c) => setState(() => _accentColor = c)),
            _colorButton('Card Prof.', _cardProfColor, (c) => setState(() => _cardProfColor = c)),
          ],
        ),

        const SizedBox(height: 24),
        _sectionTitle('Reglas de Turnos'),
        Row(children: [
          Expanded(child: _numberField('Min anticipacion (hs)', _minAnticipacion, (v) => setState(() => _minAnticipacion = v))),
          const SizedBox(width: 8),
          Expanded(child: _numberField('Max anticipacion (dias)', _maxAnticipacion, (v) => setState(() => _maxAnticipacion = v))),
        ]),
        _numberField('Auto-liberacion (min)', _autoRelease, (v) => setState(() => _autoRelease = v)),
        _numberField('Ventana confirmacion (hs)', _ventanaConfirmacion, (v) => setState(() => _ventanaConfirmacion = v)),
        _numberField('Recordatorio antes (hs)', _recordatorio, (v) => setState(() => _recordatorio = v)),
        _dropdownField('Dia cerrado', _diaCerrado, {
          0: 'Ninguno', 1: 'Lunes', 2: 'Martes', 3: 'Miercoles',
          4: 'Jueves', 5: 'Viernes', 6: 'Sabado', 7: 'Domingo',
        }, (v) => setState(() => _diaCerrado = v!)),

        const SizedBox(height: 24),
        _sectionTitle('Seña / Pago Anticipado'),
        Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppConfig.colorPendiente.withAlpha(10),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppConfig.colorPendiente.withAlpha(30)),
          ),
          child: const Text(
            'Pedí una seña o pago anticipado a tus clientas antes de confirmar el turno. Ellas verán los datos bancarios y podrán enviarte el comprobante por WhatsApp.',
            style: TextStyle(color: AppConfig.colorTextoSecundario, fontSize: 12, height: 1.4),
          ),
        ),
        SwitchListTile(
          value: _senaHabilitada,
          onChanged: (v) => setState(() => _senaHabilitada = v),
          title: const Text('Pedir seña para reservar', style: TextStyle(color: AppConfig.colorTexto, fontSize: 14)),
          subtitle: Text(
            _senaHabilitada ? 'Activa la seña en cada servicio desde la pestaña Servicios' : 'Desactivado',
            style: const TextStyle(color: AppConfig.colorTextoSecundario, fontSize: 12),
          ),
          activeColor: widget.accent,
          contentPadding: EdgeInsets.zero,
        ),
        if (_senaHabilitada) ...[
          _numberField('Porcentaje (%)', _senaPorcentaje, (v) {
            if (v >= 1 && v <= 100) setState(() => _senaPorcentaje = v);
          }),
          _textField('CBU', _senaCbuCtrl),
          _textField('Alias', _senaAliasCtrl),
          _textField('Titular de la cuenta', _senaTitularCtrl),
        ],

        const SizedBox(height: 32),
        ElevatedButton.icon(
          onPressed: _saving ? null : _save,
          icon: _saving
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.save),
          label: Text(_saving ? 'Guardando...' : 'Guardar Configuracion'),
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.accent,
            foregroundColor: AppConfig.colorFondoOscuro,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: TextButton.icon(
            onPressed: () => WhatsappService.openSupport(),
            icon: const Icon(Icons.support_agent, size: 18),
            label: const Text('Soporte tecnico'),
            style: TextButton.styleFrom(foregroundColor: AppConfig.colorTextoSecundario),
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 4),
      child: Text(title, style: TextStyle(color: widget.accent, fontSize: 16, fontWeight: FontWeight.w600)),
    );
  }

  Widget _textField(String label, TextEditingController ctrl) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: ctrl,
        style: const TextStyle(color: AppConfig.colorTexto),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.white.withAlpha(150)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.white.withAlpha(50)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: widget.accent),
          ),
          filled: true,
          fillColor: Colors.white.withAlpha(13),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    );
  }

  Widget _imageUploadField(String label, String? currentUrl, String fileName, ValueChanged<String?> onChanged) {
    final hasImage = currentUrl != null && currentUrl.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: Colors.white.withAlpha(180), fontSize: 13)),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(20),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white.withAlpha(50)),
                ),
                child: hasImage
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(currentUrl!, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, color: Colors.white38)),
                      )
                    : const Icon(Icons.image_outlined, color: Colors.white24, size: 32),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _pickAndUploadImage(label, fileName, onChanged),
                      icon: const Icon(Icons.upload, size: 18),
                      label: Text(hasImage ? 'Cambiar imagen' : 'Subir imagen'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.accent,
                        foregroundColor: AppConfig.colorFondoOscuro,
                        minimumSize: const Size(double.infinity, 40),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    if (hasImage) ...[
                      const SizedBox(height: 4),
                      TextButton.icon(
                        onPressed: () => setState(() => onChanged(null)),
                        icon: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
                        label: const Text('Quitar', style: TextStyle(color: Colors.red, fontSize: 12)),
                        style: TextButton.styleFrom(minimumSize: Size.zero, padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4)),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _colorButton(String label, Color color, ValueChanged<Color> onPick) {
    return GestureDetector(
      onTap: () => _pickColor(label, color, onPick),
      child: Column(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withAlpha(80), width: 2),
              boxShadow: [BoxShadow(color: color.withAlpha(80), blurRadius: 8)],
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: Colors.white.withAlpha(150), fontSize: 10)),
        ],
      ),
    );
  }

  Widget _numberField(String label, int value, ValueChanged<int> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(child: Text(label, style: TextStyle(color: Colors.white.withAlpha(180), fontSize: 13))),
          SizedBox(
            width: 80,
            child: TextField(
              controller: TextEditingController(text: '$value'),
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppConfig.colorTexto),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.white.withAlpha(50)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: widget.accent),
                ),
                filled: true,
                fillColor: Colors.white.withAlpha(13),
              ),
              onChanged: (v) {
                final n = int.tryParse(v);
                if (n != null) onChanged(n);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _dropdownField(String label, int value, Map<int, String> options, ValueChanged<int?> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<int>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.white.withAlpha(150)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.white.withAlpha(50)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: widget.accent),
          ),
          filled: true,
          fillColor: Colors.white.withAlpha(13),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
        dropdownColor: AppConfig.colorFondoCard,
        items: options.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value, style: const TextStyle(color: AppConfig.colorTexto)))).toList(),
        onChanged: onChanged,
      ),
    );
  }
}

// ==== Reminders Bottom Sheet ====
class _RemindersSheet extends StatefulWidget {
  final List<Appointment> appointments;
  final String fechaStr;
  final String salonName;
  final Tenant? tenant;
  final Color primary;
  final Color accent;
  final SupabaseService svc;

  const _RemindersSheet({
    required this.appointments,
    required this.fechaStr,
    required this.salonName,
    required this.tenant,
    required this.primary,
    required this.accent,
    required this.svc,
  });

  @override
  State<_RemindersSheet> createState() => _RemindersSheetState();
}

class _RemindersSheetState extends State<_RemindersSheet> {
  late Set<String> _sentIds;

  @override
  void initState() {
    super.initState();
    _sentIds = widget.appointments
        .where((a) => a.recordatorioEnviado)
        .map((a) => a.id)
        .toSet();
  }

  Future<void> _sendReminder(Appointment a) async {
    final tenant = widget.tenant;
    if (tenant == null || tenant.whatsappNumero.isEmpty) return;

    final message = WhatsappService.buildReminderMessage(
      nombreCliente: a.nombreCliente,
      servicio: a.servicioNombre ?? '',
      profesional: a.professionalNombre ?? '',
      fecha: widget.fechaStr,
      hora: a.hora,
      codigo: a.codigoConfirmacion,
      salonName: widget.salonName,
    );

    await WhatsappService.sendMessage(
      phoneNumber: a.telefono,
      message: message,
      countryCode: tenant.codigoPaisTelefono,
    );

    await widget.svc.markReminderSent(a.id);
    if (mounted) {
      setState(() => _sentIds.add(a.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalPending = widget.appointments.where((a) => !_sentIds.contains(a.id)).length;

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (_, scrollCtrl) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              children: [
                Icon(Icons.notifications_active, color: widget.accent, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Recordatorios - ${widget.fechaStr}',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: widget.primary)),
                      Text('$totalPending pendiente${totalPending == 1 ? '' : 's'} de ${widget.appointments.length} turno${widget.appointments.length == 1 ? '' : 's'}',
                          style: const TextStyle(fontSize: 12, color: AppConfig.colorTextoSecundario)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppConfig.colorTextoSecundario),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Colors.white12),
          Expanded(
            child: ListView.builder(
              controller: scrollCtrl,
              padding: const EdgeInsets.all(12),
              itemCount: widget.appointments.length,
              itemBuilder: (_, i) {
                final a = widget.appointments[i];
                final sent = _sentIds.contains(a.id);
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  color: sent ? AppConfig.colorFondoCard.withAlpha(150) : AppConfig.colorFondoCard,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: sent ? Colors.green.withAlpha(40) : widget.accent.withAlpha(30),
                      child: Icon(
                        sent ? Icons.check : Icons.person,
                        color: sent ? Colors.green : widget.accent,
                        size: 20,
                      ),
                    ),
                    title: Text(a.nombreCliente,
                        style: TextStyle(
                          color: AppConfig.colorTexto,
                          fontWeight: FontWeight.w600,
                          decoration: sent ? TextDecoration.lineThrough : null,
                        )),
                    subtitle: Text(
                      '${a.hora} - ${a.servicioNombre ?? ''}\n${a.telefono}',
                      style: const TextStyle(color: AppConfig.colorTextoSecundario, fontSize: 12),
                    ),
                    isThreeLine: true,
                    trailing: sent
                        ? const Icon(Icons.done, color: Colors.green)
                        : IconButton(
                            icon: const Icon(Icons.chat, color: Color(0xFF25D366), size: 28),
                            tooltip: 'Enviar recordatorio por WhatsApp',
                            onPressed: () => _sendReminder(a),
                          ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
