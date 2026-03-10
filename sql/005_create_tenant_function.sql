-- ============================================================================
-- 005_create_tenant_function.sql
-- Funcion SECURITY DEFINER para crear tenants desde la app
-- Bypasea RLS porque corre con privilegios del owner (postgres)
-- Ejecutar en Supabase SQL Editor
-- ============================================================================

CREATE OR REPLACE FUNCTION create_tenant(
  p_id TEXT,
  p_nombre_salon TEXT,
  p_admin_user_id UUID,
  p_subscription_start_date TEXT DEFAULT NULL,
  p_trial_days INT DEFAULT 15
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_result JSON;
BEGIN
  INSERT INTO tenants (
    id,
    nombre_salon,
    admin_user_id,
    admin_emails,
    onboarding_completed,
    subscription_start_date,
    trial_days
  ) VALUES (
    p_id,
    p_nombre_salon,
    p_admin_user_id,
    '[]',
    false,
    COALESCE(p_subscription_start_date, to_char(NOW(), 'YYYY-MM-DD')),
    p_trial_days
  )
  RETURNING row_to_json(tenants.*) INTO v_result;

  RETURN v_result;
END;
$$;

-- Permitir que anon y authenticated llamen a esta funcion
GRANT EXECUTE ON FUNCTION create_tenant TO anon;
GRANT EXECUTE ON FUNCTION create_tenant TO authenticated;

-- ============================================================================
-- Funcion para bloquear/desbloquear tenants (super admin)
-- ============================================================================

CREATE OR REPLACE FUNCTION block_tenant(
  p_id TEXT,
  p_reason TEXT DEFAULT 'Bloqueado por falta de pago'
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  UPDATE tenants
  SET is_blocked = true,
      blocked_at = NOW()::TEXT,
      block_reason = p_reason
  WHERE id = p_id;
END;
$$;

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
      block_reason = ''
  WHERE id = p_id;
END;
$$;

-- Funcion para listar todos los tenants (super admin)
CREATE OR REPLACE FUNCTION list_all_tenants()
RETURNS SETOF tenants
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN QUERY SELECT * FROM tenants ORDER BY nombre_salon;
END;
$$;

GRANT EXECUTE ON FUNCTION block_tenant TO anon;
GRANT EXECUTE ON FUNCTION block_tenant TO authenticated;
GRANT EXECUTE ON FUNCTION unblock_tenant TO anon;
GRANT EXECUTE ON FUNCTION unblock_tenant TO authenticated;
GRANT EXECUTE ON FUNCTION list_all_tenants TO anon;
GRANT EXECUTE ON FUNCTION list_all_tenants TO authenticated;

-- ============================================================================
-- Funcion para cargar tenant con validacion de bloqueo server-side
-- Si esta bloqueado o vencido, devuelve is_blocked = true desde el servidor
-- Esto evita que alguien bypass la logica client-side
-- ============================================================================

CREATE OR REPLACE FUNCTION get_tenant_validated(p_id TEXT)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_tenant tenants%ROWTYPE;
  v_start DATE;
  v_trial_end DATE;
  v_due_day INT;
  v_next_due DATE;
  v_days_past INT;
BEGIN
  SELECT * INTO v_tenant FROM tenants WHERE id = p_id;

  IF NOT FOUND THEN
    RETURN NULL;
  END IF;

  -- Si ya esta bloqueado, devolver tal cual
  IF v_tenant.is_blocked THEN
    RETURN row_to_json(v_tenant);
  END IF;

  -- Verificar vencimiento server-side
  IF v_tenant.subscription_start_date IS NOT NULL AND v_tenant.subscription_start_date != '' THEN
    v_start := v_tenant.subscription_start_date::DATE;
    v_trial_end := v_start + (COALESCE(v_tenant.trial_days, 15) || ' days')::INTERVAL;

    -- Si paso el trial
    IF NOW()::DATE > v_trial_end THEN
      v_due_day := COALESCE(v_tenant.subscription_due_day, 18);
      v_next_due := make_date(
        EXTRACT(YEAR FROM NOW())::INT,
        EXTRACT(MONTH FROM NOW())::INT,
        LEAST(v_due_day, 28)
      );

      IF NOW()::DATE > v_next_due THEN
        v_days_past := (NOW()::DATE - v_next_due);
        -- Mas de 5 dias de gracia: auto-bloquear
        IF v_days_past > 5 THEN
          UPDATE tenants
          SET is_blocked = true,
              blocked_at = NOW()::TEXT,
              block_reason = 'Bloqueado automaticamente por falta de pago'
          WHERE id = p_id;

          v_tenant.is_blocked := true;
          v_tenant.block_reason := 'Bloqueado automaticamente por falta de pago';
        END IF;
      END IF;
    END IF;
  END IF;

  RETURN row_to_json(v_tenant);
END;
$$;

GRANT EXECUTE ON FUNCTION get_tenant_validated TO anon;
GRANT EXECUTE ON FUNCTION get_tenant_validated TO authenticated;
