import 'package:flutter/material.dart';
import 'dart:ui';
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

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  String? _error;
  bool _blocked = false;
  String _blockMessage = '';

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    _fadeController.forward();
    _scaleController.forward();
    _initApp();
  }

  Future<void> _initApp() async {
    try {
      await Future.delayed(const Duration(milliseconds: 2500));
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

      // Verificar que el usuario logueado sea el admin de ESTE tenant
      var isAdmin = false;
      if (svc.isLoggedIn) {
        final tenantForUser = await svc.getTenantIdForCurrentUser();
        if (tenantForUser == svc.tenantId) {
          isAdmin = true;
        } else {
          // Sesion de otro tenant, cerrar sesion
          await svc.signOut();
        }
      }
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
    Future<void> tryPin() async {
      final ok = await auth.verifyAsync(pinCtrl.text);
      if (!mounted) return;
      if (ok) {
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
        backgroundColor: const Color(0xFF1A1020),
        title: const Text('Super Admin', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: pinCtrl,
          obscureText: true,
          keyboardType: TextInputType.number,
          maxLength: 6,
          style: const TextStyle(color: Colors.white, letterSpacing: 6, fontSize: 20),
          textAlign: TextAlign.center,
          decoration: const InputDecoration(labelText: 'PIN', labelStyle: TextStyle(color: Color(0xFFD4A0A0))),
          onSubmitted: (_) => tryPin(),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar', style: TextStyle(color: Color(0xFFD4A0A0)))),
          ElevatedButton(
            onPressed: tryPin,
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD4A0A0)),
            child: const Text('Entrar'),
          ),
        ],
      ),
    );
  }

  /// Si el tenant no completó onboarding, mostrar contenido genérico
  bool get _usarGenerico {
    final tenant = SupabaseService.instance.currentTenant;
    return tenant == null || !tenant.onboardingCompleted;
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  Widget _buildLogo() {
    final tenant = SupabaseService.instance.currentTenant;
    if (!_usarGenerico && tenant != null && tenant.logoUrl != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: Image.network(
          tenant.logoUrl!,
          width: 140,
          height: 140,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildGenericLogo(),
        ),
      );
    }
    return _buildGenericLogo();
  }

  Widget _buildGenericLogo() {
    return Container(
      width: 140,
      height: 140,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE8B4C8), Color(0xFFD4A0A0)],
        ),
      ),
      child: const Icon(Icons.spa, size: 64, color: Colors.white),
    );
  }

  Widget _buildHelperBanner() {
    if (!_usarGenerico) return const SizedBox.shrink();

    final tenantId = SupabaseService.instance.tenantId;
    final esTenantReal = tenantId != 'demo' && tenantId.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(top: 28.0),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 1200),
        curve: Curves.easeOutBack,
        builder: (context, value, child) {
          final clamped = value.clamp(0.0, 1.0);
          return Opacity(
            opacity: clamped,
            child: Transform.translate(
              offset: Offset(0, (1 - clamped) * 16),
              child: Transform.scale(
                scale: 0.96 + (clamped * 0.04),
                child: child,
              ),
            ),
          );
        },
        child: Container(
          width: 420,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF2A1520),
                Color(0xFF8B2252),
                Color(0xFFD4688E),
                Color(0xFFF5A0B8),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFFFD4E5).withAlpha(120), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF8B2252).withAlpha(80),
                blurRadius: 32,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '💅 Tu salon, listo en minutos',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFFFFE8F0),
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Entra al panel de admin, subi tu logo,\nelegí tus servicios y arma tu equipo.\nEs super facil, te guiamos en cada paso.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFFFCE0EC),
                  fontSize: 15,
                  height: 1.6,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Tené paciencia, selecciona los servicios\ny completa tu salon paso a paso.\nCuando termines, aca aparece tu logo!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFFFFF0F5),
                  fontSize: 14,
                  height: 1.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (esTenantReal) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD700).withAlpha(40),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFFD700).withAlpha(80)),
                  ),
                  child: const Text(
                    'Este salon se esta configurando.\nProximamente estara disponible.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFFFFE8A0),
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tenant = SupabaseService.instance.currentTenant;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0610),
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
      body: Stack(
        children: [
          // Fondo degradado rosa/negro estilo Netflix femenino
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF1A0A14), // negro rosado arriba
                  Color(0xFF0E0610), // negro violeta medio
                  Color(0xFF140A10), // negro rosado abajo
                ],
              ),
            ),
          ),
          // Glow rosa sutil detrás del logo
          Positioned(
            top: MediaQuery.of(context).size.height * 0.18,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFFD4A0A0).withAlpha(30),
                      const Color(0xFFD4A0A0).withAlpha(10),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo con animación
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: AnimatedBuilder(
                        animation: _scaleAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _scaleAnimation.value,
                            child: Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withAlpha(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFD4A0A0).withAlpha(40),
                                    blurRadius: 60,
                                    spreadRadius: 20,
                                  ),
                                ],
                              ),
                              child: _buildLogo(),
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Nombre y subtítulo
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Column(
                        children: [
                          Text(
                            _usarGenerico
                                ? 'BELLA COLOR'
                                : (tenant?.nombreSalon ?? 'BELLA COLOR').toUpperCase(),
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w300,
                              color: Colors.white.withAlpha(230),
                              letterSpacing: 8,
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Línea decorativa rosa
                          Container(
                            width: 80,
                            height: 1.5,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.transparent,
                                  const Color(0xFFD4A0A0).withAlpha(180),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _usarGenerico
                                ? 'Sistema de turnos para salones de belleza'
                                : (tenant?.subtitulo ?? ''),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w300,
                              color: const Color(0xFFD4A0A0).withAlpha(180),
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Banner helper (solo sin onboarding)
                    _buildHelperBanner(),

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
                    // ERROR STATE
                    else if (_error != null)
                      GestureDetector(
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const AdminLoginScreen()),
                        ),
                        onLongPress: _showSuperAdminAuth,
                        child: const Text('Admin', style: TextStyle(fontSize: 14, color: Color(0xFFD4A0A0))),
                      )
                    // LOADING STATE - spinner elegante
                    else
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(8),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFFD4A0A0).withAlpha(40),
                              width: 1,
                            ),
                          ),
                          child: ClipOval(
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                              child: const Center(
                                child: SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 1.5,
                                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFD4A0A0)),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
