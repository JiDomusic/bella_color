class Cliente {
  final String id;
  final String tenantId;
  final String nombre;
  final String telefono;
  final String email;
  final String notas;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Cliente({
    required this.id,
    required this.tenantId,
    required this.nombre,
    required this.telefono,
    this.email = '',
    this.notas = '',
    this.createdAt,
    this.updatedAt,
  });

  factory Cliente.fromJson(Map<String, dynamic> json) => Cliente(
    id: json['id'] as String,
    tenantId: json['tenant_id'] as String,
    nombre: json['nombre'] as String,
    telefono: json['telefono'] as String,
    email: json['email'] ?? '',
    notas: json['notas'] ?? '',
    createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
    updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at']) : null,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'tenant_id': tenantId,
    'nombre': nombre,
    'telefono': telefono,
    'email': email,
    'notas': notas,
  };
}
