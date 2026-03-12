-- ============================================================================
-- 008_crear_salon_automatico.sql
-- Funcion para crear usuario + salon en una sola transaccion
--
-- EJECUTAR EN: Supabase SQL Editor del proyecto BELLA COLOR
-- DESPUES DE: 007_TODO_COMPLETO_salon.sql
--
-- Esta funcion crea el usuario en auth.users Y el tenant en una sola
-- transaccion atomica, evitando problemas de foreign key.
-- ============================================================================

CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- ============================================================================
-- Funcion: create_auth_user_and_tenant
-- Crea usuario en auth.users + identidad + tenant, todo en una transaccion
-- ============================================================================
CREATE OR REPLACE FUNCTION create_auth_user_and_tenant(
  p_email TEXT,
  p_password TEXT,
  p_tenant_id TEXT,
  p_nombre_salon TEXT,
  p_trial_days INT DEFAULT 15
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID;
  v_encrypted_pw TEXT;
  v_now TIMESTAMPTZ := NOW();
BEGIN
  -- Validaciones
  IF p_email IS NULL OR p_email = '' THEN
    RAISE EXCEPTION 'Email es requerido';
  END IF;
  IF p_password IS NULL OR length(p_password) < 6 THEN
    RAISE EXCEPTION 'Password debe tener al menos 6 caracteres';
  END IF;
  IF p_tenant_id IS NULL OR p_tenant_id = '' THEN
    RAISE EXCEPTION 'Tenant ID es requerido';
  END IF;

  -- Verificar que no exista el email
  IF EXISTS (SELECT 1 FROM auth.users WHERE email = p_email) THEN
    RAISE EXCEPTION 'El email ya esta registrado';
  END IF;

  -- Verificar que no exista el tenant
  IF EXISTS (SELECT 1 FROM tenants WHERE id = p_tenant_id) THEN
    RAISE EXCEPTION 'El ID de salon ya existe';
  END IF;

  -- Generar UUID y encriptar password
  v_user_id := gen_random_uuid();
  v_encrypted_pw := crypt(p_password, gen_salt('bf'));

  -- 1. Crear usuario en auth.users
  INSERT INTO auth.users (
    id, instance_id, email, encrypted_password,
    email_confirmed_at, created_at, updated_at,
    raw_app_meta_data, raw_user_meta_data,
    aud, role, confirmation_token
  ) VALUES (
    v_user_id,
    '00000000-0000-0000-0000-000000000000',
    p_email,
    v_encrypted_pw,
    v_now, v_now, v_now,
    '{"provider":"email","providers":["email"]}',
    '{}',
    'authenticated',
    'authenticated',
    encode(gen_random_bytes(32), 'hex')
  );

  -- 2. Crear identidad (requerido para login)
  INSERT INTO auth.identities (
    id, user_id, identity_data, provider, provider_id,
    created_at, updated_at, last_sign_in_at
  ) VALUES (
    v_user_id::text,
    v_user_id,
    jsonb_build_object(
      'sub', v_user_id::text,
      'email', p_email,
      'email_verified', true,
      'phone_verified', false
    ),
    'email',
    v_user_id::text,
    v_now, v_now, v_now
  );

  -- 3. Crear tenant vinculado al usuario
  INSERT INTO tenants (
    id, nombre_salon, admin_user_id, admin_emails,
    onboarding_completed, subscription_start_date, trial_days
  ) VALUES (
    p_tenant_id,
    p_nombre_salon,
    v_user_id,
    '[]',
    false,
    to_char(v_now, 'YYYY-MM-DD'),
    p_trial_days
  );

  -- Retornar resultado
  RETURN json_build_object(
    'user_id', v_user_id,
    'tenant_id', p_tenant_id,
    'email', p_email
  );
END;
$$;

-- Permisos
GRANT EXECUTE ON FUNCTION create_auth_user_and_tenant TO anon;
GRANT EXECUTE ON FUNCTION create_auth_user_and_tenant TO authenticated;

-- Notificar a PostgREST para que recargue el esquema y detecte la funcion
NOTIFY pgrst, 'reload schema';
SELECT pg_notify('pgrst', 'reload schema');
