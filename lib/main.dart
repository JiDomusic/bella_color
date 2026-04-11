import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'config/app_config.dart';
import 'config/brand_config.dart';
import 'screens/splash_screen.dart';
import 'services/supabase_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es_ES', null);

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
      title: BrandConfig.instance.nombre,
      theme: theme,
      home: const SplashScreen(),
      builder: (context, child) {
        // Gradiente cálido premium detrás de cada pantalla.
        return DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF150E18), // Plum profundo
                AppConfig.colorFondoOscuro,
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
        color: AppConfig.colorFondoCard.withAlpha(230),
        surfaceTintColor: Colors.transparent,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppConfig.colorPrimario,
          foregroundColor: Colors.white,
          shadowColor: AppConfig.colorPrimario.withAlpha(80),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppConfig.colorSecundario.withAlpha(50),
          foregroundColor: AppConfig.colorTexto,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 16),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppConfig.colorPrimario,
          side: BorderSide(color: AppConfig.colorPrimario.withAlpha(120)),
          backgroundColor: AppConfig.colorPrimario.withAlpha(15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppConfig.colorPrimario,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        ),
      ),
      floatingActionButtonTheme: base.floatingActionButtonTheme.copyWith(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: AppConfig.colorAcento,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: AppConfig.colorPrimario.withAlpha(30),
        shape: const StadiumBorder(),
        labelStyle: const TextStyle(color: AppConfig.colorTexto),
      ),
    );
  }
}
