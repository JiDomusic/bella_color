import 'package:flutter/material.dart';
import 'package:simple_barcode_scanner/simple_barcode_scanner.dart';
import '../../config/app_config.dart';
import '../../models/producto.dart';
import '../../models/movimiento_stock.dart';
import '../../services/supabase_service.dart';

class StockTab extends StatefulWidget {
  final Color primary;
  final Color accent;
  /// Callback cuando cambia el stock (para notificaciones)
  final void Function(List<Producto> productosBajoStock)? onStockChanged;

  const StockTab({super.key, required this.primary, required this.accent, this.onStockChanged});

  @override
  State<StockTab> createState() => StockTabState();
}

class StockTabState extends State<StockTab> {
  final _svc = SupabaseService.instance;
  List<Producto> _productos = [];
  String _categoriaFiltro = 'todos';
  bool _loading = true;

  List<Producto> get productosBajoStock => _productos.where((p) => p.stockBajo && p.activo).toList();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _productos = await _svc.loadProductos(
        categoria: _categoriaFiltro == 'todos' ? null : _categoriaFiltro,
      );
    } catch (_) {}
    if (mounted) {
      setState(() => _loading = false);
      widget.onStockChanged?.call(productosBajoStock);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bajoStock = productosBajoStock;
    return Column(
      children: [
        // Hint
        Container(
          width: double.infinity,
          margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppConfig.colorPrimario.withAlpha(15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppConfig.colorPrimario.withAlpha(40)),
          ),
          child: Row(
            children: [
              Icon(Icons.inventory_2_outlined, size: 18, color: AppConfig.colorPrimario.withAlpha(180)),
              const SizedBox(width: 8),
              const Expanded(child: Text(
                'Controla el stock de productos del salon. Usa el scanner para agregar rapido o los botones +/- para ajustar.',
                style: TextStyle(color: AppConfig.colorTextoSecundario, fontSize: 12),
              )),
            ],
          ),
        ),
        // Alerta de stock bajo
        if (bajoStock.isNotEmpty)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppConfig.colorCancelado.withAlpha(20),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppConfig.colorCancelado.withAlpha(60)),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: AppConfig.colorCancelado, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text(
                  'Stock bajo en ${bajoStock.length} producto${bajoStock.length > 1 ? 's' : ''}: ${bajoStock.take(3).map((p) => p.nombre).join(', ')}${bajoStock.length > 3 ? '...' : ''}',
                  style: const TextStyle(color: AppConfig.colorCancelado, fontSize: 12),
                )),
              ],
            ),
          ),
        // Filtro de categoria + boton agregar
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _categoriaFiltro,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppConfig.colorSurfaceVariant,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  dropdownColor: AppConfig.colorFondoCard,
                  style: const TextStyle(color: AppConfig.colorTexto, fontSize: 13),
                  items: [
                    const DropdownMenuItem(value: 'todos', child: Text('Todas las categorias')),
                    ...Producto.categorias.map((c) => DropdownMenuItem(value: c, child: Text(Producto.categoriaLabel(c)))),
                  ],
                  onChanged: (v) {
                    _categoriaFiltro = v ?? 'todos';
                    _load();
                  },
                ),
              ),
              const SizedBox(width: 8),
              FloatingActionButton.small(
                onPressed: _addProductoDialog,
                backgroundColor: widget.accent,
                child: const Icon(Icons.add, color: Colors.white),
              ),
            ],
          ),
        ),
        // Lista de productos
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _productos.isEmpty
                  ? const Center(child: Text('No hay productos. Agrega el primero!', style: TextStyle(color: AppConfig.colorTextoSecundario)))
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: _productos.length,
                        itemBuilder: (_, i) => _productoCard(_productos[i]),
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _productoCard(Producto p) {
    final isLow = p.stockBajo;
    return Card(
      color: AppConfig.colorFondoCard,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: isLow ? AppConfig.colorCancelado.withAlpha(40) : AppConfig.colorSurfaceVariant.withAlpha(80)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.nombre, style: const TextStyle(color: AppConfig.colorTexto, fontWeight: FontWeight.w600, fontSize: 14)),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(Producto.categoriaLabel(p.categoria), style: TextStyle(color: widget.primary, fontSize: 11)),
                      if (p.marca.isNotEmpty) ...[
                        Text(' · ', style: TextStyle(color: AppConfig.colorTextoSecundario.withAlpha(100))),
                        Text(p.marca, style: const TextStyle(color: AppConfig.colorTextoSecundario, fontSize: 11)),
                      ],
                    ],
                  ),
                  if (p.codigoBarras.isNotEmpty)
                    Text('Cod: ${p.codigoBarras}', style: TextStyle(color: AppConfig.colorTextoSecundario.withAlpha(120), fontSize: 10)),
                ],
              ),
            ),
            // Botones +/-
            IconButton(
              onPressed: () => _adjustStock(p, -1),
              icon: const Icon(Icons.remove_circle_outline, color: AppConfig.colorCancelado, size: 28),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 4),
            // Badge de cantidad
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isLow ? AppConfig.colorCancelado.withAlpha(30) : widget.accent.withAlpha(30),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: isLow ? AppConfig.colorCancelado : widget.accent.withAlpha(60)),
              ),
              child: Text(
                '${p.cantidad}',
                style: TextStyle(
                  color: isLow ? AppConfig.colorCancelado : widget.accent,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(width: 4),
            IconButton(
              onPressed: () => _adjustStock(p, 1),
              icon: Icon(Icons.add_circle_outline, color: widget.accent, size: 28),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            // Menu
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, color: AppConfig.colorTextoSecundario.withAlpha(120), size: 20),
              color: AppConfig.colorFondoCard,
              onSelected: (v) {
                if (v == 'edit') _editProductoDialog(p);
                if (v == 'history') _showMovimientos(p);
                if (v == 'delete') _deleteProducto(p);
                if (v == 'adjust') _adjustStockDialog(p);
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'edit', child: Text('Editar', style: TextStyle(color: AppConfig.colorTexto))),
                const PopupMenuItem(value: 'adjust', child: Text('Ajustar stock', style: TextStyle(color: AppConfig.colorTexto))),
                const PopupMenuItem(value: 'history', child: Text('Historial', style: TextStyle(color: AppConfig.colorTexto))),
                const PopupMenuItem(value: 'delete', child: Text('Eliminar', style: TextStyle(color: AppConfig.colorCancelado))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _adjustStock(Producto p, int delta) async {
    try {
      final updated = await _svc.adjustStock(p.id, delta, tipo: delta > 0 ? 'ingreso' : 'egreso');
      await _load();
      if (updated.stockBajo && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Alerta: ${updated.nombre} tiene solo ${updated.cantidad} unidades!'),
            backgroundColor: AppConfig.colorCancelado,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppConfig.colorCancelado),
        );
      }
    }
  }

  void _adjustStockDialog(Producto p) {
    final cantCtrl = TextEditingController();
    String tipo = 'ingreso';
    final motivoCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDState) => AlertDialog(
          backgroundColor: AppConfig.colorFondoCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Ajustar: ${p.nombre}', style: const TextStyle(color: AppConfig.colorTexto, fontSize: 16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Stock actual: ${p.cantidad}', style: const TextStyle(color: AppConfig.colorTextoSecundario)),
              const SizedBox(height: 12),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'ingreso', label: Text('Ingreso (+)')),
                  ButtonSegment(value: 'egreso', label: Text('Egreso (-)')),
                ],
                selected: {tipo},
                onSelectionChanged: (v) => setDState(() => tipo = v.first),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: cantCtrl,
                decoration: const InputDecoration(labelText: 'Cantidad'),
                keyboardType: TextInputType.number,
                style: const TextStyle(color: AppConfig.colorTexto),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: motivoCtrl,
                decoration: const InputDecoration(labelText: 'Motivo (opcional)'),
                style: const TextStyle(color: AppConfig.colorTexto),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () async {
                final cant = int.tryParse(cantCtrl.text) ?? 0;
                if (cant <= 0) return;
                final delta = tipo == 'ingreso' ? cant : -cant;
                await _svc.adjustStock(p.id, delta, tipo: tipo, motivo: motivoCtrl.text.trim());
                await _load();
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Confirmar'),
            ),
          ],
        ),
      ),
    );
  }

  void _addProductoDialog({String? barcode}) {
    final nameCtrl = TextEditingController();
    final marcaCtrl = TextEditingController();
    final barcodeCtrl = TextEditingController(text: barcode ?? '');
    final cantCtrl = TextEditingController(text: '1');
    final alertCtrl = TextEditingController(text: '5');
    String selectedCat = 'otro';

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDState) => AlertDialog(
          backgroundColor: AppConfig.colorFondoCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Nuevo Producto', style: TextStyle(color: AppConfig.colorTexto)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Nombre del producto'),
                  style: const TextStyle(color: AppConfig.colorTexto),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: marcaCtrl,
                  decoration: const InputDecoration(labelText: 'Marca (opcional)'),
                  style: const TextStyle(color: AppConfig.colorTexto),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: barcodeCtrl,
                        decoration: const InputDecoration(labelText: 'Codigo de barras'),
                        style: const TextStyle(color: AppConfig.colorTexto),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () => _scanBarcode(barcodeCtrl, setDState),
                      icon: Icon(Icons.qr_code_scanner, color: widget.accent, size: 28),
                      tooltip: 'Escanear',
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: selectedCat,
                  decoration: const InputDecoration(labelText: 'Categoria'),
                  dropdownColor: AppConfig.colorFondoCard,
                  style: const TextStyle(color: AppConfig.colorTexto),
                  items: Producto.categorias.map((c) => DropdownMenuItem(value: c, child: Text(Producto.categoriaLabel(c)))).toList(),
                  onChanged: (v) => setDState(() => selectedCat = v!),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: cantCtrl,
                        decoration: const InputDecoration(labelText: 'Cantidad'),
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: AppConfig.colorTexto),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: alertCtrl,
                        decoration: const InputDecoration(labelText: 'Alerta minimo'),
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: AppConfig.colorTexto),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty) return;
                try {
                  await _svc.createProducto({
                    'nombre': nameCtrl.text.trim(),
                    'marca': marcaCtrl.text.trim(),
                    'codigo_barras': barcodeCtrl.text.trim(),
                    'cantidad': int.tryParse(cantCtrl.text) ?? 1,
                    'categoria': selectedCat,
                    'min_stock_alerta': int.tryParse(alertCtrl.text) ?? 5,
                  });
                  await _load();
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Producto "${nameCtrl.text.trim()}" creado'),
                        backgroundColor: Colors.green),
                    );
                  }
                } catch (e) {
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error al crear producto: $e'),
                        backgroundColor: Colors.red),
                    );
                  }
                }
              },
              child: const Text('Crear'),
            ),
          ],
        ),
      ),
    );
  }

  void _editProductoDialog(Producto p) {
    final nameCtrl = TextEditingController(text: p.nombre);
    final marcaCtrl = TextEditingController(text: p.marca);
    final barcodeCtrl = TextEditingController(text: p.codigoBarras);
    final alertCtrl = TextEditingController(text: p.minStockAlerta.toString());
    String selectedCat = p.categoria;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDState) => AlertDialog(
          backgroundColor: AppConfig.colorFondoCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Editar Producto', style: TextStyle(color: AppConfig.colorTexto)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Nombre'),
                  style: const TextStyle(color: AppConfig.colorTexto),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: marcaCtrl,
                  decoration: const InputDecoration(labelText: 'Marca'),
                  style: const TextStyle(color: AppConfig.colorTexto),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: barcodeCtrl,
                        decoration: const InputDecoration(labelText: 'Codigo de barras'),
                        style: const TextStyle(color: AppConfig.colorTexto),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () => _scanBarcode(barcodeCtrl, setDState),
                      icon: Icon(Icons.qr_code_scanner, color: widget.accent, size: 28),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: selectedCat,
                  decoration: const InputDecoration(labelText: 'Categoria'),
                  dropdownColor: AppConfig.colorFondoCard,
                  style: const TextStyle(color: AppConfig.colorTexto),
                  items: Producto.categorias.map((c) => DropdownMenuItem(value: c, child: Text(Producto.categoriaLabel(c)))).toList(),
                  onChanged: (v) => setDState(() => selectedCat = v!),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: alertCtrl,
                  decoration: const InputDecoration(labelText: 'Alerta minimo'),
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: AppConfig.colorTexto),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty) return;
                await _svc.updateProducto(p.id, {
                  'nombre': nameCtrl.text.trim(),
                  'marca': marcaCtrl.text.trim(),
                  'codigo_barras': barcodeCtrl.text.trim(),
                  'categoria': selectedCat,
                  'min_stock_alerta': int.tryParse(alertCtrl.text) ?? 5,
                });
                await _load();
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteProducto(Producto p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppConfig.colorFondoCard,
        title: Text('Eliminar ${p.nombre}?', style: const TextStyle(color: AppConfig.colorTexto)),
        content: const Text('Se eliminara el producto y su historial de movimientos.', style: TextStyle(color: AppConfig.colorTextoSecundario)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppConfig.colorCancelado),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await _svc.deleteProducto(p.id);
      await _load();
    }
  }

  void _showMovimientos(Producto p) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppConfig.colorFondoCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => FutureBuilder<List<MovimientoStock>>(
        future: _svc.loadMovimientosStock(p.id),
        builder: (ctx, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final movs = snap.data!;
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppConfig.colorSurfaceVariant, borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 16),
                Text('Historial: ${p.nombre}', style: const TextStyle(color: AppConfig.colorTexto, fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                if (movs.isEmpty)
                  const Text('Sin movimientos.', style: TextStyle(color: AppConfig.colorTextoSecundario))
                else
                  ...movs.take(20).map((m) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Icon(
                          m.cantidad > 0 ? Icons.arrow_upward : Icons.arrow_downward,
                          color: m.cantidad > 0 ? AppConfig.colorConfirmado : AppConfig.colorCancelado,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${m.cantidad > 0 ? '+' : ''}${m.cantidad}',
                          style: TextStyle(
                            color: m.cantidad > 0 ? AppConfig.colorConfirmado : AppConfig.colorCancelado,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(m.tipo, style: const TextStyle(color: AppConfig.colorTextoSecundario, fontSize: 12)),
                        if (m.motivo.isNotEmpty) ...[
                          Text(' · ', style: TextStyle(color: AppConfig.colorTextoSecundario.withAlpha(100))),
                          Expanded(child: Text(m.motivo, style: const TextStyle(color: AppConfig.colorTextoSecundario, fontSize: 12), overflow: TextOverflow.ellipsis)),
                        ] else
                          const Spacer(),
                        Text(
                          m.createdAt != null ? '${m.createdAt!.day}/${m.createdAt!.month}' : '',
                          style: TextStyle(color: AppConfig.colorTextoSecundario.withAlpha(120), fontSize: 11),
                        ),
                      ],
                    ),
                  )),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Escanear codigo de barras con camara o ingreso manual.
  Future<void> _scanBarcode(TextEditingController ctrl, StateSetter setDState) async {
    final result = await _doScan();
    if (result != null && result.isNotEmpty) {
      setDState(() => ctrl.text = result);
      final existing = await _svc.findProductoByBarcode(result);
      if (existing != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Producto encontrado: ${existing.nombre} (stock: ${existing.cantidad})'),
            backgroundColor: widget.accent,
            action: SnackBarAction(
              label: 'Sumar +1',
              textColor: Colors.white,
              onPressed: () => _adjustStock(existing, 1),
            ),
          ),
        );
      }
    }
  }

  /// Metodo publico para escanear desde afuera
  void scanAndAdd() async {
    final result = await _doScan();
    if (result != null && result.isNotEmpty) {
      final existing = await _svc.findProductoByBarcode(result);
      if (existing != null) {
        await _adjustStock(existing, 1);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('+1 ${existing.nombre} (stock: ${existing.cantidad + 1})'), backgroundColor: widget.accent),
          );
        }
      } else {
        _addProductoDialog(barcode: result);
      }
    }
  }

  /// Intenta usar el scanner de camara, con fallback a ingreso manual.
  Future<String?> _doScan() async {
    // Mostrar opciones: camara o manual
    final mode = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppConfig.colorFondoCard,
        title: const Text('Codigo de barras', style: TextStyle(color: AppConfig.colorTexto)),
        content: const Text('Como queres ingresar el codigo?', style: TextStyle(color: AppConfig.colorTextoSecundario)),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.pop(context, 'camara'),
            icon: const Icon(Icons.camera_alt),
            label: const Text('Camara'),
          ),
          TextButton.icon(
            onPressed: () => Navigator.pop(context, 'manual'),
            icon: const Icon(Icons.keyboard),
            label: const Text('Manual'),
          ),
        ],
      ),
    );
    if (mode == null) return null;

    if (mode == 'camara') {
      try {
        final res = await Navigator.of(context).push<String>(
          MaterialPageRoute(builder: (_) => const SimpleBarcodeScannerPage()),
        );
        if (res != null && res != '-1' && res.isNotEmpty) return res;
        return null;
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: const Text('Error con la camara. Ingresa manualmente.'), backgroundColor: AppConfig.colorPendiente),
          );
        }
        return _manualInput();
      }
    } else {
      return _manualInput();
    }
  }

  Future<String?> _manualInput() async {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppConfig.colorFondoCard,
        title: const Text('Ingresar codigo', style: TextStyle(color: AppConfig.colorTexto)),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(labelText: 'Codigo de barras'),
          style: const TextStyle(color: AppConfig.colorTexto, fontSize: 18, letterSpacing: 2),
          keyboardType: TextInputType.number,
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, ctrl.text.trim()),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
