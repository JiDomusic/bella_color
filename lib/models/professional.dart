class Professional {
  final String id;
  final String tenantId;
  final String nombre;
  final String especialidad;
  final String descripcion;
  final String? fotoUrl;
  final String telefono;
  final bool activo;
  final int orden;

  Professional({
    required this.id,
    required this.tenantId,
    required this.nombre,
    this.especialidad = '',
    this.descripcion = '',
    this.fotoUrl,
    this.telefono = '',
    this.activo = true,
    this.orden = 0,
  });

  factory Professional.fromJson(Map<String, dynamic> json) => Professional(
    id: json['id'] as String,
    tenantId: json['tenant_id'] as String,
    nombre: json['nombre'] as String,
    especialidad: json['especialidad'] ?? '',
    descripcion: json['descripcion'] ?? '',
    fotoUrl: json['foto_url'],
    telefono: json['telefono'] ?? '',
    activo: json['activo'] ?? true,
    orden: json['orden'] ?? 0,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'tenant_id': tenantId,
    'nombre': nombre,
    'especialidad': especialidad,
    'descripcion': descripcion,
    'foto_url': fotoUrl,
    'telefono': telefono,
    'activo': activo,
    'orden': orden,
  };
}
