class Producto {
  final String id;
  final String tenantId;
  final String nombre;
  final String marca;
  final String codigoBarras;
  final int cantidad;
  final String categoria;
  final int minStockAlerta;
  final double? precioCosto;
  final double? precioVenta;
  final String notas;
  final bool activo;
  final DateTime? createdAt;

  Producto({
    required this.id,
    required this.tenantId,
    required this.nombre,
    this.marca = '',
    this.codigoBarras = '',
    this.cantidad = 0,
    this.categoria = 'otro',
    this.minStockAlerta = 5,
    this.precioCosto,
    this.precioVenta,
    this.notas = '',
    this.activo = true,
    this.createdAt,
  });

  bool get stockBajo => cantidad < minStockAlerta;

  factory Producto.fromJson(Map<String, dynamic> json) => Producto(
    id: json['id'] as String,
    tenantId: json['tenant_id'] as String,
    nombre: json['nombre'] as String,
    marca: json['marca'] ?? '',
    codigoBarras: json['codigo_barras'] ?? '',
    cantidad: json['cantidad'] ?? 0,
    categoria: json['categoria'] ?? 'otro',
    minStockAlerta: json['min_stock_alerta'] ?? 5,
    precioCosto: json['precio_costo'] != null ? double.tryParse(json['precio_costo'].toString()) : null,
    precioVenta: json['precio_venta'] != null ? double.tryParse(json['precio_venta'].toString()) : null,
    notas: json['notas'] ?? '',
    activo: json['activo'] ?? true,
    createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
  );

  Map<String, dynamic> toJson() => {
    'tenant_id': tenantId,
    'nombre': nombre,
    'marca': marca,
    'codigo_barras': codigoBarras,
    'cantidad': cantidad,
    'categoria': categoria,
    'min_stock_alerta': minStockAlerta,
    'precio_costo': precioCosto,
    'precio_venta': precioVenta,
    'notas': notas,
    'activo': activo,
  };

  static const categorias = [
    'unas',
    'cejas',
    'color',
    'peluqueria',
    'maquillaje',
    'depilacion',
    'pestanas',
    'cuidado_capilar',
    'corporal',
    'otro',
  ];

  static String categoriaLabel(String cat) {
    const labels = {
      'unas': 'Unas',
      'cejas': 'Cejas',
      'color': 'Color / Tintura',
      'peluqueria': 'Peluqueria',
      'maquillaje': 'Maquillaje',
      'depilacion': 'Depilacion',
      'pestanas': 'Pestanas',
      'cuidado_capilar': 'Cuidado Capilar',
      'corporal': 'Corporal',
      'otro': 'Otro',
    };
    return labels[cat] ?? cat;
  }
}
