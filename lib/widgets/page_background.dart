import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../services/supabase_service.dart';
import '../config/public_theme.dart';

class PageBackground extends StatelessWidget {
  final Widget child;

  const PageBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final tenant = SupabaseService.instance.currentTenant;
    final primary = tenant != null ? AppConfig.hexToColor(tenant.colorPrimario) : AppConfig.colorPrimario;
    final tertiary = tenant != null ? AppConfig.hexToColor(tenant.colorTerciario) : const Color(0xFFE8C4C4);
    final fullHeight = MediaQuery.of(context).size.height;

    // Fondo de pagina: foto de fondo > color elegido > gradiente
    final fondoUrl = tenant?.fondoUrl ?? '';
    final colorFondo = tenant?.colorFondoPagina ?? '';

    if (fondoUrl.isNotEmpty) {
      return Container(
        constraints: BoxConstraints(minHeight: fullHeight),
        decoration: BoxDecoration(
          image: DecorationImage(
            image: NetworkImage(fondoUrl),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.white.withAlpha(140),
              BlendMode.srcOver,
            ),
          ),
        ),
        child: child,
      );
    }

    if (colorFondo.isNotEmpty) {
      final bgColor = AppConfig.hexToColor(colorFondo);
      return Container(
        constraints: BoxConstraints(minHeight: fullHeight),
        color: bgColor,
        child: child,
      );
    }

    // Gradiente elegante por defecto usando colores del salón
    return Container(
      constraints: BoxConstraints(minHeight: fullHeight),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            PublicTheme.cream,
            Colors.white,
            primary.withAlpha(24),
          ],
          stops: const [0.0, 0.55, 1.0],
        ),
      ),
      child: child,
    );
  }
}
