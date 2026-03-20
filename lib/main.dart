import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'config/app_config.dart';
import 'screens/splash_screen.dart';
import 'services/supabase_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final tenantId = _resolveTenantId();
  SupabaseService.instance.setTenantId(tenantId);

  await SupabaseService.instance.initialize();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  runApp(const BellaColorApp());
}

/// Obtiene tenant_id: path (/jose), query param (?tenant=jose), fragment, o 'demo'.
String _resolveTenantId() {
  String envTenant = const String.fromEnvironment('TENANT_ID', defaultValue: 'demo');

  if (kIsWeb) {
    try {
      final uri = Uri.base;

      // 1. Query param ?tenant=xxx (retrocompatible)
      final fromQuery = uri.queryParameters['tenant'];
      if (fromQuery != null && fromQuery.isNotEmpty) return fromQuery;

      // 2. Path limpio /jose (nuevo formato bonito)
      final pathSegments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
      if (pathSegments.length == 1 && !pathSegments[0].contains('.')) {
        return pathSegments[0];
      }

      // 3. Fragment #jose
      final frag = uri.fragment;
      if (frag.isNotEmpty) {
        final path = frag.startsWith('/') ? frag.substring(1) : frag;
        if (path.isNotEmpty && !path.contains('/')) return path;
      }
    } catch (_) {
      // Fall back to envTenant
    }
  }

  return envTenant;
}

class BellaColorApp extends StatelessWidget {
  const BellaColorApp({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = _butterflyTheme();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Bella Color',
      theme: theme,
      home: const SplashScreen(),
      builder: (context, child) {
        // Subtle mariposa-inspired gradient behind every screen.
        return DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF1E0F21),
                Color(0xFF0D111A),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }

  ThemeData _butterflyTheme() {
    final base = AppConfig.buildTheme();

    return base.copyWith(
      useMaterial3: true,
      cardTheme: base.cardTheme.copyWith(
        color: AppConfig.colorFondoCard.withOpacity(0.9),
        surfaceTintColor: Colors.transparent,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppConfig.colorPrimario.withOpacity(0.22),
          foregroundColor: AppConfig.colorTexto,
          shadowColor: AppConfig.colorPrimario.withOpacity(0.35),
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppConfig.colorSecundario.withOpacity(0.2),
          foregroundColor: AppConfig.colorTexto,
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 16),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppConfig.colorTexto,
          side: BorderSide(color: AppConfig.colorPrimario.withOpacity(0.5)),
          backgroundColor: AppConfig.colorPrimario.withOpacity(0.08),
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppConfig.colorTexto,
          backgroundColor: AppConfig.colorPrimario.withOpacity(0.12),
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        ),
      ),
      floatingActionButtonTheme: base.floatingActionButtonTheme.copyWith(
        shape: const CircleBorder(),
        backgroundColor: AppConfig.colorAcento.withOpacity(0.35),
        foregroundColor: Colors.white,
        elevation: 6,
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: AppConfig.colorPrimario.withOpacity(0.18),
        shape: const StadiumBorder(),
        labelStyle: const TextStyle(color: AppConfig.colorTexto),
      ),
    );
  }
}
