import 'dart:async';
import 'package:flutter/material.dart';
import '../models/operating_hours.dart';
import '../models/producto.dart';

class NotificationService {
  Timer? _closingTimer;
  final void Function(String title, String message) onNotification;
  final void Function(List<Producto> productos) onLowStock;

  NotificationService({
    required this.onNotification,
    required this.onLowStock,
  });

  void dispose() {
    _closingTimer?.cancel();
  }

  /// Programa alertas 10 minutos antes del cierre segun los horarios del dia.
  void scheduleClosingAlerts(List<OperatingHours> hours) {
    _closingTimer?.cancel();

    final now = DateTime.now();
    // Flutter: 1=Mon..7=Sun; OperatingHours: 0=Dom, 1=Lun..6=Sab
    int diaSemana = now.weekday % 7; // Convierte a formato 0=Dom

    final todayHours = hours.where((h) => h.diaSemana == diaSemana).toList();
    if (todayHours.isEmpty) return;

    // Encontrar la hora de cierre mas tardia del dia
    TimeOfDay? latestClosing;
    for (final h in todayHours) {
      final parts = h.horaFin.split(':');
      if (parts.length >= 2) {
        final tod = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
        if (latestClosing == null || _todToMinutes(tod) > _todToMinutes(latestClosing)) {
          latestClosing = tod;
        }
      }
    }
    if (latestClosing == null) return;

    // Calcular 10 minutos antes del cierre
    final closingMinutes = _todToMinutes(latestClosing) - 10;
    final nowMinutes = now.hour * 60 + now.minute;

    if (nowMinutes >= closingMinutes) return; // Ya paso

    final delay = Duration(minutes: closingMinutes - nowMinutes);
    _closingTimer = Timer(delay, () {
      onNotification(
        'Hora de cerrar!',
        'Recordatorio: chequea el stock del dia y agrega las observaciones de las clientas.',
      );
    });
  }

  /// Chequea productos con stock bajo y dispara alerta si hay.
  void checkLowStock(List<Producto> productos) {
    final bajoStock = productos.where((p) => p.stockBajo && p.activo).toList();
    if (bajoStock.isNotEmpty) {
      onLowStock(bajoStock);
    }
  }

  int _todToMinutes(TimeOfDay tod) => tod.hour * 60 + tod.minute;
}
