class WaitlistEntry {
  final String id;
  final String tenantId;
  final String fecha;
  final String? hora;
  final String? servicioId;
  final String? professionalId;
  final String nombre;
  final String telefono;
  final String? email;
  final String? comentarios;
  final String estado;
  final bool notificado;
  final DateTime? notificadoAt;
  final DateTime? createdAt;

  WaitlistEntry({
    required this.id,
    required this.tenantId,
    required this.fecha,
    this.hora,
    this.servicioId,
    this.professionalId,
    required this.nombre,
    required this.telefono,
    this.email,
    this.comentarios,
    this.estado = 'esperando',
    this.notificado = false,
    this.notificadoAt,
    this.createdAt,
  });

  factory WaitlistEntry.fromJson(Map<String, dynamic> json) => WaitlistEntry(
    id: json['id'] as String,
    tenantId: json['tenant_id'] as String,
    fecha: json['fecha'] as String,
    hora: json['hora'],
    servicioId: json['servicio_id'],
    professionalId: json['professional_id'],
    nombre: json['nombre'] as String,
    telefono: json['telefono'] as String,
    email: json['email'],
    comentarios: json['comentarios'],
    estado: json['estado'] ?? 'esperando',
    notificado: json['notificado'] ?? false,
    notificadoAt: json['notificado_at'] != null ? DateTime.tryParse(json['notificado_at']) : null,
    createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'tenant_id': tenantId,
    'fecha': fecha,
    'hora': hora,
    'servicio_id': servicioId,
    'professional_id': professionalId,
    'nombre': nombre,
    'telefono': telefono,
    'email': email,
    'comentarios': comentarios,
    'estado': estado,
  };
}
