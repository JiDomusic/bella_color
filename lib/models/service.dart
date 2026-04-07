class Service {
  final String id;
  final String tenantId;
  final String nombre;
  final String descripcion;
  final String categoria;
  final int duracionMinutos;
  final double? precio;
  final double? precioEfectivo;
  final double? precioTarjeta;
  final int descuentoEfectivoPct;
  final int descuentoTarjetaPct;
  final String moneda;
  final String? imagenUrl;
  final bool activo;
  final int maxTurnosDia;
  final int orden;
  final bool requiereSena;
  final bool permiteSolapamiento;

  Service({
    required this.id,
    required this.tenantId,
    required this.nombre,
    this.descripcion = '',
    this.categoria = 'otro',
    this.duracionMinutos = 60,
    this.precio,
    this.precioEfectivo,
    this.precioTarjeta,
    this.descuentoEfectivoPct = 0,
    this.descuentoTarjetaPct = 0,
    this.moneda = 'ARS',
    this.imagenUrl,
    this.activo = true,
    this.maxTurnosDia = 8,
    this.orden = 0,
    this.requiereSena = false,
    this.permiteSolapamiento = false,
  });

  /// Precio efectivo con fallback al precio general
  double? get precioEfectivoFinal => precioEfectivo ?? precio;

  /// Precio tarjeta (sin fallback, puede ser null)
  double? get precioTarjetaFinal => precioTarjeta;

  factory Service.fromJson(Map<String, dynamic> json) => Service(
    id: json['id'] as String,
    tenantId: json['tenant_id'] as String,
    nombre: json['nombre'] as String,
    descripcion: json['descripcion'] ?? '',
    categoria: json['categoria'] ?? 'otro',
    duracionMinutos: json['duracion_minutos'] ?? 60,
    precio: json['precio'] != null ? double.tryParse(json['precio'].toString()) : null,
    precioEfectivo: json['precio_efectivo'] != null ? double.tryParse(json['precio_efectivo'].toString()) : null,
    precioTarjeta: json['precio_tarjeta'] != null ? double.tryParse(json['precio_tarjeta'].toString()) : null,
    descuentoEfectivoPct: json['descuento_efectivo_pct'] ?? 0,
    descuentoTarjetaPct: json['descuento_tarjeta_pct'] ?? 0,
    moneda: json['moneda'] ?? 'ARS',
    imagenUrl: json['imagen_url'],
    activo: json['activo'] ?? true,
    maxTurnosDia: json['max_turnos_dia'] ?? 8,
    orden: json['orden'] ?? 0,
    requiereSena: json['requiere_sena'] ?? false,
    permiteSolapamiento: json['permite_solapamiento'] ?? false,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'tenant_id': tenantId,
    'nombre': nombre,
    'descripcion': descripcion,
    'categoria': categoria,
    'duracion_minutos': duracionMinutos,
    'precio': precio,
    'precio_efectivo': precioEfectivo,
    'precio_tarjeta': precioTarjeta,
    'descuento_efectivo_pct': descuentoEfectivoPct,
    'descuento_tarjeta_pct': descuentoTarjetaPct,
    'moneda': moneda,
    'imagen_url': imagenUrl,
    'activo': activo,
    'max_turnos_dia': maxTurnosDia,
    'orden': orden,
    'requiere_sena': requiereSena,
    'permite_solapamiento': permiteSolapamiento,
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
