class Appointment {
  final String id;
  final String tenantId;
  final String fecha;
  final String hora;
  final int duracionMinutos;
  final String nombreCliente;
  final String telefono;
  final String? email;
  final String? servicioId;
  final String? servicioNombre;
  final String? professionalId;
  final String? professionalNombre;
  final String codigoConfirmacion;
  final String estado;
  final bool confirmadoCliente;
  final DateTime? confirmadoAt;
  final String? comentarios;
  final bool recordatorioEnviado;
  final DateTime? recordatorioEnviadoAt;
  final DateTime? createdAt;
  final double? precio;

  Appointment({
    required this.id,
    required this.tenantId,
    required this.fecha,
    required this.hora,
    this.duracionMinutos = 60,
    required this.nombreCliente,
    required this.telefono,
    this.email,
    this.servicioId,
    this.servicioNombre,
    this.professionalId,
    this.professionalNombre,
    required this.codigoConfirmacion,
    this.estado = 'pendiente_confirmacion',
    this.confirmadoCliente = false,
    this.confirmadoAt,
    this.comentarios,
    this.recordatorioEnviado = false,
    this.recordatorioEnviadoAt,
    this.createdAt,
    this.precio,
  });

  factory Appointment.fromJson(Map<String, dynamic> json) => Appointment(
    id: json['id'] as String,
    tenantId: json['tenant_id'] as String,
    fecha: json['fecha'] as String,
    hora: json['hora'] as String,
    duracionMinutos: json['duracion_minutos'] ?? 60,
    nombreCliente: json['nombre_cliente'] as String,
    telefono: json['telefono'] as String,
    email: json['email'],
    servicioId: json['servicio_id'],
    servicioNombre: json['servicio_nombre'],
    professionalId: json['professional_id'],
    professionalNombre: json['professional_nombre'],
    codigoConfirmacion: json['codigo_confirmacion'] as String,
    estado: json['estado'] ?? 'pendiente_confirmacion',
    confirmadoCliente: json['confirmado_cliente'] ?? false,
    confirmadoAt: json['confirmado_at'] != null ? DateTime.tryParse(json['confirmado_at']) : null,
    comentarios: json['comentarios'],
    recordatorioEnviado: json['recordatorio_enviado'] ?? false,
    recordatorioEnviadoAt: json['recordatorio_enviado_at'] != null
        ? DateTime.tryParse(json['recordatorio_enviado_at'])
        : null,
    createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
    precio: (json['precio'] as num?)?.toDouble(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'tenant_id': tenantId,
    'fecha': fecha,
    'hora': hora,
    'duracion_minutos': duracionMinutos,
    'nombre_cliente': nombreCliente,
    'telefono': telefono,
    'email': email,
    'servicio_id': servicioId,
    'servicio_nombre': servicioNombre,
    'professional_id': professionalId,
    'professional_nombre': professionalNombre,
    'codigo_confirmacion': codigoConfirmacion,
    'estado': estado,
    'confirmado_cliente': confirmadoCliente,
    'comentarios': comentarios,
    'precio': precio,
  };

  bool get isPending => estado == 'pendiente_confirmacion';
  bool get isConfirmed => estado == 'confirmada';
  bool get isInProgress => estado == 'en_atencion';
  bool get isCompleted => estado == 'completada';
  bool get isCancelled => estado == 'cancelada';
  bool get isNoShow => estado == 'no_show';

  static const estados = [
    'pendiente_confirmacion',
    'confirmada',
    'en_atencion',
    'completada',
    'no_show',
    'cancelada',
  ];

  static String estadoLabel(String estado) {
    const labels = {
      'pendiente_confirmacion': 'Pendiente',
      'confirmada': 'Confirmada',
      'en_atencion': 'En atencion',
      'completada': 'Completada',
      'no_show': 'No asistio',
      'cancelada': 'Cancelada',
    };
    return labels[estado] ?? estado;
  }
}
