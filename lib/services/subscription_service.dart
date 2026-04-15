import '../models/tenant.dart';

class SubscriptionStatus {
  final bool isActive;
  final bool isBlocked;
  final bool isTrial;
  final bool shouldAutoBlock;
  final int daysRemaining;
  final String message;

  SubscriptionStatus({
    required this.isActive,
    required this.isBlocked,
    required this.isTrial,
    this.shouldAutoBlock = false,
    required this.daysRemaining,
    required this.message,
  });
}

class SubscriptionService {
  static SubscriptionStatus check(Tenant tenant) {
    // Si esta bloqueado manualmente por super admin
    if (tenant.isBlocked) {
      return SubscriptionStatus(
        isActive: false,
        isBlocked: true,
        isTrial: false,
        daysRemaining: 0,
        message: tenant.blockReason.isNotEmpty
            ? tenant.blockReason
            : 'Sistema bloqueado por falta de pago. Contacta a soporte.',
      );
    }

    // Si no tiene fecha de inicio, esta activo (recien creado, aun sin fecha)
    if (tenant.subscriptionStartDate == null || tenant.subscriptionStartDate!.isEmpty) {
      return SubscriptionStatus(
        isActive: true,
        isBlocked: false,
        isTrial: true,
        daysRemaining: tenant.trialDays,
        message: 'Periodo de prueba: ${tenant.trialDays} dias',
      );
    }

    final startDate = DateTime.tryParse(tenant.subscriptionStartDate!);
    if (startDate == null) {
      return SubscriptionStatus(
        isActive: true,
        isBlocked: false,
        isTrial: false,
        daysRemaining: 999,
        message: '',
      );
    }

    final now = DateTime.now();
    // El trial incluye el día completo del vencimiento (se bloquea recién al día siguiente)
    final trialEnd = startDate.add(Duration(days: tenant.trialDays + 1));

    // Periodo de prueba
    if (now.isBefore(trialEnd)) {
      final remaining = trialEnd.difference(now).inDays;
      return SubscriptionStatus(
        isActive: true,
        isBlocked: false,
        isTrial: true,
        daysRemaining: remaining,
        message: remaining <= 0
            ? 'Tu prueba gratis vence HOY! Transferi para no perder el acceso.'
            : remaining <= 3
                ? 'Tu prueba gratis vence en $remaining dia${remaining == 1 ? '' : 's'}!'
                : 'Prueba gratis: $remaining dias restantes',
      );
    }

    // Despues del trial: calcular vencimiento mensual
    final dueDay = tenant.subscriptionDueDay;
    // Comparar solo por fecha (sin hora) para que el día completo de vencimiento sea válido
    final today = DateTime(now.year, now.month, now.day);
    final dueDateThisMonth = DateTime(now.year, now.month, dueDay);

    if (today.isAfter(dueDateThisMonth)) {
      // Ya paso el dia de vencimiento -> AUTO-BLOQUEAR al día siguiente
      final daysPastDue = today.difference(dueDateThisMonth).inDays;
      return SubscriptionStatus(
        isActive: false,
        isBlocked: false,
        isTrial: false,
        shouldAutoBlock: true,
        daysRemaining: -daysPastDue,
        message: 'Pago vencido hace $daysPastDue dia${daysPastDue == 1 ? '' : 's'}. Sistema suspendido automaticamente.',
      );
    } else {
      // Hoy es el dia de vencimiento o aún no llegó
      final daysUntilDue = dueDateThisMonth.difference(today).inDays;
      return SubscriptionStatus(
        isActive: true,
        isBlocked: false,
        isTrial: false,
        daysRemaining: daysUntilDue,
        message: daysUntilDue <= 5
            ? daysUntilDue == 0
                ? 'Tu pago vence HOY (dia $dueDay)'
                : 'Tu pago vence en $daysUntilDue dia${daysUntilDue == 1 ? '' : 's'} (dia $dueDay)'
            : '',
      );
    }
  }
}
