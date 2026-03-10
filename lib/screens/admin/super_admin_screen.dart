import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../config/app_config.dart';
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
      final tenants = await _svc.loadAllTenants();
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

  String _bookingLink(String tenantId) => '${AppConfig.publicBaseUrl}?tenant=$tenantId';

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

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppConfig.colorFondoCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.spa, color: AppConfig.colorPrimario, size: 24),
            const SizedBox(width: 8),
            const Text('Nuevo Salon', style: TextStyle(color: AppConfig.colorTexto)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                style: const TextStyle(color: AppConfig.colorTexto),
                decoration: _inputDecor('Nombre del salon', Icons.store),
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
                decoration: _inputDecor('Contrasena temporal', Icons.lock),
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
            child: const Text('Crear Salon'),
          ),
        ],
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
      // 1. Crear usuario auth via REST (sin afectar sesion del super admin)
      final userId = await _svc.createAuthUser(email, password);

      // 2. Crear tenant en la base de datos
      await _svc.createSalon(
        tenantId: tenantId,
        salonName: name,
        adminUserId: userId,
      );

      if (mounted) Navigator.pop(context); // cerrar progress

      // Mostrar resultado con el link
      if (mounted) {
        _showSuccess(
          tenantId: tenantId,
          salonName: name,
          email: email,
          password: password,
        );
      }

      _loadTenants();
    } catch (e) {
      if (mounted) Navigator.pop(context); // cerrar progress
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo crear el salon. Verifica los datos e intenta de nuevo.'), backgroundColor: Colors.redAccent),
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
  }) {
    final link = _bookingLink(tenantId);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppConfig.colorFondoCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.check_circle, color: AppConfig.colorAcento, size: 28),
            const SizedBox(width: 8),
            const Text('Salon Creado', style: TextStyle(color: AppConfig.colorTexto)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _infoRow('Salon', salonName),
              _infoRow('Tenant ID', tenantId),
              _infoRow('Email admin', email),
              _infoRow('Contrasena', password),
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
                      child: Text(link, style: TextStyle(color: AppConfig.colorAcento, fontFamily: 'monospace', fontSize: 12)),
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
              const Text(
                'Enviale estos datos al cliente por WhatsApp.\n'
                'El cliente entra al link, se loguea con email y contrasena, '
                'y configura todo desde el onboarding.',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              final text = 'Hola! Tu sistema de turnos esta listo.\n\n'
                  'Link: $link\n'
                  'Email: $email\n'
                  'Contrasena: $password\n\n'
                  'Ingresa al link, logueate y configura tu salon.';
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
        label: const Text('Nuevo Salon', style: TextStyle(fontWeight: FontWeight.w600)),
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
                  padding: const EdgeInsets.all(16),
                  itemCount: _tenants.length,
                  itemBuilder: (_, i) {
                    final t = _tenants[i];
                    final link = _bookingLink(t.id);
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppConfig.colorPrimario.withAlpha(30),
                          child: const Icon(Icons.spa, color: AppConfig.colorPrimario),
                        ),
                        title: Text(
                          t.nombreSalon.isEmpty ? t.id : t.nombreSalon,
                          style: const TextStyle(color: AppConfig.colorTexto, fontWeight: FontWeight.w600),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(t.id, style: const TextStyle(color: AppConfig.colorTextoSecundario, fontSize: 12)),
                            const SizedBox(height: 4),
                            GestureDetector(
                              onTap: () async {
                                await Clipboard.setData(ClipboardData(text: link));
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Link copiado: $link'), backgroundColor: AppConfig.colorFondoCard),
                                  );
                                }
                              },
                              child: Text(
                                link,
                                style: TextStyle(color: AppConfig.colorPrimario.withAlpha(200), fontSize: 12, decoration: TextDecoration.underline),
                              ),
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Heart button: pink = blocked, green = active
                            IconButton(
                              icon: Icon(
                                t.isBlocked ? Icons.heart_broken : Icons.favorite,
                                color: t.isBlocked ? Colors.pink.shade300 : Colors.green,
                                size: 22,
                              ),
                              onPressed: () => _toggleBlock(t),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: (t.isBlocked ? Colors.red : t.onboardingCompleted ? Colors.green : Colors.amber).withAlpha(25),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                t.isBlocked ? 'Bloqueado' : t.onboardingCompleted ? 'Activo' : 'Pendiente',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: t.isBlocked ? Colors.red : t.onboardingCompleted ? Colors.green : Colors.amber,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.redAccent, size: 20),
                              onPressed: () => _deleteSalon(t),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
