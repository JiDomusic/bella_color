class MovimientoStock {
  final String id;
  final String tenantId;
  final String productoId;
  final int cantidad;
  final String tipo;
  final String motivo;
  final DateTime? createdAt;

  MovimientoStock({
    required this.id,
    required this.tenantId,
    required this.productoId,
    required this.cantidad,
    this.tipo = 'ajuste',
    this.motivo = '',
    this.createdAt,
  });

  factory MovimientoStock.fromJson(Map<String, dynamic> json) => MovimientoStock(
    id: json['id'] as String,
    tenantId: json['tenant_id'] as String,
    productoId: json['producto_id'] as String,
    cantidad: json['cantidad'] as int,
    tipo: json['tipo'] ?? 'ajuste',
    motivo: json['motivo'] ?? '',
    createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
  );

  Map<String, dynamic> toJson() => {
    'tenant_id': tenantId,
    'producto_id': productoId,
    'cantidad': cantidad,
    'tipo': tipo,
    'motivo': motivo,
  };
}
