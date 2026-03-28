import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/app_config.dart';
import '../../models/cliente.dart';
import '../../models/cliente_observacion.dart';
import '../../models/appointment.dart';
import '../../services/supabase_service.dart';

class ClientesTab extends StatefulWidget {
  final Color primary;
  final Color accent;

  const ClientesTab({super.key, required this.primary, required this.accent});

  @override
  State<ClientesTab> createState() => _ClientesTabState();
}

class _ClientesTabState extends State<ClientesTab> {
  final _svc = SupabaseService.instance;
  final _searchCtrl = TextEditingController();
  List<Cliente> _clientes = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load({String? busqueda}) async {
    setState(() => _loading = true);
    try {
      _clientes = await _svc.loadClientes(busqueda: busqueda);
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  void _onSearch() {
    final q = _searchCtrl.text.trim();
    _load(busqueda: q.isEmpty ? null : q);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Hint
        Container(
          width: double.infinity,
          margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppConfig.colorPrimario.withAlpha(15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppConfig.colorPrimario.withAlpha(40)),
          ),
          child: Row(
            children: [
              Icon(Icons.person_search, size: 18, color: AppConfig.colorPrimario.withAlpha(180)),
              const SizedBox(width: 8),
              const Expanded(child: Text(
                'Busca clientas por nombre. Toca una para ver su historial y agregar observaciones.',
                style: TextStyle(color: AppConfig.colorTextoSecundario, fontSize: 12),
              )),
            ],
          ),
        ),
        // Barra de busqueda
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Buscar por nombre...',
                    hintStyle: const TextStyle(color: AppConfig.colorTextoSecundario),
                    prefixIcon: const Icon(Icons.search, color: AppConfig.colorTextoSecundario),
                    filled: true,
                    fillColor: AppConfig.colorSurfaceVariant,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  style: const TextStyle(color: AppConfig.colorTexto),
                  onSubmitted: (_) => _onSearch(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _onSearch,
                icon: Icon(Icons.search, color: widget.accent),
              ),
            ],
          ),
        ),
        // Lista
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _clientes.isEmpty
                  ? Center(child: Text(
                      _searchCtrl.text.isEmpty
                          ? 'No hay clientas registradas aun.\nSe crean automaticamente al completar turnos.'
                          : 'No se encontraron resultados.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppConfig.colorTextoSecundario),
                    ))
                  : RefreshIndicator(
                      onRefresh: () => _load(busqueda: _searchCtrl.text.trim().isEmpty ? null : _searchCtrl.text.trim()),
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: _clientes.length,
                        itemBuilder: (_, i) => _clienteCard(_clientes[i]),
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _clienteCard(Cliente c) {
    return Card(
      color: AppConfig.colorFondoCard,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: AppConfig.colorSurfaceVariant.withAlpha(80)),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: widget.primary.withAlpha(40),
          child: Text(
            c.nombre.isNotEmpty ? c.nombre[0].toUpperCase() : '?',
            style: TextStyle(color: widget.primary, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(c.nombre, style: const TextStyle(color: AppConfig.colorTexto, fontWeight: FontWeight.w600)),
        subtitle: Text(c.telefono, style: const TextStyle(color: AppConfig.colorTextoSecundario, fontSize: 12)),
        trailing: Icon(Icons.chevron_right, color: AppConfig.colorTextoSecundario.withAlpha(120)),
        onTap: () => _openClienteDetail(c),
      ),
    );
  }

  void _openClienteDetail(Cliente cliente) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppConfig.colorFondoCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (ctx, scrollCtrl) => _ClienteDetailSheet(
          cliente: cliente,
          primary: widget.primary,
          accent: widget.accent,
          scrollController: scrollCtrl,
          onChanged: () => _load(busqueda: _searchCtrl.text.trim().isEmpty ? null : _searchCtrl.text.trim()),
        ),
      ),
    );
  }
}

// ========== Detalle del cliente (bottom sheet) ==========
class _ClienteDetailSheet extends StatefulWidget {
  final Cliente cliente;
  final Color primary;
  final Color accent;
  final ScrollController scrollController;
  final VoidCallback onChanged;

  const _ClienteDetailSheet({
    required this.cliente,
    required this.primary,
    required this.accent,
    required this.scrollController,
    required this.onChanged,
  });

  @override
  State<_ClienteDetailSheet> createState() => _ClienteDetailSheetState();
}

