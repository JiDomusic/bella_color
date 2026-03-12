import 'supabase_service.dart';

class AutoReleaseService {
  /// Marca turnos confirmados como no_show si pasaron X minutos de la hora.
  static Future<int> processAutoRelease({int autoReleaseMinutes = 15}) async {
    final svc = SupabaseService.instance;
    final now = DateTime.now();
    final today = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final appointments = await svc.loadAppointments(fecha: today);
    int released = 0;

    for (final a in appointments) {
      if (a.estado != 'confirmada' && a.estado != 'pendiente_confirmacion') continue;

      try {
        final horaParts = a.hora.split(':');
        final appointmentTime = DateTime(
          now.year, now.month, now.day,
          int.parse(horaParts[0]), int.parse(horaParts[1]),
        );
        final releaseTime = appointmentTime.add(Duration(minutes: autoReleaseMinutes));

        if (now.isAfter(releaseTime)) {
          await svc.updateAppointmentStatus(a.id, 'no_show');
          released++;
        }
      } catch (_) {
        continue;
      }
    }

    return released;
  }

  /// Devuelve turnos que están retrasados pero aún no auto-liberados.
  static List<Map<String, dynamic>> getLateAppointments(
    List<Map<String, dynamic>> appointments, {
    int autoReleaseMinutes = 15,
  }) {
    final now = DateTime.now();
    final late = <Map<String, dynamic>>[];

    for (final a in appointments) {
      if (a['estado'] != 'confirmada') continue;

      final horaStr = a['hora'] as String?;
      if (horaStr == null) continue;

      try {
        final horaParts = horaStr.split(':');
        final appointmentTime = DateTime(
          now.year, now.month, now.day,
          int.parse(horaParts[0]), int.parse(horaParts[1]),
        );
        final releaseTime = appointmentTime.add(Duration(minutes: autoReleaseMinutes));

        if (now.isAfter(appointmentTime) && now.isBefore(releaseTime)) {
          final lateMinutes = now.difference(appointmentTime).inMinutes;
          late.add({...a, '_late_minutes': lateMinutes});
        }
      } catch (_) {
        continue;
      }
    }

    return late;
  }
}
