-- ============================================================================
-- 025_last_payment_date.sql
-- Registra el último pago cuando super admin desbloquea un salon.
-- Esto evita que el auto-bloqueo del splash vuelva a bloquear el tenant
-- después de que el super admin lo desbloqueó manualmente.
-- Run in Supabase SQL Editor
-- ============================================================================

ALTER TABLE tenants ADD COLUMN IF NOT EXISTS last_payment_date DATE;

-- unblock_tenant ahora también registra el pago (hoy) para que el ciclo mensual
-- no dispare shouldAutoBlock en el próximo login del admin del salon.
CREATE OR REPLACE FUNCTION unblock_tenant(p_id TEXT)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  UPDATE tenants
  SET is_blocked = false,
      blocked_at = NULL,
      block_reason = '',
      last_payment_date = CURRENT_DATE
  WHERE id = p_id;
END;
$$;

GRANT EXECUTE ON FUNCTION unblock_tenant TO anon;
GRANT EXECUTE ON FUNCTION unblock_tenant TO authenticated;
