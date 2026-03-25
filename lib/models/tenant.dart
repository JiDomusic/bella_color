class Tenant {
  final String id;
  final String nombreSalon;
  final String subtitulo;
  final String slogan;
  final String direccion;
  final String ciudad;
  final String provincia;
  final String pais;
  final String googleMapsQuery;
  final String emailContacto;
  final String telefonoContacto;
  final String whatsappNumero;
  final String codigoPaisTelefono;
  final String sitioWeb;
  final String? logoUrl;
  final String? logoBlancoUrl;
  final String? fondoUrl;
  final String colorPrimario;
  final String colorSecundario;
  final String colorTerciario;
  final String colorAcento;
  final int minAnticipacionHoras;
  final int maxAnticipacionDias;
  final int minutosAutoLiberacion;
  final int ventanaConfirmacionHoras;
  final int recordatorioHorasAntes;
  final int diaCerrado;
  final List<String> adminEmails;
  final List<String> superAdminEmails;
  final bool onboardingCompleted;
  final String? adminUserId;
  final String? subscriptionStartDate;
  final int subscriptionDueDay;
  final bool isBlocked;
  final DateTime? blockedAt;
  final String blockReason;
  final int trialDays;
  final DateTime? trialEndDate;
  final bool trialExtended;
  final String bannerTexto;
  final bool senaHabilitada;
  final int senaPorcentaje;
  final String senaCbu;
  final String senaAlias;
  final String senaTitular;
  final String fondoPaginaUrl;
  final String colorFondoPagina;
  final bool mostrarNombreSalon;
  final bool mostrarBanner;

  Tenant({
    required this.id,
    this.nombreSalon = '',
    this.subtitulo = '',
    this.slogan = '',
    this.direccion = '',
    this.ciudad = '',
    this.provincia = '',
    this.pais = 'Argentina',
    this.googleMapsQuery = '',
    this.emailContacto = '',
    this.telefonoContacto = '',
    this.whatsappNumero = '',
    this.codigoPaisTelefono = '54',
    this.sitioWeb = '',
    this.logoUrl,
    this.logoBlancoUrl,
    this.fondoUrl,
    this.colorPrimario = '#D4A0A0',
    this.colorSecundario = '#C48B8B',
    this.colorTerciario = '#E8C4C4',
    this.colorAcento = '#D4AF37',
    this.minAnticipacionHoras = 2,
    this.maxAnticipacionDias = 60,
    this.minutosAutoLiberacion = 15,
    this.ventanaConfirmacionHoras = 2,
    this.recordatorioHorasAntes = 24,
    this.diaCerrado = 0,
    this.adminEmails = const [],
    this.superAdminEmails = const [],
    this.onboardingCompleted = false,
    this.adminUserId,
    this.subscriptionStartDate,
    this.subscriptionDueDay = 18,
    this.isBlocked = false,
    this.blockedAt,
    this.blockReason = '',
    this.trialDays = 15,
    this.trialEndDate,
    this.trialExtended = false,
    this.bannerTexto = '',
    this.senaHabilitada = false,
    this.senaPorcentaje = 0,
    this.senaCbu = '',
    this.senaAlias = '',
    this.senaTitular = '',
    this.fondoPaginaUrl = '',
    this.colorFondoPagina = '',
    this.mostrarNombreSalon = true,
    this.mostrarBanner = false,
  });

  factory Tenant.fromJson(Map<String, dynamic> json) {
    List<String> parseEmails(dynamic v) {
      if (v is List) return v.cast<String>();
      if (v is String) {
        try {
          final parsed = List<String>.from(
            (v.startsWith('[') ? v : '[$v]')
                .replaceAll("'", '"')
                .split(RegExp(r'[\[\],\s"]+'))
                .where((s) => s.isNotEmpty),
          );
          return parsed;
        } catch (_) {
          return [];
        }
      }
      return [];
    }

    return Tenant(
      id: json['id'] as String,
      nombreSalon: json['nombre_salon'] ?? '',
      subtitulo: json['subtitulo'] ?? '',
      slogan: json['slogan'] ?? '',
      direccion: json['direccion'] ?? '',
      ciudad: json['ciudad'] ?? '',
      provincia: json['provincia'] ?? '',
      pais: json['pais'] ?? 'Argentina',
      googleMapsQuery: json['google_maps_query'] ?? '',
      emailContacto: json['email_contacto'] ?? '',
      telefonoContacto: json['telefono_contacto'] ?? '',
      whatsappNumero: json['whatsapp_numero'] ?? '',
      codigoPaisTelefono: json['codigo_pais_telefono'] ?? '54',
      sitioWeb: json['sitio_web'] ?? '',
      logoUrl: json['logo_url'],
      logoBlancoUrl: json['logo_blanco_url'],
      fondoUrl: json['fondo_url'],
      colorPrimario: json['color_primario'] ?? '#D4A0A0',
      colorSecundario: json['color_secundario'] ?? '#C48B8B',
      colorTerciario: json['color_terciario'] ?? '#E8C4C4',
      colorAcento: json['color_acento'] ?? '#D4AF37',
      minAnticipacionHoras: json['min_anticipacion_horas'] ?? 2,
      maxAnticipacionDias: json['max_anticipacion_dias'] ?? 60,
      minutosAutoLiberacion: json['minutos_auto_liberacion'] ?? 15,
      ventanaConfirmacionHoras: json['ventana_confirmacion_horas'] ?? 2,
      recordatorioHorasAntes: json['recordatorio_horas_antes'] ?? 24,
      diaCerrado: json['dia_cerrado'] ?? 0,
      adminEmails: parseEmails(json['admin_emails']),
      superAdminEmails: parseEmails(json['super_admin_emails']),
      onboardingCompleted: json['onboarding_completed'] ?? false,
      adminUserId: json['admin_user_id'],
      subscriptionStartDate: json['subscription_start_date'],
      subscriptionDueDay: json['subscription_due_day'] ?? 18,
      isBlocked: json['is_blocked'] ?? false,
      blockedAt: json['blocked_at'] != null ? DateTime.tryParse(json['blocked_at']) : null,
      blockReason: json['block_reason'] ?? '',
      trialDays: json['trial_days'] ?? 15,
      trialEndDate: json['trial_end_date'] != null ? DateTime.tryParse(json['trial_end_date']) : null,
      trialExtended: json['trial_extended'] ?? false,
      bannerTexto: json['banner_texto'] ?? '',
      senaHabilitada: json['sena_habilitada'] ?? false,
      senaPorcentaje: json['sena_porcentaje'] ?? 0,
      senaCbu: json['sena_cbu'] ?? '',
      senaAlias: json['sena_alias'] ?? '',
      senaTitular: json['sena_titular'] ?? '',
      fondoPaginaUrl: json['fondo_pagina_url'] ?? '',
      colorFondoPagina: json['color_fondo_pagina'] ?? '',
      mostrarNombreSalon: json['mostrar_nombre_salon'] ?? true,
      mostrarBanner: json['mostrar_banner'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'nombre_salon': nombreSalon,
    'subtitulo': subtitulo,
    'slogan': slogan,
    'direccion': direccion,
    'ciudad': ciudad,
    'provincia': provincia,
    'pais': pais,
    'google_maps_query': googleMapsQuery,
    'email_contacto': emailContacto,
    'telefono_contacto': telefonoContacto,
    'whatsapp_numero': whatsappNumero,
    'codigo_pais_telefono': codigoPaisTelefono,
    'sitio_web': sitioWeb,
    'logo_url': logoUrl,
    'logo_blanco_url': logoBlancoUrl,
    'fondo_url': fondoUrl,
    'color_primario': colorPrimario,
    'color_secundario': colorSecundario,
    'color_terciario': colorTerciario,
    'color_acento': colorAcento,
    'min_anticipacion_horas': minAnticipacionHoras,
    'max_anticipacion_dias': maxAnticipacionDias,
    'minutos_auto_liberacion': minutosAutoLiberacion,
    'ventana_confirmacion_horas': ventanaConfirmacionHoras,
    'recordatorio_horas_antes': recordatorioHorasAntes,
    'dia_cerrado': diaCerrado,
    'admin_emails': adminEmails.toString(),
    'super_admin_emails': superAdminEmails.toString(),
    'onboarding_completed': onboardingCompleted,
    'admin_user_id': adminUserId,
    'subscription_start_date': subscriptionStartDate,
    'subscription_due_day': subscriptionDueDay,
    'is_blocked': isBlocked,
    'block_reason': blockReason,
    'trial_days': trialDays,
    'trial_end_date': trialEndDate?.toIso8601String(),
    'trial_extended': trialExtended,
    'banner_texto': bannerTexto,
    'sena_habilitada': senaHabilitada,
    'sena_porcentaje': senaPorcentaje,
    'sena_cbu': senaCbu,
    'sena_alias': senaAlias,
    'sena_titular': senaTitular,
    'fondo_pagina_url': fondoPaginaUrl,
    'color_fondo_pagina': colorFondoPagina,
    'mostrar_nombre_salon': mostrarNombreSalon,
    'mostrar_banner': mostrarBanner,
  };

  Tenant copyWith({
    String? nombreSalon,
    String? subtitulo,
    String? slogan,
    String? direccion,
    String? ciudad,
    String? provincia,
    String? googleMapsQuery,
    String? emailContacto,
    String? telefonoContacto,
    String? whatsappNumero,
    String? sitioWeb,
    String? logoUrl,
    String? logoBlancoUrl,
    String? fondoUrl,
    String? colorPrimario,
    String? colorSecundario,
    String? colorTerciario,
    String? colorAcento,
    int? minAnticipacionHoras,
    int? maxAnticipacionDias,
    int? minutosAutoLiberacion,
    int? ventanaConfirmacionHoras,
    int? recordatorioHorasAntes,
    int? diaCerrado,
    List<String>? adminEmails,
    bool? onboardingCompleted,
  }) {
    return Tenant(
      id: id,
      nombreSalon: nombreSalon ?? this.nombreSalon,
      subtitulo: subtitulo ?? this.subtitulo,
      slogan: slogan ?? this.slogan,
      direccion: direccion ?? this.direccion,
      ciudad: ciudad ?? this.ciudad,
      provincia: provincia ?? this.provincia,
      pais: pais,
      googleMapsQuery: googleMapsQuery ?? this.googleMapsQuery,
      emailContacto: emailContacto ?? this.emailContacto,
      telefonoContacto: telefonoContacto ?? this.telefonoContacto,
      whatsappNumero: whatsappNumero ?? this.whatsappNumero,
      codigoPaisTelefono: codigoPaisTelefono,
      sitioWeb: sitioWeb ?? this.sitioWeb,
      logoUrl: logoUrl ?? this.logoUrl,
      logoBlancoUrl: logoBlancoUrl ?? this.logoBlancoUrl,
      fondoUrl: fondoUrl ?? this.fondoUrl,
      colorPrimario: colorPrimario ?? this.colorPrimario,
      colorSecundario: colorSecundario ?? this.colorSecundario,
      colorTerciario: colorTerciario ?? this.colorTerciario,
      colorAcento: colorAcento ?? this.colorAcento,
      minAnticipacionHoras: minAnticipacionHoras ?? this.minAnticipacionHoras,
      maxAnticipacionDias: maxAnticipacionDias ?? this.maxAnticipacionDias,
      minutosAutoLiberacion: minutosAutoLiberacion ?? this.minutosAutoLiberacion,
      ventanaConfirmacionHoras: ventanaConfirmacionHoras ?? this.ventanaConfirmacionHoras,
      recordatorioHorasAntes: recordatorioHorasAntes ?? this.recordatorioHorasAntes,
      diaCerrado: diaCerrado ?? this.diaCerrado,
      adminEmails: adminEmails ?? this.adminEmails,
      superAdminEmails: superAdminEmails,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      adminUserId: adminUserId,
      subscriptionStartDate: subscriptionStartDate,
      subscriptionDueDay: subscriptionDueDay,
    );
  }
}
