import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/public_theme.dart';
import '../models/service.dart';
import '../utils/price_format.dart';

class ServiceCard extends StatelessWidget {
  final Service service;
  final Color primary;
  final Color accent;
  final VoidCallback onTap;

  const ServiceCard({
    super.key,
    required this.service,
    required this.primary,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isNarrow = MediaQuery.of(context).size.width < 700;
    final imageAspect = isNarrow ? 1.0 : 4 / 5;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: PublicTheme.paper,
          borderRadius: PublicTheme.borderLg,
          border: Border.all(color: PublicTheme.stroke),
          boxShadow: [
            BoxShadow(color: Colors.black.withAlpha(12), blurRadius: 12, offset: const Offset(0, 4)),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: imageAspect,
              child: service.imagenUrl != null
                  ? Image.network(service.imagenUrl!, fit: BoxFit.cover)
                  : Container(
                      color: primary.withAlpha(24),
                      child: Icon(_categoryIcon(service.categoria), size: 46, color: primary.withAlpha(140)),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    service.nombre,
                    style: GoogleFonts.sora(fontSize: 14, fontWeight: FontWeight.w700, color: PublicTheme.ink),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 14, color: primary),
                      const SizedBox(width: 4),
                      Text(
                        '${service.duracionMinutos} min',
                        style: GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.w600, color: PublicTheme.softMuted),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      if (service.precioEfectivoFinal != null)
                        _pricePill(formatPrecioConSigno(service.precioEfectivoFinal!), primary, Icons.payments_outlined),
                      if (service.precioTarjetaFinal != null)
                        _pricePill(formatPrecioConSigno(service.precioTarjetaFinal!), accent, Icons.credit_card),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pricePill(String text, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withAlpha(28),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withAlpha(120)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            text,
            style: GoogleFonts.sora(fontSize: 13, fontWeight: FontWeight.w700, color: color),
          ),
        ],
      ),
    );
  }

  IconData _categoryIcon(String cat) {
    const icons = {
      'unas': Icons.brush,
      'maquillaje': Icons.face_retouching_natural,
      'masajes': Icons.spa,
      'depilacion': Icons.content_cut,
      'pestanas': Icons.visibility,
      'cejas': Icons.remove_red_eye,
      'facial': Icons.face,
      'cabello': Icons.content_cut,
      'corporal': Icons.self_improvement,
    };
    return icons[cat] ?? Icons.star;
  }
}
