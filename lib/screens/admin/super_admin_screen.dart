import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/app_config.dart';
import '../../config/brand_config.dart';
import '../../models/tenant.dart';
import '../../services/supabase_service.dart';

class SuperAdminScreen extends StatefulWidget {
  const SuperAdminScreen({super.key});

  @override
  State<SuperAdminScreen> createState() => _SuperAdminScreenState();
}

class _SuperAdminScreenState extends State<SuperAdminScreen> {
  final _svc = SupabaseService.instance;
  List<Tenant> _tenants = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadTenants();
  }

  Future<void> _loadTenants() async {
    try {
      final allTenants = await _svc.loadAllTenants();
      // Filtrar por marca: en Juke-Box solo barberías, en Bella Color solo salones
      final brand = BrandConfig.instance;
      final tenants = allTenants.where((t) {
        if (t.id == 'demo') return true; // demo siempre visible
        if (brand.esBarberia) return t.esBarberia;
        return !t.esBarberia; // salon
      }).toList();
      if (mounted) setState(() { _tenants = tenants; _loading = false; });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _generateTenantId(String name) {
    return name
        .toLowerCase()
        .replaceAll(RegExp(r'[áàä]'), 'a')
        .replaceAll(RegExp(r'[éèë]'), 'e')
        .replaceAll(RegExp(r'[íìï]'), 'i')
        .replaceAll(RegExp(r'[óòö]'), 'o')
        .replaceAll(RegExp(r'[úùü]'), 'u')
        .replaceAll(RegExp(r'ñ'), 'n')
        .replaceAll(RegExp(r'[^a-z0-9\s]'), '')
        .trim()
        .replaceAll(RegExp(r'\s+'), '_');
  }

  String _generateTempPassword() {
    const chars = 'ABCDEFGHJKMNPQRSTUVWXYZabcdefghjkmnpqrstuvwxyz23456789';
    final random = DateTime.now().millisecondsSinceEpoch;
    final buf = StringBuffer();
    for (int i = 0; i < 8; i++) {
      buf.write(chars[(random + i * 17) % chars.length]);
    }
    return buf.toString();
  }

  String _bookingLink(String tenantId, {String? tenantCategoria}) {
    if (tenantCategoria == 'barberia') {
      return 'https://juke-box-reserva.web.app/$tenantId';
    }
    return 'https://bella-color.web.app/$tenantId';
  }

  InputDecoration _inputDecor(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 20),
    );
  }

  Future<void> _createSalon() async {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passwordCtrl = TextEditingController(text: _generateTempPassword());
    String categoria = BrandConfig.instance.esBarberia ? 'barberia' : 'salon';

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppConfig.colorFondoCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(
                categoria == 'barberia' ? Icons.content_cut : Icons.spa,
                color: AppConfig.colorPrimario,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                categoria == 'barberia' ? 'Nueva Barberia' : 'Nuevo Salon',
                style: const TextStyle(color: AppConfig.colorTexto),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Selector de categoria
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setDialogState(() => categoria = 'salon'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: categoria == 'salon'
                                ? const Color(0xFFE8A0BF).withAlpha(40)
                                : Colors.white.withAlpha(8),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: categoria == 'salon'
                                  ? const Color(0xFFE8A0BF)
                                  : Colors.white.withAlpha(30),
                              width: categoria == 'salon' ? 2 : 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(Icons.spa, size: 28,
                                  color: categoria == 'salon'
                                      ? const Color(0xFFE8A0BF)
                                      : Colors.white54),
                              const SizedBox(height: 6),
                              Text('Salon',
                                  style: TextStyle(
                                    color: categoria == 'salon'
                                        ? const Color(0xFFE8A0BF)
                                        : Colors.white54,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  )),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setDialogState(() => categoria = 'barberia'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: categoria == 'barberia'
                                ? const Color(0xFF4CAF50).withAlpha(40)
                                : Colors.white.withAlpha(8),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: categoria == 'barberia'
                                  ? const Color(0xFF4CAF50)
                                  : Colors.white.withAlpha(30),
                              width: categoria == 'barberia' ? 2 : 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(Icons.content_cut, size: 28,
                                  color: categoria == 'barberia'
                                      ? const Color(0xFF4CAF50)
                                      : Colors.white54),
                              const SizedBox(height: 6),
                              Text('Barberia',
                                  style: TextStyle(
                                    color: categoria == 'barberia'
                                        ? const Color(0xFF4CAF50)
                                        : Colors.white54,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  )),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameCtrl,
                  style: const TextStyle(color: AppConfig.colorTexto),
                  decoration: _inputDecor(
                    categoria == 'barberia' ? 'Nombre de la barberia' : 'Nombre del salon',
                    Icons.store,
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailCtrl,
                  style: const TextStyle(color: AppConfig.colorTexto),
                  decoration: _inputDecor('Email del admin', Icons.email),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: passwordCtrl,
                  style: const TextStyle(color: AppConfig.colorTexto),
                  decoration: _inputDecor('Contraseña temporal', Icons.lock),
                ),
                const SizedBox(height: 8),
                Text(
                  'Se genera automaticamente. El admin puede cambiarla despues.',
                  style: TextStyle(fontSize: 11, color: AppConfig.colorTextoSecundario),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(categoria == 'barberia' ? 'Crear Barberia' : 'Crear Salon'),
            ),
          ],
        ),
      ),
    );

    if (result != true) return;

    final name = nameCtrl.text.trim();
    final email = emailCtrl.text.trim();
    final password = passwordCtrl.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty) return;

    final tenantId = _generateTenantId(name);

    // Show progress
    _showProgress('Creando salon...');

    try {
      // Crear usuario + tenant en una sola llamada RPC segura
      await _svc.createSalonComplete(
        email: email,
        password: password,
        tenantId: tenantId,
        salonName: name,
        categoria: categoria,
      );

      // Guardar credenciales para consulta posterior
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('sa_cred_email_$tenantId', email);
      await prefs.setString('sa_cred_pass_$tenantId', password);

      if (mounted) Navigator.pop(context); // cerrar progress

      // Mostrar resultado con el link
      if (mounted) {
        _showSuccess(
          tenantId: tenantId,
          salonName: name,
          email: email,
          password: password,
          categoria: categoria,
        );
      }

      _loadTenants();
    } catch (e) {
      if (mounted) Navigator.pop(context); // cerrar progress
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent, duration: const Duration(seconds: 8)),
        );
      }
    }
  }

  void _showProgress(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: AppConfig.colorFondoCard,
        content: Row(
          children: [
            CircularProgressIndicator(color: AppConfig.colorPrimario),
            const SizedBox(width: 16),
            Text(message, style: const TextStyle(color: AppConfig.colorTexto)),
          ],
        ),
      ),
    );
  }

  void _showSuccess({
    required String tenantId,
    required String salonName,
    required String email,
    required String password,
    String categoria = 'salon',
  }) {
    final link = _bookingLink(tenantId, tenantCategoria: categoria);
    final esBarberia = categoria == 'barberia';
    final tipoNombre = esBarberia ? 'Barberia' : 'Salon';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppConfig.colorFondoCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.check_circle, color: AppConfig.colorAcento, size: 28),
            const SizedBox(width: 8),
            Text('$tipoNombre Creado', style: const TextStyle(color: AppConfig.colorTexto)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _infoRow(tipoNombre, salonName),
              _infoRow('Tenant ID', tenantId),
              _infoRow('Email admin', email),
              _infoRow('Contraseña', password),
              const Divider(color: Colors.white24),
              const SizedBox(height: 8),
              const Text('Link para el cliente:', style: TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => launchUrl(Uri.parse(link), mode: LaunchMode.externalApplication),
                        child: Text(link, style: TextStyle(color: AppConfig.colorAcento, fontFamily: 'monospace', fontSize: 12, decoration: TextDecoration.underline)),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy, color: Colors.white54, size: 20),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: link));
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(content: Text('Link copiado')),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Enviale estos datos al cliente por WhatsApp.\n'
                'El cliente entra al link, se loguea con email y contraseña, '
                'y configura todo desde el onboarding.\n'
                '${esBarberia ? "Link de barberia (juke-box-reserva)" : "Link de salon (bella-color)"}',
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              final tipoMsg = esBarberia ? 'barberia' : 'salon';
              final text = 'Hola! Tu sistema de turnos esta listo.\n\n'
                  'Link: $link\n'
                  'Email: $email\n'
                  'Contraseña: $password\n\n'
                  'Ingresa al link, logueate y configura tu $tipoMsg.';
              Clipboard.setData(ClipboardData(text: text));
              ScaffoldMessenger.of(ctx).showSnackBar(
                const SnackBar(content: Text('Mensaje copiado al portapapeles')),
              );
            },
            child: const Text('Copiar mensaje para WhatsApp'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text('$label:', style: const TextStyle(color: AppConfig.colorTextoSecundario, fontSize: 13)),
          ),
          Expanded(child: Text(value, style: const TextStyle(color: AppConfig.colorTexto, fontSize: 13, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  Future<void> _openLink(String link) async {
    final uri = Uri.tryParse(link);
    if (uri == null) return;
    final ok = await canLaunchUrl(uri);
    if (!ok) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo abrir el link'), backgroundColor: Colors.redAccent),
        );
      }
      return;
    }
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _copyLink(String link) async {
    await Clipboard.setData(ClipboardData(text: link));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Link copiado: $link'), backgroundColor: AppConfig.colorFondoCard),
      );
    }
  }

  _SubInfo _subscriptionInfo(Tenant t) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startDateStr = t.subscriptionStartDate;
    final startDate = (startDateStr != null && startDateStr.isNotEmpty)
        ? DateTime.tryParse(startDateStr)
        : null;
    final trialEnd = startDate?.add(Duration(days: t.trialDays + 2));
    final dueDay = t.subscriptionDueDay;
    final lastPayment = t.lastPaymentDate;

    String fmt(DateTime d) =>
        '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

    String vencimientoLabel;
    String vencimientoTexto;
    Color vencimientoColor;

    // En trial sin pago registrado → mostrar fin de prueba
    if (lastPayment == null && trialEnd != null && now.isBefore(trialEnd)) {
      final dias = trialEnd.difference(now).inDays;
      vencimientoLabel = 'Fin prueba:';
      vencimientoTexto = '${fmt(trialEnd)} ($dias d)';
      vencimientoColor = dias <= 3 ? Colors.orange : Colors.white;
    } else {
      // Post-trial o con pago registrado → próximo vencimiento mensual
      DateTime nextDue = DateTime(now.year, now.month, dueDay);
      if (!nextDue.isAfter(today)) {
        // Si ya pasó este mes Y hay pago registrado de este ciclo, el próximo es el mes siguiente
        final pagoThisCycle = lastPayment != null &&
            !DateTime(lastPayment.year, lastPayment.month, lastPayment.day).isBefore(nextDue);
        if (pagoThisCycle) {
          nextDue = DateTime(now.year, now.month + 1, dueDay);
        }
      }
      final dias = nextDue.difference(today).inDays;
      vencimientoLabel = 'Vence:';
      vencimientoTexto = '${fmt(nextDue)} ($dias d)';
      vencimientoColor = dias < 0
          ? Colors.red
          : dias <= 3
              ? Colors.orange
              : Colors.white;
    }

    return _SubInfo(
      vencimientoLabel: vencimientoLabel,
      vencimientoTexto: vencimientoTexto,
      vencimientoColor: vencimientoColor,
      ultimoPagoTexto: lastPayment != null ? fmt(lastPayment) : '—',
    );
  }

  Future<void> _toggleBlock(Tenant t) async {
    if (t.isBlocked) {
      // Desbloquear
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppConfig.colorFondoCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.favorite, color: Colors.pink.shade300, size: 24),
              const SizedBox(width: 8),
              const Text('Desbloquear salon?', style: TextStyle(color: AppConfig.colorTexto)),
            ],
          ),
          content: Text(
            'Se desbloqueara "${t.nombreSalon}" y podra volver a operar normalmente.',
            style: const TextStyle(color: AppConfig.colorTextoSecundario),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text('Desbloquear'),
            ),
          ],
        ),
      );
      if (confirm == true) {
        await _svc.unblockTenant(t.id);
        _loadTenants();
      }
    } else {
      // Bloquear
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppConfig.colorFondoCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.heart_broken, color: Colors.pink.shade300, size: 24),
              const SizedBox(width: 8),
              const Text('Bloquear salon?', style: TextStyle(color: AppConfig.colorTexto)),
            ],
          ),
          content: Text(
            'Se bloqueara "${t.nombreSalon}" por falta de pago. El admin vera un mensaje de bloqueo.',
            style: const TextStyle(color: AppConfig.colorTextoSecundario),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              child: const Text('Bloquear'),
            ),
          ],
        ),
      );
      if (confirm == true) {
        await _svc.blockTenant(t.id, 'Bloqueado por falta de pago');
        _loadTenants();
      }
    }
  }

  Future<void> _deleteSalon(Tenant t) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppConfig.colorFondoCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Eliminar salon?', style: TextStyle(color: AppConfig.colorTexto)),
        content: Text(
          'Se eliminara "${t.nombreSalon}" y todos sus datos (profesionales, servicios, turnos, etc). Esta accion no se puede deshacer.',
          style: const TextStyle(color: AppConfig.colorTextoSecundario),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _svc.deleteTenant(t.id);
      _loadTenants();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConfig.colorFondoOscuro,
      appBar: AppBar(title: const Text('Super Admin')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createSalon,
        backgroundColor: AppConfig.colorAcento.withAlpha(90),
        icon: const Icon(Icons.add_business),
        label: const Text('Nuevo', style: TextStyle(fontWeight: FontWeight.w600)),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: AppConfig.colorPrimario))
          : _tenants.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.store_mall_directory, size: 80, color: Colors.white.withAlpha(50)),
                      const SizedBox(height: 16),
                      Text('No hay salones', style: TextStyle(color: Colors.white.withAlpha(130), fontSize: 18)),
                      const SizedBox(height: 8),
                      Text('Toca el boton + para crear el primero', style: TextStyle(color: Colors.white.withAlpha(80), fontSize: 14)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  itemCount: _tenants.length,
                  itemBuilder: (_, i) => _buildTenantCard(_tenants[i]),
                ),
    );
  }

  Widget _buildTenantCard(Tenant t) {
    final link = _bookingLink(t.id, tenantCategoria: t.categoria);
    final trialEnd = t.trialEndDate;
    final trialDays = trialEnd != null ? trialEnd.difference(DateTime.now()).inDays : t.trialDays;
    final trialExpired = trialDays < 0;
    final subInfo = _subscriptionInfo(t);

    return Card(
      color: AppConfig.colorFondoCard,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  t.esBarberia ? Icons.content_cut : Icons.spa,
                  color: t.esBarberia ? const Color(0xFF4CAF50) : const Color(0xFFD97FC2),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.nombreSalon.isEmpty ? t.id : t.nombreSalon,
                        style: const TextStyle(color: AppConfig.colorTexto, fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Text(t.id, style: TextStyle(color: Colors.white.withAlpha(128), fontSize: 13, fontFamily: 'monospace')),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Status badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: (t.isBlocked ? Colors.red : t.onboardingCompleted ? Colors.green : Colors.amber).withAlpha(40),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        t.isBlocked ? 'Bloqueado' : t.onboardingCompleted ? 'Activo' : 'Pendiente',
                        style: TextStyle(
                          color: t.isBlocked ? Colors.red : t.onboardingCompleted ? Colors.green : Colors.amber,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Trial days badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: trialExpired
                            ? Colors.red.withAlpha(40)
                            : trialDays <= 3
                                ? Colors.orange.withAlpha(40)
                                : const Color(0xFFD97FC2).withAlpha(30),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            trialExpired ? Icons.timer_off : Icons.timer_outlined,
                            size: 12,
                            color: trialExpired ? Colors.red : trialDays <= 3 ? Colors.orange : (t.esBarberia ? const Color(0xFF4CAF50) : const Color(0xFFD97FC2)),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            trialExpired
                                ? 'Expirado${t.trialExtended ? " (ext)" : ""}'
                                : '$trialDays dias${t.trialExtended ? " (ext)" : ""}',
                            style: TextStyle(
                              color: trialExpired ? Colors.red : trialDays <= 3 ? Colors.orange : (t.esBarberia ? const Color(0xFF4CAF50) : const Color(0xFFD97FC2)),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Link copiable
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(13),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(link,
                        style: const TextStyle(color: Color(0xFFD97FC2), fontSize: 11, fontFamily: 'monospace'),
                        overflow: TextOverflow.ellipsis),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy, color: Colors.white54, size: 18),
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                    onPressed: () => _copyLink(link),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            // Fechas de suscripción
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(8),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white.withAlpha(15)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.event_available, size: 14, color: Colors.white.withAlpha(140)),
                      const SizedBox(width: 6),
                      Text(subInfo.vencimientoLabel, style: TextStyle(color: Colors.white.withAlpha(160), fontSize: 11)),
                      const SizedBox(width: 4),
                      Text(
                        subInfo.vencimientoTexto,
                        style: TextStyle(
                          color: subInfo.vencimientoColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.check_circle_outline, size: 14, color: Colors.white.withAlpha(140)),
                      const SizedBox(width: 6),
                      Text('Último pago: ', style: TextStyle(color: Colors.white.withAlpha(160), fontSize: 11)),
                      Text(
                        subInfo.ultimoPagoTexto,
                        style: TextStyle(
                          color: t.lastPaymentDate != null ? Colors.green.shade300 : Colors.white.withAlpha(120),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: Icon(
                    t.isBlocked ? Icons.heart_broken : Icons.favorite,
                    color: t.isBlocked ? Colors.pink.shade300 : Colors.green,
                    size: 20,
                  ),
                  tooltip: t.isBlocked ? 'Desbloquear (registrar pago)' : 'Bloquear (falta de pago)',
                  onPressed: () => _toggleBlock(t),
                ),
                TextButton.icon(
                  onPressed: () => _showCredentials(t),
                  icon: Icon(Icons.key, color: Colors.white.withAlpha(153), size: 18),
                  label: Text('Credenciales', style: TextStyle(color: Colors.white.withAlpha(153), fontSize: 13)),
                ),
                TextButton.icon(
                  onPressed: () => _deleteSalon(t),
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
                  label: const Text('Eliminar', style: TextStyle(color: Colors.redAccent, fontSize: 13)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showCredentials(Tenant t) async {
    final prefs = await SharedPreferences.getInstance();
    final tenantId = t.id;
    final name = t.nombreSalon.isEmpty ? t.id : t.nombreSalon;
    // Email: primero SharedPreferences, fallback a admin_emails del tenant
    var savedEmail = prefs.getString('sa_cred_email_$tenantId');
    if (savedEmail == null && t.adminEmails.isNotEmpty) {
      savedEmail = t.adminEmails.first;
      // Guardar para futuras consultas
      await prefs.setString('sa_cred_email_$tenantId', savedEmail);
    }
    savedEmail ??= 'No guardado';
    final savedPass = prefs.getString('sa_cred_pass_$tenantId') ?? 'No guardado';
    final link = _bookingLink(tenantId, tenantCategoria: t.categoria);
    final tipoMsg = t.esBarberia ? 'barberia' : 'salon';

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) {
        String currentPass = savedPass;
        return StatefulBuilder(
          builder: (ctx, setDialogState) => AlertDialog(
            backgroundColor: AppConfig.colorFondoCard,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(name, style: const TextStyle(color: AppConfig.colorTexto, fontSize: 18)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _credRow('Email', savedEmail!),
                  const SizedBox(height: 12),
                  _credRow('Password', currentPass),
                  const SizedBox(height: 12),
                  _credRow('Link', link),
                  if (currentPass == 'No guardado' && t.adminUserId != null) ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final newPass = _generateTempPassword();
                          try {
                            await _svc.resetAuthUserPassword(t.adminUserId!, newPass);
                            await prefs.setString('sa_cred_pass_$tenantId', newPass);
                            setDialogState(() => currentPass = newPass);
                            if (ctx.mounted) {
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                const SnackBar(content: Text('Contrasena reseteada!')),
                              );
                            }
                          } catch (e) {
                            if (ctx.mounted) {
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent),
                              );
                            }
                          }
                        },
                        icon: const Icon(Icons.refresh, size: 16),
                        label: const Text('Resetear contrasena'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              if (savedEmail != 'No guardado')
                TextButton.icon(
                  onPressed: () {
                    final text = 'Hola! Tu sistema de turnos esta listo.\n\n'
                        'Link: $link\n'
                        'Email: $savedEmail\n'
                        'Contrasena: $currentPass\n\n'
                        'Ingresa al link, logueate y configura tu $tipoMsg.';
                    Clipboard.setData(ClipboardData(text: text));
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(content: Text('Mensaje copiado para WhatsApp')),
                    );
                  },
                  icon: const Icon(Icons.chat, size: 16),
                  label: const Text('Copiar para WhatsApp'),
                ),
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cerrar')),
            ],
          ),
        );
      },
    );
  }

  Widget _credRow(String label, String value) {
    return Row(
      children: [
        SizedBox(
          width: 70,
          child: Text(label, style: TextStyle(color: Colors.white.withAlpha(128), fontSize: 12)),
        ),
        Expanded(
          child: Text(value, style: const TextStyle(color: AppConfig.colorTexto, fontSize: 13, fontFamily: 'monospace')),
        ),
        IconButton(
          icon: const Icon(Icons.copy, size: 16, color: Colors.white54),
          constraints: const BoxConstraints(),
          padding: EdgeInsets.zero,
          onPressed: () {
            Clipboard.setData(ClipboardData(text: value));
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('$label copiado'), duration: const Duration(seconds: 1)),
            );
          },
        ),
      ],
    );
  }
}

class _SubInfo {
  final String vencimientoLabel;
  final String vencimientoTexto;
  final Color vencimientoColor;
  final String ultimoPagoTexto;

  _SubInfo({
    required this.vencimientoLabel,
    required this.vencimientoTexto,
    required this.vencimientoColor,
    required this.ultimoPagoTexto,
  });
}
