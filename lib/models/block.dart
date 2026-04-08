class Block {
  final String id;
  final String tenantId;
  final String? fecha;
  final String? hora;
  final String? professionalId;
  final String motivo;
  final bool diaCompleto;
  final String? categoria;

  Block({
    required this.id,
    required this.tenantId,
    this.fecha,
    this.hora,
    this.professionalId,
    this.motivo = '',
    this.diaCompleto = false,
    this.categoria,
  });

  factory Block.fromJson(Map<String, dynamic> json) => Block(
    id: json['id'] as String,
    tenantId: json['tenant_id'] as String,
    fecha: json['fecha'],
    hora: json['hora'],
    professionalId: json['professional_id'],
    motivo: json['motivo'] ?? '',
    diaCompleto: json['dia_completo'] ?? false,
    categoria: json['categoria'],
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'tenant_id': tenantId,
    'fecha': fecha,
    'hora': hora,
    'professional_id': professionalId,
    'motivo': motivo,
    'dia_completo': diaCompleto,
    'categoria': categoria,
  };
}
