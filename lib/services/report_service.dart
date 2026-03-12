import 'supabase_service.dart';

class ReportService {
  /// Genera un reporte con estadísticas de turnos para un rango de fechas.
  static Future<Map<String, dynamic>> generateReport(DateTime startDate, DateTime endDate) async {
    final svc = SupabaseService.instance;
    final allAppointments = await svc.loadAppointments();

    final startStr = startDate.toIso8601String().split('T')[0];
    final endStr = endDate.toIso8601String().split('T')[0];

    final filtered = allAppointments.where((a) {
      return a.fecha.compareTo(startStr) >= 0 && a.fecha.compareTo(endStr) <= 0;
    }).toList();

    if (filtered.isEmpty) {
      return {
        'total_turnos': 0,
        'tasa_no_show': 0.0,
        'tasa_cancelacion': 0.0,
        'servicio_mas_pedido': null,
        'profesional_mas_ocupado': null,
        'dia_mas_ocupado': null,
        'horario_mas_ocupado': null,
        'turnos_por_estado': <String, int>{},
        'turnos_por_dia': <String, int>{},
        'turnos_por_hora': <String, int>{},
        'turnos_por_servicio': <String, int>{},
        'turnos_por_profesional': <String, int>{},
      };
    }

    final total = filtered.length;
    int noShows = 0;
    int cancelados = 0;
    final porDia = <String, int>{};
    final porHora = <String, int>{};
    final porEstado = <String, int>{};
    final porServicio = <String, int>{};
    final porProfesional = <String, int>{};

    final dayNames = ['', 'Lun', 'Mar', 'Mie', 'Jue', 'Vie', 'Sab', 'Dom'];

    for (final a in filtered) {
      // Por estado
      porEstado[a.estado] = (porEstado[a.estado] ?? 0) + 1;
      if (a.estado == 'no_show') noShows++;
      if (a.estado == 'cancelada') cancelados++;

      // Por día
      try {
        final dt = DateTime.parse(a.fecha);
        final dayName = dayNames[dt.weekday];
        porDia[dayName] = (porDia[dayName] ?? 0) + 1;
      } catch (_) {}

      // Por hora
      final horaShort = a.hora.length >= 5 ? a.hora.substring(0, 5) : a.hora;
      porHora[horaShort] = (porHora[horaShort] ?? 0) + 1;

      // Por servicio
      final servName = a.servicioNombre ?? 'Sin servicio';
      porServicio[servName] = (porServicio[servName] ?? 0) + 1;

      // Por profesional
      final profName = a.professionalNombre ?? 'Sin profesional';
      porProfesional[profName] = (porProfesional[profName] ?? 0) + 1;
    }

    // Más ocupados
    String? diaMasOcupado;
    int maxDia = 0;
    for (final entry in porDia.entries) {
      if (entry.value > maxDia) { maxDia = entry.value; diaMasOcupado = entry.key; }
    }

    String? horarioMasOcupado;
    int maxHora = 0;
    for (final entry in porHora.entries) {
      if (entry.value > maxHora) { maxHora = entry.value; horarioMasOcupado = entry.key; }
    }

    String? servicioTop;
    int maxServ = 0;
    for (final entry in porServicio.entries) {
      if (entry.value > maxServ) { maxServ = entry.value; servicioTop = entry.key; }
    }

    String? profesionalTop;
    int maxProf = 0;
    for (final entry in porProfesional.entries) {
      if (entry.value > maxProf) { maxProf = entry.value; profesionalTop = entry.key; }
    }

    return {
      'total_turnos': total,
      'tasa_no_show': total > 0 ? (noShows / total * 100) : 0.0,
      'tasa_cancelacion': total > 0 ? (cancelados / total * 100) : 0.0,
      'servicio_mas_pedido': servicioTop,
      'profesional_mas_ocupado': profesionalTop,
      'dia_mas_ocupado': diaMasOcupado,
      'horario_mas_ocupado': horarioMasOcupado,
      'turnos_por_estado': porEstado,
      'turnos_por_dia': porDia,
      'turnos_por_hora': porHora,
      'turnos_por_servicio': porServicio,
      'turnos_por_profesional': porProfesional,
    };
  }
}
