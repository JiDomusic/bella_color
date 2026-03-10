import 'package:flutter/material.dart';
import '../../config/app_config.dart';
import '../../services/supabase_service.dart';
import 'admin_dashboard_screen.dart';
import 'super_admin_screen.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _pinCtrl = TextEditingController();
  bool _loading = false;
  bool _showSuperAdmin = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _pinCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_emailCtrl.text.trim().isEmpty || _passCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Completa email y contrasena');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      await SupabaseService.instance.signIn(_emailCtrl.text.trim(), _passCtrl.text.trim());
      final tenantId = await SupabaseService.instance.getTenantIdForCurrentUser();
      if (tenantId != null) {
        SupabaseService.instance.setTenantId(tenantId);
        await SupabaseService.instance.loadTenant();
      }
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
        );
      }
    } catch (e) {
      setState(() => _error = 'Credenciales incorrectas');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _checkSuperAdminPin() {
    if (_pinCtrl.text == AppConfig.superAdminPin) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const SuperAdminScreen()),
      );
    } else {
      setState(() => _error = 'PIN incorrecto');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConfig.colorFondoOscuro,
      appBar: AppBar(title: const Text('Administracion')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.admin_panel_settings, size: 60, color: AppConfig.colorPrimario.withAlpha(120)),
              const SizedBox(height: 24),
              TextField(
                controller: _emailCtrl,
                decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email)),
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(color: AppConfig.colorTexto),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _passCtrl,
                decoration: const InputDecoration(labelText: 'Contrasena', prefixIcon: Icon(Icons.lock)),
                obscureText: true,
                style: const TextStyle(color: AppConfig.colorTexto),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _login,
                  child: _loading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Ingresar'),
                ),
              ),
              const SizedBox(height: 32),
              // Super Admin toggle
              GestureDetector(
                onTap: () => setState(() => _showSuperAdmin = !_showSuperAdmin),
                child: Text(
                  'Super Admin',
                  style: TextStyle(fontSize: 12, color: Colors.white.withAlpha(30)),
                ),
              ),
              if (_showSuperAdmin) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _pinCtrl,
                  decoration: const InputDecoration(labelText: 'PIN', prefixIcon: Icon(Icons.vpn_key)),
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  style: const TextStyle(color: AppConfig.colorTexto),
                ),
                const SizedBox(height: 8),
                TextButton(onPressed: _checkSuperAdminPin, child: const Text('Acceder')),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
