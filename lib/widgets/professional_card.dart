import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/app_config.dart';
import '../config/public_theme.dart';
import '../models/professional.dart';

class ProfessionalCard extends StatelessWidget {
  final Professional professional;
  final Color primary;
  final Color? cardColor;
  final VoidCallback onTap;

  const ProfessionalCard({
    super.key,
    required this.professional,
    required this.primary,
    this.cardColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 150,
        decoration: BoxDecoration(
          color: cardColor ?? Colors.white,
          borderRadius: PublicTheme.borderLg,
          border: Border.all(color: PublicTheme.stroke),
          boxShadow: [
            BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          children: [
            const SizedBox(height: 16),
            // Avatar
            CircleAvatar(
              radius: 42,
              backgroundColor: primary.withAlpha(24),
              backgroundImage: professional.fotoUrl != null
                  ? NetworkImage(professional.fotoUrl!)
                  : null,
              child: professional.fotoUrl == null
                  ? Text(
                      professional.nombre.isNotEmpty ? professional.nombre[0].toUpperCase() : '?',
                      style: GoogleFonts.sora(fontSize: 26, color: primary, fontWeight: FontWeight.w700),
                    )
                  : null,
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                professional.nombre,
                style: GoogleFonts.sora(fontSize: 14, fontWeight: FontWeight.w700, color: PublicTheme.ink),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
            if (professional.especialidad.isNotEmpty) ...[
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  professional.especialidad,
                  style: GoogleFonts.spaceGrotesk(fontSize: 11, color: PublicTheme.softMuted),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Ver turnos',
                style: GoogleFonts.sora(fontSize: 11, color: AppConfig.colorFondoOscuro, fontWeight: FontWeight.w700, letterSpacing: 0.3),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
