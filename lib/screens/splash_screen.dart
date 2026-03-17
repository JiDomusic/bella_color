import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../services/supabase_service.dart';
import '../services/subscription_service.dart';
import '../services/whatsapp_service.dart';
import 'home_screen.dart';
import 'admin/admin_dashboard_screen.dart';
import 'admin/admin_login_screen.dart';
import 'admin/super_admin_screen.dart';
import '../services/pin_auth_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeIn;
  String? _error;
  bool _blocked = false;
  String _blockMessage = '';

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _fadeIn = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
    _initApp();
  }

  Future<void> _initApp() async {
    try {
      await Future.delayed(const Duration(milliseconds: 800));
      final svc = SupabaseService.instance;
      final tenant = await svc.loadTenant();

      if (!mounted) return;

      // Check subscription
      final status = SubscriptionService.check(tenant);

      // Auto-bloqueo: si vencio el periodo de gracia, bloquear automaticamente
      if (status.shouldAutoBlock && !tenant.isBlocked) {
        await svc.blockTenant(tenant.id, 'Bloqueado automaticamente por falta de pago');
        if (tenant.whatsappNumero.isNotEmpty) {
          WhatsappService.openChat(
            phone: tenant.whatsappNumero,
            countryCode: tenant.codigoPaisTelefono,
            message: 'Hola ${tenant.nombreSalon}! Tu sistema de turnos fue suspendido por falta de pago. '
                'Contacta a ${AppConfig.nombreEmpresa} al ${AppConfig.whatsappSoporte} para reactivarlo.',
          );
        }
      }

      if (!status.isActive || tenant.isBlocked || status.shouldAutoBlock) {
        setState(() {
          _blocked = true;
          _blockMessage = status.message.isNotEmpty
              ? status.message
              : 'Sistema bloqueado. Contacta a soporte para reactivar.';
        });
        return;
      }

      final isAdmin = svc.isLoggedIn;
      final destination = isAdmin ? const AdminDashboardScreen() : const HomeScreen();

      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => destination,
          transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: child),
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    } catch (e) {
      final msg = e.toString();
      if (mounted) {
        // Si es tenant demo o vacío, ir al home con el welcome overlay
        final tenantId = SupabaseService.instance.tenantId;
        if (tenantId == 'demo' || tenantId.isEmpty) {
          Navigator.of(context).pushReplacement(
            PageRouteBuilder(
              pageBuilder: (_, __, ___) => const HomeScreen(),
              transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: child),
              transitionDuration: const Duration(milliseconds: 500),
            ),
          );
          return;
        }
        setState(() {
          if (msg.contains('Salon no encontrado') || msg.contains('tenant')) {
            _error = 'Salon no configurado. Contacta al administrador.';
          } else {
            _error = 'No se pudo conectar. Verifica tu conexion a internet.';
          }
        });
      }
    }
  }

  void _showSuperAdminAuth() {
    final auth = PinAuthService.instance;
    if (auth.isLocked) {
      final mins = (auth.remainingLockSeconds / 60).ceil();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Demasiados intentos. Espera $mins minuto${mins == 1 ? '' : 's'}.'), backgroundColor: Colors.redAccent),
      );
      return;
    }
    final pinCtrl = TextEditingController();
    void tryPin() {
      if (auth.verify(pinCtrl.text)) {
        Navigator.pop(context);
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SuperAdminScreen()));
      } else {
        Navigator.pop(context);
        final msg = auth.isLocked
            ? 'Demasiados intentos. Espera ${PinAuthService.lockoutMinutes} minutos.'
            : 'PIN incorrecto. ${auth.remainingAttempts} intento${auth.remainingAttempts == 1 ? '' : 's'}.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
        );
      }
    }
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppConfig.colorFondoOscuro,
        title: const Text('Super Admin', style: TextStyle(color: AppConfig.colorTexto)),
        content: TextField(
          controller: pinCtrl,
          obscureText: true,
          keyboardType: TextInputType.number,
          maxLength: 6,
          style: const TextStyle(color: AppConfig.colorTexto, letterSpacing: 6, fontSize: 20),
          textAlign: TextAlign.center,
          decoration: const InputDecoration(labelText: 'PIN'),
          onSubmitted: (_) => tryPin(),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(onPressed: tryPin, child: const Text('Entrar')),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tenant = SupabaseService.instance.currentTenant;
    return Scaffold(
      backgroundColor: const Color(0xFFFFF0F3),
      floatingActionButton: _error != null
          ? FloatingActionButton(
              onPressed: () => WhatsappService.openChat(
                phone: '3413363551',
                countryCode: '54',
                message: 'Hola! Quisiera informacion sobre el sistema de turnos.',
              ),
              backgroundColor: const Color(0xFF25D366),
              child: const Icon(Icons.chat, color: Colors.white, size: 26),
            )
          : null,
      body: Center(
        child: FadeTransition(
          opacity: _fadeIn,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (tenant?.logoUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.network(tenant!.logoUrl!, width: 100, height: 100, fit: BoxFit.cover),
                )
              else
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4A0A0).withAlpha(30),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.spa, size: 44, color: Color(0xFFD4A0A0)),
                ),
              const SizedBox(height: 20),
              Text(
                tenant?.nombreSalon ?? 'Bella Color',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF8B6B6B),
                  letterSpacing: 1,
                ),
              ),
              if (tenant?.subtitulo.isNotEmpty == true) ...[
                const SizedBox(height: 6),
                Text(
                  tenant!.subtitulo,
                  style: const TextStyle(fontSize: 13, color: Color(0xFFB89999)),
                ),
              ],
              const SizedBox(height: 40),
              // BLOCKED STATE
              if (_blocked)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.red.withAlpha(20),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.red.withAlpha(60)),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.heart_broken, size: 40, color: Colors.pink.shade300),
                            const SizedBox(height: 12),
                            const Text(
                              'Sistema Suspendido',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.redAccent),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _blockMessage,
                              style: const TextStyle(fontSize: 13, color: AppConfig.colorTextoSecundario),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => WhatsappService.openSupport(),
                        icon: const Icon(Icons.chat, size: 18),
                        label: const Text('Contactar Soporte'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF25D366),
                          minimumSize: const Size(double.infinity, 48),
                        ),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const AdminLoginScreen()),
                        ),
                        icon: const Icon(Icons.admin_panel_settings, size: 16),
                        label: const Text('Admin'),
                      ),
                    ],
                  ),
                )
              // ERROR STATE - solo Admin link
              else if (_error != null)
                GestureDetector(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AdminLoginScreen()),
                  ),
                  onLongPress: _showSuperAdminAuth,
                  child: const Text('Admin', style: TextStyle(fontSize: 14, color: Color(0xFFB89999))),
                )
              // LOADING STATE
              else
                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: const Color(0xFFD4A0A0),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
