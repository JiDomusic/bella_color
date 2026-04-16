// Script para generar favicons con el logo del splash (gradiente rosa + ícono spa)
// Ejecutar: dart run generate_favicon.dart

import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'dart:math';

void main() {
  // Generar en 3 tamaños
  final sizes = {
    'web/favicon.png': 32,
    'web/icons/Icon-192.png': 192,
    'web/icons/Icon-512.png': 512,
    'web/icons/Icon-maskable-192.png': 192,
    'web/icons/Icon-maskable-512.png': 512,
  };

  for (final entry in sizes.entries) {
    final size = entry.value;
    final image = img.Image(width: size, height: size);

    // Gradiente rosa diagonal (E8B4C8 → D4A0A0)
    for (int y = 0; y < size; y++) {
      for (int x = 0; x < size; x++) {
        final t = (x + y) / (2 * size); // diagonal factor 0..1
        final r = (0xE8 + (0xD4 - 0xE8) * t).round().clamp(0, 255);
        final g = (0xB4 + (0xA0 - 0xB4) * t).round().clamp(0, 255);
        final b = (0xC8 + (0xA0 - 0xC8) * t).round().clamp(0, 255);

        // Circular mask (redondo)
        final cx = size / 2, cy = size / 2, radius = size / 2;
        final dist = sqrt((x - cx) * (x - cx) + (y - cy) * (y - cy));
        if (dist <= radius) {
          image.setPixelRgba(x, y, r, g, b, 255);
        } else {
          image.setPixelRgba(x, y, 0, 0, 0, 0);
        }
      }
    }

    // Dibujar un ícono simple de "spa" (3 pétalos) en blanco
    _drawSpaIcon(image, size);

    final png = img.encodePng(image);
    File(entry.key).writeAsBytesSync(png);
    print('Generated ${entry.key} (${size}x$size)');
  }
  print('Done!');
}

void _drawSpaIcon(img.Image image, int size) {
  final cx = size / 2;
  final cy = size / 2;
  final petalRadius = size * 0.18;
  final petalOffset = size * 0.14;

  // 3 pétalos: arriba, abajo-izquierda, abajo-derecha
  final petals = [
    [cx, cy - petalOffset],                    // arriba
    [cx - petalOffset * 0.87, cy + petalOffset * 0.5], // abajo-izq
    [cx + petalOffset * 0.87, cy + petalOffset * 0.5], // abajo-der
  ];

  for (final petal in petals) {
    _fillCircle(image, petal[0], petal[1], petalRadius, 255, 255, 255, 220);
  }
  // Centro
  _fillCircle(image, cx, cy, petalRadius * 0.4, 255, 255, 255, 255);
}

void _fillCircle(img.Image image, double cx, double cy, double radius, int r, int g, int b, int a) {
  final minX = (cx - radius).floor().clamp(0, image.width - 1);
  final maxX = (cx + radius).ceil().clamp(0, image.width - 1);
  final minY = (cy - radius).floor().clamp(0, image.height - 1);
  final maxY = (cy + radius).ceil().clamp(0, image.height - 1);

  for (int y = minY; y <= maxY; y++) {
    for (int x = minX; x <= maxX; x++) {
      final dist = sqrt((x - cx) * (x - cx) + (y - cy) * (y - cy));
      if (dist <= radius) {
        // Alpha blend
        final existing = image.getPixel(x, y);
        final ea = existing.a.toInt();
        final er = existing.r.toInt();
        final eg = existing.g.toInt();
        final eb = existing.b.toInt();

        final fa = a / 255.0;
        final nr = (r * fa + er * (1 - fa)).round().clamp(0, 255);
        final ng = (g * fa + eg * (1 - fa)).round().clamp(0, 255);
        final nb = (b * fa + eb * (1 - fa)).round().clamp(0, 255);
        final na = (a + ea * (1 - fa)).round().clamp(0, 255);

        image.setPixelRgba(x, y, nr, ng, nb, na);
      }
    }
  }
}