class _ClienteDetailSheetState extends State<_ClienteDetailSheet> {
  final _svc = SupabaseService.instance;
  List<ClienteObservacion> _observaciones = [];
  List<Appointment> _turnos = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      _observaciones = await _svc.loadObservaciones(widget.cliente.id);
      _turnos = await _svc.loadAppointmentsForClient(widget.cliente.telefono);
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      controller: widget.scrollController,
      padding: const EdgeInsets.all(16),
      children: [
        // Handle
        Center(
          child: Container(
            width: 40, height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(color: AppConfig.colorSurfaceVariant, borderRadius: BorderRadius.circular(2)),
          ),
        ),
        // Nombre y telefono
        Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: widget.primary.withAlpha(40),
              child: Text(
                widget.cliente.nombre.isNotEmpty ? widget.cliente.nombre[0].toUpperCase() : '?',
                style: TextStyle(color: widget.primary, fontWeight: FontWeight.bold, fontSize: 24),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.cliente.nombre, style: const TextStyle(color: AppConfig.colorTexto, fontSize: 18, fontWeight: FontWeight.bold)),
                  Text(widget.cliente.telefono, style: const TextStyle(color: AppConfig.colorTextoSecundario, fontSize: 13)),
                  if (widget.cliente.email.isNotEmpty)
                    Text(widget.cliente.email, style: const TextStyle(color: AppConfig.colorTextoSecundario, fontSize: 12)),
                ],
              ),
            ),
            // Boton WhatsApp
            IconButton(
              onPressed: () => _openWhatsApp(widget.cliente.telefono),
              icon: const Icon(Icons.chat, color: Color(0xFF25D366), size: 28),
              tooltip: 'WhatsApp',
            ),
          ],
        ),
        const SizedBox(height: 20),

        if (_loading)
          const Center(child: CircularProgressIndicator())
        else ...[
          // Seccion: Historia Clinica
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Historia Clinica', style: TextStyle(color: AppConfig.colorTexto, fontSize: 16, fontWeight: FontWeight.bold)),
              ElevatedButton.icon(
                onPressed: _addObservacion,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Agregar', style: TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  minimumSize: Size.zero,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_observaciones.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppConfig.colorSurfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'No hay observaciones aun. Agrega la primera!',
                style: TextStyle(color: AppConfig.colorTextoSecundario, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            )
          else
            ...(_observaciones.map((obs) => _observacionCard(obs))),

          const SizedBox(height: 24),

          // Seccion: Turnos pasados
          const Text('Historial de Turnos', style: TextStyle(color: AppConfig.colorTexto, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (_turnos.isEmpty)
            const Text('No hay turnos registrados.', style: TextStyle(color: AppConfig.colorTextoSecundario, fontSize: 13))
          else
            ...(_turnos.take(20).map((t) => _turnoCard(t))),
        ],
      ],
    );
  }

  Widget _observacionCard(ClienteObservacion obs) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppConfig.colorSurfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: widget.primary.withAlpha(30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calendar_today, size: 12, color: widget.accent),
              const SizedBox(width: 4),
              Text(obs.fecha, style: TextStyle(color: widget.accent, fontSize: 12, fontWeight: FontWeight.w600)),
              if (obs.servicioNombre.isNotEmpty) ...[
                const SizedBox(width: 8),
                Icon(Icons.spa, size: 12, color: widget.primary),
                const SizedBox(width: 4),
                Expanded(child: Text(obs.servicioNombre, style: TextStyle(color: widget.primary, fontSize: 12), overflow: TextOverflow.ellipsis)),
              ] else
                const Spacer(),
              // Botones editar/eliminar
              InkWell(
                onTap: () => _editObservacion(obs),
                child: const Icon(Icons.edit, size: 16, color: AppConfig.colorTextoSecundario),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () => _deleteObservacion(obs),
                child: const Icon(Icons.delete_outline, size: 16, color: AppConfig.colorCancelado),
              ),
            ],
          ),
          if (obs.professionalNombre.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text('Prof: ${obs.professionalNombre}', style: const TextStyle(color: AppConfig.colorTextoSecundario, fontSize: 11)),
          ],
          const SizedBox(height: 6),
          Text(obs.observacion, style: const TextStyle(color: AppConfig.colorTexto, fontSize: 13, height: 1.4)),
        ],
      ),
    );
  }

  Widget _turnoCard(Appointment t) {
    final estadoColor = {
      'completada': AppConfig.colorConfirmado,
      'cancelada': AppConfig.colorCancelado,
      'no_show': AppConfig.colorPendiente,
      'confirmada': AppConfig.colorSecundario,
      'pendiente_confirmacion': AppConfig.colorPendiente,
      'en_atencion': AppConfig.colorEnAtencion,
    };
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppConfig.colorSurfaceVariant,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            width: 8, height: 8,
            decoration: BoxDecoration(
              color: estadoColor[t.estado] ?? AppConfig.colorTextoSecundario,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(t.fecha, style: const TextStyle(color: AppConfig.colorTextoSecundario, fontSize: 12)),
          const SizedBox(width: 6),
          Text(t.hora, style: const TextStyle(color: AppConfig.colorTextoSecundario, fontSize: 12)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              t.servicioNombre ?? 'Sin servicio',
              style: const TextStyle(color: AppConfig.colorTexto, fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (t.professionalNombre != null)
            Text(t.professionalNombre!, style: TextStyle(color: widget.primary, fontSize: 11)),
        ],
      ),
    );
  }

  void _openWhatsApp(String telefono) async {
    final tel = telefono.replaceAll(RegExp(r'[^\d+]'), '');
    final url = Uri.parse('https://wa.me/$tel');
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  void _addObservacion() {
    final obsCtrl = TextEditingController();
    final servicioCtrl = TextEditingController();
    final profCtrl = TextEditingController();
    final now = DateTime.now();
    String fecha = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppConfig.colorFondoCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Nueva Observacion', style: TextStyle(color: AppConfig.colorTexto)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: TextEditingController(text: fecha),
                decoration: const InputDecoration(labelText: 'Fecha'),
                style: const TextStyle(color: AppConfig.colorTexto),
                onChanged: (v) => fecha = v,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: servicioCtrl,
                decoration: const InputDecoration(labelText: 'Servicio realizado'),
                style: const TextStyle(color: AppConfig.colorTexto),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: profCtrl,
                decoration: const InputDecoration(labelText: 'Profesional'),
                style: const TextStyle(color: AppConfig.colorTexto),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: obsCtrl,
                decoration: const InputDecoration(
                  labelText: 'Observacion / que se hizo',
                  hintText: 'Ej: Color rubio ceniza con Wella T18, raiz oscura...',
                  hintStyle: TextStyle(color: AppConfig.colorTextoSecundario, fontSize: 12),
                ),
                style: const TextStyle(color: AppConfig.colorTexto),
                maxLines: 4,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              if (obsCtrl.text.trim().isEmpty) return;
              await _svc.createObservacion({
                'cliente_id': widget.cliente.id,
                'fecha': fecha,
                'servicio_nombre': servicioCtrl.text.trim(),
                'professional_nombre': profCtrl.text.trim(),
                'observacion': obsCtrl.text.trim(),
              });
              await _loadData();
              widget.onChanged();
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _editObservacion(ClienteObservacion obs) {
    final obsCtrl = TextEditingController(text: obs.observacion);
    final servicioCtrl = TextEditingController(text: obs.servicioNombre);
    final profCtrl = TextEditingController(text: obs.professionalNombre);
    String fecha = obs.fecha;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppConfig.colorFondoCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Editar Observacion', style: TextStyle(color: AppConfig.colorTexto)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: TextEditingController(text: fecha),
                decoration: const InputDecoration(labelText: 'Fecha'),
                style: const TextStyle(color: AppConfig.colorTexto),
                onChanged: (v) => fecha = v,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: servicioCtrl,
                decoration: const InputDecoration(labelText: 'Servicio realizado'),
                style: const TextStyle(color: AppConfig.colorTexto),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: profCtrl,
                decoration: const InputDecoration(labelText: 'Profesional'),
                style: const TextStyle(color: AppConfig.colorTexto),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: obsCtrl,
                decoration: const InputDecoration(labelText: 'Observacion'),
                style: const TextStyle(color: AppConfig.colorTexto),
                maxLines: 4,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              if (obsCtrl.text.trim().isEmpty) return;
              await _svc.updateObservacion(obs.id, {
                'fecha': fecha,
                'servicio_nombre': servicioCtrl.text.trim(),
                'professional_nombre': profCtrl.text.trim(),
                'observacion': obsCtrl.text.trim(),
              });
              await _loadData();
              widget.onChanged();
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteObservacion(ClienteObservacion obs) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppConfig.colorFondoCard,
        title: const Text('Eliminar observacion?', style: TextStyle(color: AppConfig.colorTexto)),
        content: const Text('Esta accion no se puede deshacer.', style: TextStyle(color: AppConfig.colorTextoSecundario)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppConfig.colorCancelado),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await _svc.deleteObservacion(obs.id);
      await _loadData();
      widget.onChanged();
    }
  }
}
