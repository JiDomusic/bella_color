import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/app_config.dart';
import '../models/tenant.dart';
import '../models/professional.dart';
import '../models/service.dart';
import '../models/appointment.dart';
import '../models/operating_hours.dart';
import '../models/block.dart';
import '../models/waitlist_entry.dart';

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

  Future<void> deleteTenant(String id) async {
    try {
      await _client.rpc('delete_tenant', params: {'p_id': id});
    } catch (_) {
      await _client.from('tenants').delete().eq('id', id);
    }
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

  // ---- Crear salon completo (usuario + tenant) ----
  Future<Map<String, dynamic>> createSalonComplete({
    required String email,
    required String password,
    required String tenantId,
    required String salonName,
  }) async {
    // Intentar via RPC atomica (crea usuario + tenant en una transaccion)
    try {
      final res = await _client.rpc('create_auth_user_and_tenant', params: {
        'p_email': email,
        'p_password': password,
        'p_tenant_id': tenantId,
        'p_nombre_salon': salonName,
      });
      return Map<String, dynamic>.from(res as Map);
    } catch (rpcError) {
      // Fallback: signUp + esperar + create_tenant
      try {
        final authRes = await _client.auth.signUp(email: email, password: password);
        final userId = authRes.user?.id;
        if (userId == null) throw Exception('No se pudo crear el usuario');

        // signUp cambia la sesion -> volver a anon para que el RPC funcione
        await _client.auth.signOut();

        // Esperar a que auth.users se sincronice completamente
        await Future.delayed(const Duration(seconds: 3));

        // Crear tenant (create_tenant es SECURITY DEFINER, funciona como anon)
        await _client.rpc('create_tenant', params: {
          'p_id': tenantId,
          'p_nombre_salon': salonName,
          'p_admin_user_id': userId,
          'p_subscription_start_date': DateTime.now().toIso8601String().substring(0, 10),
          'p_trial_days': 15,
        });

        return {'user_id': userId, 'tenant_id': tenantId};
      } catch (fallbackError) {
        throw Exception(
          'Error creando salon. '
          'RPC: $rpcError | '
          'Fallback: $fallbackError'
        );
      }
    }
  }

  // ---- Storage ----
  Future<String> uploadImage(String path, Uint8List bytes, {String contentType = 'image/jpeg'}) async {
    final scopedPath = path.startsWith('$_tenantId/') ? path : '$_tenantId/$path';
    await _client.storage.from(AppConfig.storageBucket).uploadBinary(
      scopedPath,
      bytes,
      fileOptions: FileOptions(contentType: contentType, upsert: true),
    );
    return _client.storage.from(AppConfig.storageBucket).getPublicUrl(scopedPath);
  }

  Future<void> deleteImage(String path) async {
    final scopedPath = path.startsWith('$_tenantId/') ? path : '$_tenantId/$path';
    await _client.storage.from(AppConfig.storageBucket).remove([scopedPath]);
  }
}
