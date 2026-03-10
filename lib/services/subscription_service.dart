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
    final trialEnd = startDate.add(Duration(days: tenant.trialDays));

    // Periodo de prueba
    if (now.isBefore(trialEnd)) {
      final remaining = trialEnd.difference(now).inDays;
      return SubscriptionStatus(
        isActive: true,
        isBlocked: false,
        isTrial: true,
        daysRemaining: remaining,
        message: remaining <= 3
            ? 'Tu prueba gratis vence en $remaining dia${remaining == 1 ? '' : 's'}!'
            : 'Prueba gratis: $remaining dias restantes',
      );
    }

    // Despues del trial: calcular vencimiento mensual
    final dueDay = tenant.subscriptionDueDay;
    var nextDue = DateTime(now.year, now.month, dueDay);
    if (nextDue.isBefore(now)) {
      // Ya paso el dia de vencimiento este mes
      final daysPastDue = now.difference(nextDue).inDays;
      if (daysPastDue > 5) {
        // Mas de 5 dias de gracia -> AUTO-BLOQUEAR
        return SubscriptionStatus(
          isActive: false,
          isBlocked: false,
          isTrial: false,
          shouldAutoBlock: true,
          daysRemaining: -daysPastDue,
          message: 'Pago vencido hace $daysPastDue dias. Sistema suspendido automaticamente.',
        );
      } else {
        // Periodo de gracia
        final graceDays = 5 - daysPastDue;
        return SubscriptionStatus(
          isActive: true,
          isBlocked: false,
          isTrial: false,
          daysRemaining: graceDays,
          message: 'Tu pago vencio el $dueDay de este mes. Tenes $graceDays dia${graceDays == 1 ? '' : 's'} de gracia.',
        );
      }
    } else {
      // Aun no llego el dia de vencimiento
      final daysUntilDue = nextDue.difference(now).inDays;
      return SubscriptionStatus(
        isActive: true,
        isBlocked: false,
        isTrial: false,
        daysRemaining: daysUntilDue,
        message: daysUntilDue <= 5
            ? 'Tu pago vence en $daysUntilDue dia${daysUntilDue == 1 ? '' : 's'} (dia $dueDay)'
            : '',
      );
    }
  }
}
