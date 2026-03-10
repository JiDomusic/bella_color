import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../models/service.dart';

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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppConfig.colorFondoCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: primary.withAlpha(40)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            if (service.imagenUrl != null)
              SizedBox(
                height: 100,
                width: double.infinity,
                child: Image.network(service.imagenUrl!, fit: BoxFit.cover),
              )
            else
              Container(
                height: 100,
                width: double.infinity,
                color: primary.withAlpha(20),
                child: Icon(_categoryIcon(service.categoria), size: 36, color: primary.withAlpha(120)),
              ),
            // Info
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service.nombre,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppConfig.colorTexto),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 12, color: AppConfig.colorTextoSecundario),
                      const SizedBox(width: 4),
                      Text(
                        '${service.duracionMinutos} min',
                        style: const TextStyle(fontSize: 11, color: AppConfig.colorTextoSecundario),
                      ),
                      if (service.precio != null) ...[
                        const Spacer(),
                        Text(
                          '\$${service.precio!.toStringAsFixed(0)}',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: accent),
                        ),
                      ],
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
