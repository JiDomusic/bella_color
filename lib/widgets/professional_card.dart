import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../models/professional.dart';

class ProfessionalCard extends StatelessWidget {
  final Professional professional;
  final Color primary;
  final VoidCallback onTap;

  const ProfessionalCard({
    super.key,
    required this.professional,
    required this.primary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140,
        decoration: BoxDecoration(
          color: AppConfig.colorFondoCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: primary.withAlpha(40)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 16),
            // Avatar
            CircleAvatar(
              radius: 40,
              backgroundColor: primary.withAlpha(30),
              backgroundImage: professional.fotoUrl != null
                  ? NetworkImage(professional.fotoUrl!)
                  : null,
              child: professional.fotoUrl == null
                  ? Text(
                      professional.nombre.isNotEmpty ? professional.nombre[0].toUpperCase() : '?',
                      style: TextStyle(fontSize: 28, color: primary, fontWeight: FontWeight.w600),
                    )
                  : null,
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                professional.nombre,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppConfig.colorTexto),
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
                  style: TextStyle(fontSize: 11, color: primary.withAlpha(180)),
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
                color: primary.withAlpha(20),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Ver turnos',
                style: TextStyle(fontSize: 11, color: primary, fontWeight: FontWeight.w500),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
