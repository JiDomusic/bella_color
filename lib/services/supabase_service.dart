import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/app_config.dart';
import '../models/tenant.dart';
import '../models/professional.dart';
import '../models/service.dart';
import '../models/appointment.dart';
import '../models/operating_hours.dart';
import '../models/block.dart';
import '../models/waitlist_entry.dart';
import '../models/cliente.dart';
import '../models/cliente_observacion.dart';
import '../models/producto.dart';
import '../models/movimiento_stock.dart';

class SupabaseService {
  static final SupabaseService instance = SupabaseService._();
  SupabaseService._();

  late SupabaseClient _client;
  String _tenantId = 'demo';
  Tenant? _currentTenant;

  SupabaseClient get client => _client;
  String get tenantId => _tenantId;
  Tenant? get currentTenant => _currentTenant;
  bool get isLoggedIn => _client.auth.currentUser != null;
  String? get currentUserId => _client.auth.currentUser?.id;

  Future<void> initialize() async {
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      anonKey: AppConfig.supabaseAnonKey,
    );
    _client = Supabase.instance.client;
  }

  void setTenantId(String id) {
    _tenantId = id;
    _currentTenant = null;
  }

  // ---- Auth ----
  Future<AuthResponse> signIn(String email, String password) async {
    return await _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<AuthResponse> signUp(String email, String password) async {
    return await _client.auth.signUp(email: email, password: password);
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  Future<void> changePassword(String newPassword) async {
    await _client.auth.updateUser(UserAttributes(password: newPassword));
  }

  Future<String?> getTenantIdForCurrentUser() async {
    final uid = currentUserId;
    if (uid == null) return null;
    final res = await _client.from('tenants').select('id').eq('admin_user_id', uid).maybeSingle();
    return res?['id'] as String?;
  }

  // ---- Tenant ----
  Future<Tenant> loadTenant() async {
    try {
      // Intenta con funcion server-side que valida bloqueo/vencimiento
      final res = await _client.rpc('get_tenant_validated', params: {'p_id': _tenantId});
      if (res != null) {
        _currentTenant = Tenant.fromJson(res);
        return _currentTenant!;
      }
    } catch (_) {
      // Si la funcion no existe, usa query directa
    }
    final res = await _client.from('tenants').select().eq('id', _tenantId).maybeSingle();
    if (res == null) {
      throw Exception('Salon no encontrado.');
    }
    _currentTenant = Tenant.fromJson(res);
    return _currentTenant!;
  }

  Future<List<Tenant>> loadAllTenants() async {
    try {
      final res = await _client.rpc('list_all_tenants');
      return (res as List).map<Tenant>((e) => Tenant.fromJson(e)).toList();
    } catch (_) {
      final res = await _client.from('tenants').select().order('nombre_salon');
      return res.map<Tenant>((e) => Tenant.fromJson(e)).toList();
    }
  }

  Future<Tenant> createTenant(Map<String, dynamic> data) async {
    try {
      final res = await _client.rpc('create_tenant', params: {
        'p_id': data['id'],
        'p_nombre_salon': data['nombre_salon'],
        'p_admin_user_id': data['admin_user_id'],
        'p_subscription_start_date': data['subscription_start_date'],
        'p_trial_days': data['trial_days'] ?? 15,
      });
      return Tenant.fromJson(res);
    } catch (_) {
      final res = await _client.from('tenants').insert(data).select().single();
      return Tenant.fromJson(res);
    }
  }

  Future<void> updateTenant(Map<String, dynamic> data) async {
    await _client.from('tenants').update(data).eq('id', _tenantId);
    _currentTenant = null;
  }

  /// Elimina un salon y todos sus datos relacionados via SECURITY DEFINER.
  Future<void> deleteTenant(String id) async {
    await _client.rpc('delete_tenant', params: {'p_id': id});
  }

  Future<void> blockTenant(String id, String reason) async {
    try {
      await _client.rpc('block_tenant', params: {'p_id': id, 'p_reason': reason});
    } catch (_) {
      await _client.from('tenants').update({
        'is_blocked': true,
        'blocked_at': DateTime.now().toIso8601String(),
        'block_reason': reason,
      }).eq('id', id);
    }
  }

  Future<void> unblockTenant(String id) async {
    try {
      await _client.rpc('unblock_tenant', params: {'p_id': id});
    } catch (_) {
      await _client.from('tenants').update({
        'is_blocked': false,
        'blocked_at': null,
        'block_reason': '',
      }).eq('id', id);
    }
  }

  // ---- Trial Bonus ----

  /// Extiende el trial 5 días más por completar onboarding.
  /// Solo se puede usar una vez.
  Future<bool> extendTrialForOnboarding() async {
    final row = await _client
        .from('tenants')
        .select('trial_end_date, trial_extended')
        .eq('id', _tenantId)
        .maybeSingle();
    if (row == null) return false;
    if (row['trial_extended'] == true) return false;

    final currentEnd = DateTime.tryParse(row['trial_end_date'] ?? '') ?? DateTime.now();
    final newEnd = currentEnd.add(const Duration(days: 5)).toIso8601String();

    await _client.from('tenants').update({
      'trial_end_date': newEnd,
      'trial_extended': true,
    }).eq('id', _tenantId);
    return true;
  }

  // ---- Professionals ----
  Future<List<Professional>> loadProfessionals() async {
    final res = await _client
        .from('professionals')
        .select()
        .eq('tenant_id', _tenantId)
        .order('orden');
    return res.map<Professional>((e) => Professional.fromJson(e)).toList();
  }

  Future<List<Professional>> loadActiveProfessionals() async {
    final res = await _client
        .from('professionals')
        .select()
        .eq('tenant_id', _tenantId)
        .eq('activo', true)
        .order('orden');
    return res.map<Professional>((e) => Professional.fromJson(e)).toList();
  }

  Future<Professional> createProfessional(Map<String, dynamic> data) async {
    data['tenant_id'] = _tenantId;
    final res = await _client.from('professionals').insert(data).select().single();
    return Professional.fromJson(res);
  }

  Future<void> updateProfessional(String id, Map<String, dynamic> data) async {
    await _client.from('professionals').update(data).eq('id', id);
  }

  Future<void> deleteProfessional(String id) async {
    await _client.from('professionals').delete().eq('id', id);
  }

  // ---- Services ----
  Future<List<Service>> loadServices() async {
    final res = await _client
        .from('services')
        .select()
        .eq('tenant_id', _tenantId)
        .order('orden');
    return res.map<Service>((e) => Service.fromJson(e)).toList();
  }

  Future<List<Service>> loadActiveServices() async {
    final res = await _client
        .from('services')
        .select()
        .eq('tenant_id', _tenantId)
        .eq('activo', true)
        .order('orden');
    return res.map<Service>((e) => Service.fromJson(e)).toList();
  }

  Future<Service> createService(Map<String, dynamic> data) async {
    data['tenant_id'] = _tenantId;
    final res = await _client.from('services').insert(data).select().single();
    return Service.fromJson(res);
  }

  Future<void> updateService(String id, Map<String, dynamic> data) async {
    await _client.from('services').update(data).eq('id', id);
  }

  Future<void> deleteService(String id) async {
    await _client.from('services').delete().eq('id', id);
  }

  // ---- Professional Services ----
  Future<List<Map<String, dynamic>>> loadProfessionalServices() async {
    return await _client
        .from('professional_services')
        .select()
        .eq('tenant_id', _tenantId);
  }

  Future<void> assignProfessionalService(String professionalId, String serviceId, {double? precioEspecial}) async {
    await _client.from('professional_services').insert({
      'tenant_id': _tenantId,
      'professional_id': professionalId,
      'service_id': serviceId,
      'precio_especial': precioEspecial,
    });
  }

  Future<void> removeProfessionalService(String professionalId, String serviceId) async {
    await _client
        .from('professional_services')
        .delete()
        .eq('professional_id', professionalId)
        .eq('service_id', serviceId);
  }

  // ---- Portfolio Images ----
  Future<List<Map<String, dynamic>>> loadPortfolioImages({String? professionalId}) async {
    var query = _client.from('portfolio_images').select().eq('tenant_id', _tenantId);
    if (professionalId != null) {
      query = query.eq('professional_id', professionalId);
    }
    return await query.order('created_at', ascending: false);
  }

  Future<void> addPortfolioImage(Map<String, dynamic> data) async {
    data['tenant_id'] = _tenantId;
    await _client.from('portfolio_images').insert(data);
  }

  Future<void> deletePortfolioImage(String id) async {
    await _client.from('portfolio_images').delete().eq('id', id);
  }

  // ---- Operating Hours ----
  Future<List<OperatingHours>> loadOperatingHours() async {
    final res = await _client
        .from('operating_hours')
        .select()
        .eq('tenant_id', _tenantId)
        .order('dia_semana');
    return res.map<OperatingHours>((e) => OperatingHours.fromJson(e)).toList();
  }

  Future<void> setOperatingHours(List<Map<String, dynamic>> hours) async {
    await _client.from('operating_hours').delete().eq('tenant_id', _tenantId);
    for (final h in hours) {
      h['tenant_id'] = _tenantId;
    }
    if (hours.isNotEmpty) {
      await _client.from('operating_hours').insert(hours);
    }
  }

  /// Devuelve los telefonos de clientas con 3+ turnos completados (frecuentes).
  /// Solo cuenta turnos del tenant actual, no expone datos entre tenants.
  Future<Set<String>> loadFrequentClientPhones() async {
    final res = await _client
        .from('appointments')
        .select('telefono')
        .eq('tenant_id', _tenantId)
        .eq('estado', 'completada');
    final counts = <String, int>{};
    for (final row in res) {
      final tel = row['telefono'] as String? ?? '';
      if (tel.isNotEmpty) counts[tel] = (counts[tel] ?? 0) + 1;
    }
    return counts.entries.where((e) => e.value >= 3).map((e) => e.key).toSet();
  }

  // ---- Appointments ----
  Future<List<Appointment>> loadAppointments({String? fecha, String? estado}) async {
    var query = _client.from('appointments').select().eq('tenant_id', _tenantId);
    if (fecha != null) query = query.eq('fecha', fecha);
    if (estado != null) query = query.eq('estado', estado);
    final res = await query.order('hora');
    return res.map<Appointment>((e) => Appointment.fromJson(e)).toList();
  }

  Future<List<Appointment>> loadAppointmentsByDate(String fecha) async {
    final res = await _client
        .from('appointments')
        .select()
        .eq('tenant_id', _tenantId)
        .eq('fecha', fecha)
        .inFilter('estado', ['pendiente_confirmacion', 'confirmada', 'en_atencion'])
        .order('hora');
    return res.map<Appointment>((e) => Appointment.fromJson(e)).toList();
  }

  Future<Appointment> createAppointment(Map<String, dynamic> data) async {
    data['tenant_id'] = _tenantId;
    final res = await _client.from('appointments').insert(data).select().single();
    return Appointment.fromJson(res);
  }

  Future<void> updateAppointmentStatus(String id, String estado) async {
    final update = <String, dynamic>{'estado': estado};
    if (estado == 'confirmada') {
      update['confirmado_cliente'] = true;
      update['confirmado_at'] = DateTime.now().toIso8601String();
    }
    await _client.from('appointments').update(update).eq('id', id);
  }

  Future<void> markReminderSent(String id) async {
    await _client.from('appointments').update({
      'recordatorio_enviado': true,
      'recordatorio_enviado_at': DateTime.now().toIso8601String(),
    }).eq('id', id);
  }

  Future<List<Appointment>> loadTomorrowConfirmedAppointments() async {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final fecha = '${tomorrow.year}-${tomorrow.month.toString().padLeft(2, '0')}-${tomorrow.day.toString().padLeft(2, '0')}';
    final res = await _client
        .from('appointments')
        .select()
        .eq('tenant_id', _tenantId)
        .eq('fecha', fecha)
        .eq('estado', 'confirmada')
        .order('hora');
    return res.map<Appointment>((e) => Appointment.fromJson(e)).toList();
  }

  Future<void> deleteAppointment(String id) async {
    await _client.from('appointments').delete().eq('id', id);
  }

  Future<Appointment?> findAppointmentByCode(String code) async {
    final res = await _client
        .from('appointments')
        .select()
        .eq('tenant_id', _tenantId)
        .eq('codigo_confirmacion', code)
        .maybeSingle();
    return res != null ? Appointment.fromJson(res) : null;
  }

  // ---- Blocks ----
  Future<List<Block>> loadBlocks({String? fecha}) async {
    var query = _client.from('blocks').select().eq('tenant_id', _tenantId);
    if (fecha != null) query = query.eq('fecha', fecha);
    final res = await query;
    return res.map<Block>((e) => Block.fromJson(e)).toList();
  }

  Future<void> createBlock(Map<String, dynamic> data) async {
    data['tenant_id'] = _tenantId;
    await _client.from('blocks').insert(data);
  }

  Future<void> deleteBlock(String id) async {
    await _client.from('blocks').delete().eq('id', id);
  }

  // ---- Waitlist ----
  Future<List<WaitlistEntry>> loadWaitlist({String? fecha}) async {
    var query = _client.from('waitlist').select().eq('tenant_id', _tenantId);
    if (fecha != null) query = query.eq('fecha', fecha);
    final res = await query.order('created_at');
    return res.map<WaitlistEntry>((e) => WaitlistEntry.fromJson(e)).toList();
  }

  Future<void> addToWaitlist(Map<String, dynamic> data) async {
    data['tenant_id'] = _tenantId;
    await _client.from('waitlist').insert(data);
  }

  Future<void> updateWaitlistEntry(String id, Map<String, dynamic> data) async {
    await _client.from('waitlist').update(data).eq('id', id);
  }

  Future<void> deleteWaitlistEntry(String id) async {
    await _client.from('waitlist').delete().eq('id', id);
  }

  // ---- Crear usuario auth via Admin API de Supabase ----
  /// La service_role_key se pasa via --dart-define=SRK=... al compilar.
  Future<String> createAuthUser(String email, String password) async {
    const serviceKey = String.fromEnvironment('SRK');
    if (serviceKey.isEmpty) {
      throw Exception('Configuración de servicio no disponible. Contacte al administrador.');
    }
    const url = '${AppConfig.supabaseUrl}/auth/v1/admin/users';

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'apikey': serviceKey,
        'Authorization': 'Bearer $serviceKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'email': email,
        'password': password,
        'email_confirm': true,
      }),
    );

    if (response.statusCode != 200) {
      final body = jsonDecode(response.body);
      throw Exception(body['msg'] ?? body['message'] ?? 'Error al crear usuario');
    }

    final body = jsonDecode(response.body);
    final userId = body['id'] as String?;
    if (userId == null) {
      throw Exception('No se pudo obtener el ID del usuario creado');
    }
    return userId;
  }

  // ---- Resetear contraseña de usuario via Admin API ----
  Future<void> resetAuthUserPassword(String userId, String newPassword) async {
    const serviceKey = String.fromEnvironment('SRK');
    if (serviceKey.isEmpty) {
      throw Exception('Configuracion de servicio no disponible. Contacte al administrador.');
    }
    final url = '${AppConfig.supabaseUrl}/auth/v1/admin/users/$userId';

    final response = await http.put(
      Uri.parse(url),
      headers: {
        'apikey': serviceKey,
        'Authorization': 'Bearer $serviceKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'password': newPassword,
      }),
    );

    if (response.statusCode != 200) {
      final body = jsonDecode(response.body);
      throw Exception(body['msg'] ?? body['message'] ?? 'Error al resetear contrasena');
    }
  }

  // ---- Crear salon completo (usuario + tenant) ----
  /// Crea usuario via Admin API (SRK) + tenant via RPC create_tenant.
  /// Mismo patron que reserva_template (funciona con build_prod.sh).
  /// Si falla el tenant, limpia el usuario auth huerfano.
  Future<Map<String, dynamic>> createSalonComplete({
    required String email,
    required String password,
    required String tenantId,
    required String salonName,
  }) async {
    // Paso 1: Crear usuario via Admin API (requiere SRK)
    final userId = await createAuthUser(email, password);

    // Paso 2: Crear tenant via funcion SECURITY DEFINER
    final trialDays = 15;
    final trialEndDate = DateTime.now().add(Duration(days: trialDays)).toIso8601String();
    try {
      await _client.rpc('create_tenant', params: {
        'p_id': tenantId,
        'p_nombre_salon': salonName,
        'p_admin_user_id': userId,
        'p_subscription_start_date': DateTime.now().toIso8601String().substring(0, 10),
        'p_trial_days': trialDays,
      });
      // Setear trial_end_date
      await _client.from('tenants').update({
        'trial_end_date': trialEndDate,
      }).eq('id', tenantId);
    } catch (e) {
      // Limpiar usuario auth huerfano
      try {
        await _client.rpc('delete_auth_user', params: {'p_user_id': userId});
      } catch (_) {}
      rethrow;
    }

    return {'user_id': userId, 'tenant_id': tenantId};
  }

  // ---- Storage ----
  Future<String> uploadImage(String path, Uint8List bytes, {String contentType = 'image/jpeg'}) async {
    final scopedPath = path.startsWith('$_tenantId/') ? path : '$_tenantId/$path';
    await _client.storage.from(AppConfig.storageBucket).uploadBinary(
      scopedPath,
      bytes,
      fileOptions: FileOptions(contentType: contentType, upsert: true),
    );
    // Para comprobantes usar URL firmada (bucket es privado)
    if (path.contains('comprobantes')) {
      final signedUrl = await _client.storage.from(AppConfig.storageBucket).createSignedUrl(scopedPath, 60 * 60 * 24 * 365);
      return signedUrl;
    }
    return _client.storage.from(AppConfig.storageBucket).getPublicUrl(scopedPath);
  }

  Future<void> deleteImage(String path) async {
    final scopedPath = path.startsWith('$_tenantId/') ? path : '$_tenantId/$path';
    await _client.storage.from(AppConfig.storageBucket).remove([scopedPath]);
  }

  Future<String> uploadVideo(String path, Uint8List bytes) async {
    final scopedPath = path.startsWith('$_tenantId/') ? path : '$_tenantId/$path';
    await _client.storage.from(AppConfig.storageBucket).uploadBinary(
      scopedPath,
      bytes,
      fileOptions: const FileOptions(contentType: 'video/mp4', upsert: true),
    );
    return _client.storage.from(AppConfig.storageBucket).getPublicUrl(scopedPath);
  }

  // ---- Clientes ----
  Future<List<Cliente>> loadClientes({String? busqueda}) async {
    var query = _client.from('clientes').select().eq('tenant_id', _tenantId);
    if (busqueda != null && busqueda.isNotEmpty) {
      query = query.ilike('nombre', '%$busqueda%');
    }
    final res = await query.order('nombre');
    return res.map<Cliente>((e) => Cliente.fromJson(e)).toList();
  }

  Future<Cliente> createCliente(Map<String, dynamic> data) async {
    data['tenant_id'] = _tenantId;
    // Normalizar telefono: solo digitos
    if (data['telefono'] != null) {
      data['telefono'] = (data['telefono'] as String).replaceAll(RegExp(r'[^\d+]'), '');
    }
    final res = await _client.from('clientes').insert(data).select().single();
    return Cliente.fromJson(res);
  }

  Future<void> updateCliente(String id, Map<String, dynamic> data) async {
    data['updated_at'] = DateTime.now().toIso8601String();
    await _client.from('clientes').update(data).eq('id', id);
  }

  Future<void> deleteCliente(String id) async {
    await _client.from('clientes').delete().eq('id', id);
  }

  /// Busca o crea un cliente por telefono (normalizado) dentro del tenant actual.
  Future<Cliente> getOrCreateCliente(String nombre, String telefono, {String? email}) async {
    final tel = telefono.replaceAll(RegExp(r'[^\d+]'), '');
    final existing = await _client
        .from('clientes')
        .select()
        .eq('tenant_id', _tenantId)
        .eq('telefono', tel)
        .maybeSingle();
    if (existing != null) return Cliente.fromJson(existing);
    return createCliente({
      'nombre': nombre,
      'telefono': tel,
      'email': email ?? '',
    });
  }

  // ---- Cliente Observaciones (Historia Clinica) ----
  Future<List<ClienteObservacion>> loadObservaciones(String clienteId) async {
    final res = await _client
        .from('cliente_observaciones')
        .select()
        .eq('tenant_id', _tenantId)
        .eq('cliente_id', clienteId)
        .order('fecha', ascending: false);
    return res.map<ClienteObservacion>((e) => ClienteObservacion.fromJson(e)).toList();
  }

  Future<ClienteObservacion> createObservacion(Map<String, dynamic> data) async {
    data['tenant_id'] = _tenantId;
    final res = await _client.from('cliente_observaciones').insert(data).select().single();
    return ClienteObservacion.fromJson(res);
  }

  Future<void> updateObservacion(String id, Map<String, dynamic> data) async {
    data['updated_at'] = DateTime.now().toIso8601String();
    await _client.from('cliente_observaciones').update(data).eq('id', id);
  }

  Future<void> deleteObservacion(String id) async {
    await _client.from('cliente_observaciones').delete().eq('id', id);
  }

  /// Turnos completados de un cliente (por telefono)
  Future<List<Appointment>> loadAppointmentsForClient(String telefono) async {
    final tel = telefono.replaceAll(RegExp(r'[^\d+]'), '');
    final res = await _client
        .from('appointments')
        .select()
        .eq('tenant_id', _tenantId)
        .eq('telefono', tel)
        .order('fecha', ascending: false);
    return res.map<Appointment>((e) => Appointment.fromJson(e)).toList();
  }

  // ---- Productos (Stock) ----
  Future<List<Producto>> loadProductos({String? categoria}) async {
    var query = _client.from('productos').select().eq('tenant_id', _tenantId);
    if (categoria != null && categoria.isNotEmpty && categoria != 'todos') {
      query = query.eq('categoria', categoria);
    }
    final res = await query.order('nombre');
    return res.map<Producto>((e) => Producto.fromJson(e)).toList();
  }

  Future<Producto> createProducto(Map<String, dynamic> data) async {
    data['tenant_id'] = _tenantId;
    final res = await _client.from('productos').insert(data).select().single();
    return Producto.fromJson(res);
  }

  Future<void> updateProducto(String id, Map<String, dynamic> data) async {
    data['updated_at'] = DateTime.now().toIso8601String();
    await _client.from('productos').update(data).eq('id', id);
  }

  Future<void> deleteProducto(String id) async {
    await _client.from('productos').delete().eq('id', id);
  }

  /// Busca producto por codigo de barras dentro del tenant
  Future<Producto?> findProductoByBarcode(String barcode) async {
    if (barcode.isEmpty) return null;
    final res = await _client
        .from('productos')
        .select()
        .eq('tenant_id', _tenantId)
        .eq('codigo_barras', barcode)
        .maybeSingle();
    return res != null ? Producto.fromJson(res) : null;
  }

  /// Ajusta stock y registra movimiento. Retorna el producto actualizado.
  Future<Producto> adjustStock(String productoId, int delta, {String tipo = 'ajuste', String motivo = ''}) async {
    // Registrar movimiento
    await _client.from('movimientos_stock').insert({
      'tenant_id': _tenantId,
      'producto_id': productoId,
      'cantidad': delta,
      'tipo': tipo,
      'motivo': motivo,
    });
    // Obtener cantidad actual y actualizar
    final row = await _client.from('productos').select('cantidad').eq('id', productoId).single();
    final nuevaCantidad = (row['cantidad'] as int) + delta;
    await _client.from('productos').update({
      'cantidad': nuevaCantidad < 0 ? 0 : nuevaCantidad,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', productoId);
    // Retornar actualizado
    final updated = await _client.from('productos').select().eq('id', productoId).single();
    return Producto.fromJson(updated);
  }

  /// Productos con stock bajo su minimo de alerta
  Future<List<Producto>> loadProductosBajoStock() async {
    final all = await _client
        .from('productos')
        .select()
        .eq('tenant_id', _tenantId)
        .eq('activo', true);
    return all
        .map<Producto>((e) => Producto.fromJson(e))
        .where((p) => p.stockBajo)
        .toList();
  }

  /// Historial de movimientos de un producto
  Future<List<MovimientoStock>> loadMovimientosStock(String productoId) async {
    final res = await _client
        .from('movimientos_stock')
        .select()
        .eq('tenant_id', _tenantId)
        .eq('producto_id', productoId)
        .order('created_at', ascending: false);
    return res.map<MovimientoStock>((e) => MovimientoStock.fromJson(e)).toList();
  }
}
