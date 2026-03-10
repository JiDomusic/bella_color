import 'package:flutter/material.dart';
import '../../config/app_config.dart';
import '../../models/tenant.dart';
import '../../models/professional.dart';
import '../../models/service.dart';
import '../../models/appointment.dart';
import '../../models/operating_hours.dart';
import '../../models/block.dart';
import '../../models/waitlist_entry.dart';
import '../../services/supabase_service.dart';
import '../../services/whatsapp_service.dart';
import 'admin_login_screen.dart';

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
  bool _loading = true;

  String _selectedDate = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
    final now = DateTime.now();
    _selectedDate = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    _loadAll();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Color get _primary => _tenant != null ? AppConfig.hexToColor(_tenant!.colorPrimario) : AppConfig.colorPrimario;
  Color get _accent => _tenant != null ? AppConfig.hexToColor(_tenant!.colorAcento) : AppConfig.colorAcento;

  Future<void> _loadAll() async {
    try {
      _tenant = await _svc.loadTenant();
      _professionals = await _svc.loadProfessionals();
      _services = await _svc.loadServices();
      _appointments = await _svc.loadAppointments(fecha: _selectedDate);
      _hours = await _svc.loadOperatingHours();
      _blocks = await _svc.loadBlocks();
      _waitlist = await _svc.loadWaitlist();
    } catch (e) {
      // ignore
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _refreshAppointments() async {
    final appts = await _svc.loadAppointments(fecha: _selectedDate);
    if (mounted) setState(() => _appointments = appts);
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
      appBar: AppBar(
        title: Text(_tenant?.nombreSalon ?? 'Admin'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () { setState(() => _loading = true); _loadAll(); },
          ),
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
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: _accent,
          labelColor: _accent,
          unselectedLabelColor: AppConfig.colorTextoSecundario,
          tabs: const [
            Tab(text: 'Turnos'),
            Tab(text: 'Profesionales'),
            Tab(text: 'Servicios'),
            Tab(text: 'Horarios'),
            Tab(text: 'Bloqueos'),
            Tab(text: 'Espera'),
            Tab(text: 'Salon'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAppointmentsTab(),
          _buildProfessionalsTab(),
          _buildServicesTab(),
          _buildHoursTab(),
          _buildBlocksTab(),
          _buildWaitlistTab(),
          _buildSalonTab(),
        ],
      ),
    );
  }

  // ==== TAB 0: TURNOS ====
  Widget _buildAppointmentsTab() {
    return Column(
      children: [
        // Date selector
        Padding(
          padding: const EdgeInsets.all(12),
          child: GestureDetector(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
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
            Text(a.nombreCliente, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppConfig.colorTexto)),
            Text('${a.servicioNombre ?? ''} ${a.professionalNombre != null ? '- ${a.professionalNombre}' : ''}',
                style: const TextStyle(fontSize: 12, color: AppConfig.colorTextoSecundario)),
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
    _refreshAppointments();
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
        Padding(
          padding: const EdgeInsets.all(12),
          child: ElevatedButton.icon(
            onPressed: _addProfessionalDialog,
            icon: const Icon(Icons.add),
            label: const Text('Agregar Profesional'),
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

  void _addProfessionalDialog() {
    final nameCtrl = TextEditingController();
    final specCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppConfig.colorFondoCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Nuevo Profesional', style: TextStyle(color: AppConfig.colorTexto)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nombre'), style: const TextStyle(color: AppConfig.colorTexto)),
            const SizedBox(height: 8),
            TextField(controller: specCtrl, decoration: const InputDecoration(labelText: 'Especialidad'), style: const TextStyle(color: AppConfig.colorTexto)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty) return;
              await _svc.createProfessional({'nombre': nameCtrl.text.trim(), 'especialidad': specCtrl.text.trim()});
              _professionals = await _svc.loadProfessionals();
              if (context.mounted) { Navigator.pop(context); setState(() {}); }
            },
            child: const Text('Crear'),
          ),
        ],
      ),
    );
  }

  // ==== TAB 2: SERVICIOS ====
  Widget _buildServicesTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: ElevatedButton.icon(
            onPressed: _addServiceDialog,
            icon: const Icon(Icons.add),
            label: const Text('Agregar Servicio'),
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
    final priceCtrl = TextEditingController();
    String selectedCat = 'otro';

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
                const SizedBox(height: 8),
                TextField(controller: priceCtrl, decoration: const InputDecoration(labelText: 'Precio (opcional)'), keyboardType: TextInputType.number, style: const TextStyle(color: AppConfig.colorTexto)),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty) return;
                await _svc.createService({
                  'nombre': nameCtrl.text.trim(),
                  'categoria': selectedCat,
                  'duracion_minutos': int.tryParse(durCtrl.text) ?? 60,
                  'precio': priceCtrl.text.isNotEmpty ? double.tryParse(priceCtrl.text) : null,
                });
                _services = await _svc.loadServices();
                if (context.mounted) { Navigator.pop(context); setState(() {}); }
              },
              child: const Text('Crear'),
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
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
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
                if (context.mounted) { Navigator.pop(context); setState(() {}); }
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
        Padding(
          padding: const EdgeInsets.all(12),
          child: ElevatedButton.icon(
            onPressed: _addBlockDialog,
            icon: const Icon(Icons.block),
            label: const Text('Agregar Bloqueo'),
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
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
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
                if (context.mounted) { Navigator.pop(context); setState(() {}); }
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
    return _waitlist.isEmpty
        ? const Center(child: Text('Lista de espera vacia', style: TextStyle(color: AppConfig.colorTextoSecundario)))
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
          );
  }

  // ==== TAB 6: SALON (settings) ====
  Widget _buildSalonTab() {
    if (_tenant == null) return const Center(child: Text('Sin datos'));
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Logo
        Center(
          child: _tenant!.logoUrl != null
              ? ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.network(_tenant!.logoUrl!, width: 80, height: 80, fit: BoxFit.cover))
              : Container(width: 80, height: 80, decoration: BoxDecoration(color: _primary.withAlpha(30), borderRadius: BorderRadius.circular(16)), child: Icon(Icons.spa, color: _primary, size: 36)),
        ),
        const SizedBox(height: 16),
        _infoRow('Nombre', _tenant!.nombreSalon),
        _infoRow('Subtitulo', _tenant!.subtitulo),
        _infoRow('Slogan', _tenant!.slogan),
        _infoRow('Direccion', _tenant!.direccion),
        _infoRow('Ciudad', '${_tenant!.ciudad}, ${_tenant!.provincia}'),
        _infoRow('Email', _tenant!.emailContacto),
        _infoRow('Telefono', _tenant!.telefonoContacto),
        _infoRow('WhatsApp', _tenant!.whatsappNumero),
        const SizedBox(height: 16),
        Text('Configuracion', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _primary)),
        const SizedBox(height: 8),
        _infoRow('Min anticipacion', '${_tenant!.minAnticipacionHoras} horas'),
        _infoRow('Max anticipacion', '${_tenant!.maxAnticipacionDias} dias'),
        _infoRow('Auto-liberacion', '${_tenant!.minutosAutoLiberacion} min'),
        _infoRow('Ventana confirmacion', '${_tenant!.ventanaConfirmacionHoras} horas'),
        _infoRow('Recordatorio', '${_tenant!.recordatorioHorasAntes} horas antes'),
        const SizedBox(height: 16),
        // WhatsApp support
        Center(
          child: TextButton.icon(
            onPressed: () => WhatsappService.openSupport(),
            icon: const Icon(Icons.support_agent, size: 18),
            label: const Text('Soporte tecnico'),
            style: TextButton.styleFrom(foregroundColor: AppConfig.colorTextoSecundario),
          ),
        ),
      ],
    );
  }

  Widget _infoRow(String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 140, child: Text(label, style: const TextStyle(fontSize: 13, color: AppConfig.colorTextoSecundario))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13, color: AppConfig.colorTexto))),
        ],
      ),
    );
  }
}
