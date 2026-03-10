class Service {
  final String id;
  final String tenantId;
  final String nombre;
  final String descripcion;
  final String categoria;
  final int duracionMinutos;
  final double? precio;
  final String moneda;
  final String? imagenUrl;
  final bool activo;
  final int maxTurnosDia;
  final int orden;

  Service({
    required this.id,
    required this.tenantId,
    required this.nombre,
    this.descripcion = '',
    this.categoria = 'otro',
    this.duracionMinutos = 60,
    this.precio,
    this.moneda = 'ARS',
    this.imagenUrl,
    this.activo = true,
    this.maxTurnosDia = 8,
    this.orden = 0,
  });

  factory Service.fromJson(Map<String, dynamic> json) => Service(
    id: json['id'] as String,
    tenantId: json['tenant_id'] as String,
    nombre: json['nombre'] as String,
    descripcion: json['descripcion'] ?? '',
    categoria: json['categoria'] ?? 'otro',
    duracionMinutos: json['duracion_minutos'] ?? 60,
    precio: json['precio'] != null ? double.tryParse(json['precio'].toString()) : null,
    moneda: json['moneda'] ?? 'ARS',
    imagenUrl: json['imagen_url'],
    activo: json['activo'] ?? true,
    maxTurnosDia: json['max_turnos_dia'] ?? 8,
    orden: json['orden'] ?? 0,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'tenant_id': tenantId,
    'nombre': nombre,
    'descripcion': descripcion,
    'categoria': categoria,
    'duracion_minutos': duracionMinutos,
    'precio': precio,
    'moneda': moneda,
    'imagen_url': imagenUrl,
    'activo': activo,
    'max_turnos_dia': maxTurnosDia,
    'orden': orden,
  };

  static const categorias = [
    'unas',
    'maquillaje',
    'masajes',
    'depilacion',
    'pestanas',
    'cejas',
    'facial',
    'cabello',
    'corporal',
    'otro',
  ];

  static String categoriaLabel(String cat) {
    const labels = {
      'unas': 'Unas',
      'maquillaje': 'Maquillaje',
      'masajes': 'Masajes',
      'depilacion': 'Depilacion',
      'pestanas': 'Pestanas',
      'cejas': 'Cejas',
      'facial': 'Facial',
      'cabello': 'Cabello',
      'corporal': 'Corporal',
      'otro': 'Otro',
    };
    return labels[cat] ?? cat;
  }
}
