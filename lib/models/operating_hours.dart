class OperatingHours {
  final String id;
  final String tenantId;
  final int diaSemana;
  final String horaInicio;
  final String horaFin;
  final int intervaloMinutos;

  OperatingHours({
    required this.id,
    required this.tenantId,
    required this.diaSemana,
    required this.horaInicio,
    required this.horaFin,
    this.intervaloMinutos = 30,
  });

  factory OperatingHours.fromJson(Map<String, dynamic> json) => OperatingHours(
    id: json['id'] as String,
    tenantId: json['tenant_id'] as String,
    diaSemana: json['dia_semana'] as int,
    horaInicio: json['hora_inicio'] as String,
    horaFin: json['hora_fin'] as String,
    intervaloMinutos: json['intervalo_minutos'] ?? 30,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'tenant_id': tenantId,
    'dia_semana': diaSemana,
    'hora_inicio': horaInicio,
    'hora_fin': horaFin,
    'intervalo_minutos': intervaloMinutos,
  };

  static String dayName(int day) {
    const days = ['Domingo', 'Lunes', 'Martes', 'Miercoles', 'Jueves', 'Viernes', 'Sabado'];
    return days[day % 7];
  }

  static String dayShort(int day) {
    const days = ['Dom', 'Lun', 'Mar', 'Mie', 'Jue', 'Vie', 'Sab'];
    return days[day % 7];
  }
}
