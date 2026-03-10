import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../services/supabase_service.dart';
import 'home_screen.dart';
import 'admin/admin_dashboard_screen.dart';
import 'admin/admin_login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeIn;
  String? _error;

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
      await svc.loadTenant();

      if (!mounted) return;

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
      if (mounted) setState(() => _error = e.toString());
    }
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
      backgroundColor: AppConfig.colorFondoOscuro,
      body: Center(
        child: FadeTransition(
          opacity: _fadeIn,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (tenant?.logoUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.network(tenant!.logoUrl!, width: 120, height: 120, fit: BoxFit.cover),
                )
              else
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: AppConfig.colorPrimario.withAlpha(40),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.spa, size: 60, color: AppConfig.colorPrimario),
                ),
              const SizedBox(height: 24),
              Text(
                tenant?.nombreSalon ?? 'Bella Color',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppConfig.colorTexto,
                  letterSpacing: 1.2,
                ),
              ),
              if (tenant?.subtitulo.isNotEmpty == true) ...[
                const SizedBox(height: 8),
                Text(
                  tenant!.subtitulo,
                  style: TextStyle(fontSize: 14, color: AppConfig.colorPrimario.withAlpha(180)),
                ),
              ],
              const SizedBox(height: 40),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    children: [
                      Text(
                        _error!,
                        style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => AdminLoginScreen()),
                              );
                            },
                            icon: const Icon(Icons.admin_panel_settings, size: 16),
                            label: const Text('Admin'),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => AdminLoginScreen()),
                              );
                            },
                            icon: const Icon(Icons.key, size: 16),
                            label: const Text('Super Admin (PIN)'),
                          ),
                        ],
                      ),
                    ],
                  ),
                )
              else
                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppConfig.colorPrimario.withAlpha(150),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
