class ClienteObservacion {
  final String id;
  final String tenantId;
  final String clienteId;
  final String fecha;
  final String servicioNombre;
  final String professionalNombre;
  final String observacion;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ClienteObservacion({
    required this.id,
    required this.tenantId,
    required this.clienteId,
    required this.fecha,
    this.servicioNombre = '',
    this.professionalNombre = '',
    this.observacion = '',
    this.createdAt,
    this.updatedAt,
  });

  factory ClienteObservacion.fromJson(Map<String, dynamic> json) => ClienteObservacion(
    id: json['id'] as String,
    tenantId: json['tenant_id'] as String,
    clienteId: json['cliente_id'] as String,
    fecha: json['fecha'] as String,
    servicioNombre: json['servicio_nombre'] ?? '',
    professionalNombre: json['professional_nombre'] ?? '',
    observacion: json['observacion'] ?? '',
    createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
    updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at']) : null,
  );

  Map<String, dynamic> toJson() => {
    'tenant_id': tenantId,
    'cliente_id': clienteId,
    'fecha': fecha,
    'servicio_nombre': servicioNombre,
    'professional_nombre': professionalNombre,
    'observacion': observacion,
  };
}
