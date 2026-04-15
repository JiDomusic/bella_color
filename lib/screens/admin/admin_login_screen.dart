import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/app_config.dart';
import '../../config/brand_config.dart';
import '../../services/supabase_service.dart';
import 'admin_dashboard_screen.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  bool _remember = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString('admin_email') ?? '';
    final savedPass = prefs.getString('admin_pass') ?? '';
    final remember = prefs.getBool('admin_remember') ?? false;
    if (remember && savedEmail.isNotEmpty && savedPass.isNotEmpty) {
      _emailCtrl.text = savedEmail;
      _passCtrl.text = savedPass;
      _remember = true;
      // Auto-login con credenciales guardadas
      _login();
    }
  }

  Future<void> _saveCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    if (_remember) {
      await prefs.setString('admin_email', _emailCtrl.text.trim());
      await prefs.setString('admin_pass', _passCtrl.text.trim());
      await prefs.setBool('admin_remember', true);
    } else {
      await prefs.remove('admin_email');
      await prefs.remove('admin_pass');
      await prefs.setBool('admin_remember', false);
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_emailCtrl.text.trim().isEmpty || _passCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Completá email y contraseña');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      await SupabaseService.instance.signIn(_emailCtrl.text.trim(), _passCtrl.text.trim());
      final tenantId = await SupabaseService.instance.getTenantIdForCurrentUser();
      if (tenantId == null) {
        await SupabaseService.instance.signOut();
        setState(() => _error = 'Este usuario no tiene un salon asignado');
        return;
      }
      // Si el usuario es admin de OTRO tenant → redirigir a su salon
      final currentTenant = SupabaseService.instance.tenantId;
      if (tenantId != currentTenant) {
        await _saveCredentials();
        final origin = html.window.location.origin;
        html.window.location.href = '$origin/$tenantId';
        return;
      }
      // Es admin de ESTE tenant → entrar al dashboard
      SupabaseService.instance.setTenantId(tenantId);
      await SupabaseService.instance.loadTenant();
      await _saveCredentials();
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

  @override
  Widget build(BuildContext context) {
    final brand = BrandConfig.instance;

    // Barbería: fondo oscuro, verde químico, estética cruda
    // Salón: fondo rosa claro, rosa suave, estética elegante
    final bgColor = brand.esBarberia ? const Color(0xFF111111) : const Color(0xFFFFF0F3);
    final accentColor = brand.esBarberia ? const Color(0xFF4CAF50) : const Color(0xFFD4A0A0);
    final labelColor = brand.esBarberia ? const Color(0xFF9E9E9E) : const Color(0xFF8B6B6B);
    final textColor = brand.esBarberia ? Colors.white : const Color(0xFF4A3535);
    final inputFill = brand.esBarberia ? const Color(0xFF1E1E1E) : Colors.white;
    final borderColor = brand.esBarberia ? const Color(0xFF4CAF50).withAlpha(80) : const Color(0xFFD4A0A0).withAlpha(80);
    final borderFocused = brand.esBarberia ? const Color(0xFF4CAF50) : const Color(0xFFD4A0A0);
    final iconData = brand.esBarberia ? Icons.content_cut : Icons.spa;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        foregroundColor: labelColor,
        elevation: 0,
        title: Text('Administración', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: labelColor)),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(iconData, size: 56, color: accentColor),
              const SizedBox(height: 28),
              TextField(
                controller: _emailCtrl,
                decoration: InputDecoration(
                  labelText: 'Email',
                  labelStyle: TextStyle(color: labelColor, fontSize: 16),
                  prefixIcon: Icon(Icons.email, color: accentColor),
                  filled: true,
                  fillColor: inputFill,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: borderFocused, width: 2),
                  ),
                ),
                keyboardType: TextInputType.emailAddress,
                style: TextStyle(color: textColor, fontSize: 16),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passCtrl,
                decoration: InputDecoration(
                  labelText: 'Contraseña',
                  labelStyle: TextStyle(color: labelColor, fontSize: 16),
                  prefixIcon: Icon(Icons.lock, color: accentColor),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscure ? Icons.visibility_off : Icons.visibility,
                      color: accentColor.withAlpha(160),
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                  filled: true,
                  fillColor: inputFill,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: borderFocused, width: 2),
                  ),
                ),
                obscureText: _obscure,
                style: TextStyle(color: textColor, fontSize: 16),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: Checkbox(
                      value: _remember,
                      onChanged: (v) => setState(() => _remember = v ?? false),
                      activeColor: accentColor,
                      checkColor: brand.esBarberia ? Colors.black : Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => setState(() => _remember = !_remember),
                    child: Text(
                      'Recordar contraseña',
                      style: TextStyle(color: labelColor, fontSize: 14),
                    ),
                  ),
                ],
              ),
              if (_error != null) ...[
                const SizedBox(height: 14),
                Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 14)),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _loading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    foregroundColor: brand.esBarberia ? Colors.black : Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                  ),
                  child: _loading
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Ingresar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
