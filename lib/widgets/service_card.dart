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
      child: AspectRatio(
        aspectRatio: 1,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: primary.withAlpha(20), blurRadius: 8, offset: const Offset(0, 2)),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Imagen de fondo
              if (service.imagenUrl != null)
                Image.network(service.imagenUrl!, fit: BoxFit.cover)
              else
                Container(
                  color: primary.withAlpha(15),
                  child: Icon(_categoryIcon(service.categoria), size: 48, color: primary.withAlpha(80)),
                ),
              // Gradiente oscuro abajo
              Positioned(
                left: 0, right: 0, bottom: 0,
                child: Container(
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black.withAlpha(180)],
                    ),
                  ),
                ),
              ),
              // Info sobre el gradiente
              Positioned(
                left: 10, right: 10, bottom: 10,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      service.nombre,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.access_time, size: 11, color: Colors.white70),
                        const SizedBox(width: 3),
                        Text(
                          '${service.duracionMinutos} min',
                          style: const TextStyle(fontSize: 11, color: Colors.white70),
                        ),
                        if (service.precio != null) ...[
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: accent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '\$${service.precio!.toStringAsFixed(0)}',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
                            ),
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
