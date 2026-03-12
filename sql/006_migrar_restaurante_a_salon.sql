-- ============================================================================
-- 006_migrar_restaurante_a_salon.sql
-- MIGRA la tabla tenants de RESTAURANTE a SALON DE BELLEZA
-- Renombra columnas, borra las de restaurante, agrega las de salon
-- Ejecutar en Supabase SQL Editor del proyecto BELLA COLOR
-- NO AFECTA al proyecto reserva_template
-- ============================================================================

-- 1. Renombrar columna de restaurante a salon
ALTER TABLE tenants RENAME COLUMN nombre_restaurante TO nombre_salon;

-- 2. Renombrar logo_color_url a logo_url (la app usa logo_url)
ALTER TABLE tenants RENAME COLUMN logo_color_url TO logo_url;

-- 3. Renombrar columnas de anticipacion
ALTER TABLE tenants RENAME COLUMN anticipo_almuerzo_horas TO min_anticipacion_horas;
ALTER TABLE tenants RENAME COLUMN dias_adelanto_maximo TO max_anticipacion_dias;
ALTER TABLE tenants RENAME COLUMN minutos_liberacion_auto TO minutos_auto_liberacion;

-- 4. Borrar columnas de restaurante que no aplican a salon
ALTER TABLE tenants DROP COLUMN IF EXISTS min_personas;
ALTER TABLE tenants DROP COLUMN IF EXISTS max_personas;
ALTER TABLE tenants DROP COLUMN IF EXISTS usa_sistema_mesas;
ALTER TABLE tenants DROP COLUMN IF EXISTS usa_areas_multiples;
ALTER TABLE tenants DROP COLUMN IF EXISTS capacidad_compartida;
ALTER TABLE tenants DROP COLUMN IF EXISTS optimizacion_estricta_mesas;
ALTER TABLE tenants DROP COLUMN IF EXISTS anticipo_regular_horas;

-- 5. Agregar columnas que faltan para salon
ALTER TABLE tenants ADD COLUMN IF NOT EXISTS is_blocked BOOLEAN DEFAULT false;
ALTER TABLE tenants ADD COLUMN IF NOT EXISTS blocked_at TEXT;
ALTER TABLE tenants ADD COLUMN IF NOT EXISTS block_reason TEXT DEFAULT '';
ALTER TABLE tenants ADD COLUMN IF NOT EXISTS trial_days INT DEFAULT 15;

-- 6. Recrear la funcion create_tenant con nombre_salon
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
    id, nombre_salon, admin_user_id, admin_emails,
    onboarding_completed, subscription_start_date, trial_days
  ) VALUES (
    p_id, p_nombre_salon, p_admin_user_id, '[]',
    false,
    COALESCE(p_subscription_start_date, to_char(NOW(), 'YYYY-MM-DD')),
    p_trial_days
  )
  RETURNING row_to_json(tenants.*) INTO v_result;

  UPDATE auth.users
  SET email_confirmed_at = NOW()
  WHERE id = p_admin_user_id AND email_confirmed_at IS NULL;

  RETURN v_result;
END;
$$;

GRANT EXECUTE ON FUNCTION create_tenant TO anon;
GRANT EXECUTE ON FUNCTION create_tenant TO authenticated;
