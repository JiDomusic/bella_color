import 'supabase_service.dart';

class ReminderService {
  /// Devuelve turnos confirmados dentro de la ventana de recordatorio
  /// que aún no tienen recordatorio enviado.
  static Future<List<Map<String, dynamic>>> getPendingReminders({
    int reminderHoursBefore = 24,
  }) async {
    final svc = SupabaseService.instance;
    final now = DateTime.now();
    final appointments = await svc.loadAppointments(estado: 'confirmada');
    final pending = <Map<String, dynamic>>[];

    for (final a in appointments) {
      final json = a.toJson();
      if (json['recordatorio_enviado'] == true) continue;

      try {
        final fecha = DateTime.parse(a.fecha);
        final horaParts = a.hora.split(':');
        final appointmentTime = DateTime(
          fecha.year, fecha.month, fecha.day,
          int.parse(horaParts[0]), int.parse(horaParts[1]),
        );

        final reminderWindow = appointmentTime.subtract(
          Duration(hours: reminderHoursBefore),
        );

        if (now.isAfter(reminderWindow) && now.isBefore(appointmentTime)) {
          pending.add(json);
        }
      } catch (_) {
        continue;
      }
    }

    pending.sort((a, b) {
      final aKey = '${a['fecha']} ${a['hora']}';
      final bKey = '${b['fecha']} ${b['hora']}';
      return aKey.compareTo(bKey);
    });

    return pending;
  }
}
