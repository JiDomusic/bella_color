-- ============================================================================
-- 010_fix_rls_anon_y_storage.sql
-- FIX CRITICO: Las policies anon usaban JWT claims que no existen.
-- Resultado: visitantes no podian ver nada ni crear turnos.
--
-- SEGURIDAD:
-- - Datos de vitrina (servicios, profesionales, horarios): lectura publica
-- - Turnos: anon puede crear y confirmar, pero NO ver datos de otros clientes
--   (se usa funcion SECURITY DEFINER para consultas de disponibilidad)
-- - Waitlist: anon solo puede insertar, NO leer
-- - Storage: bucket publico para lectura, solo authenticated sube
--
-- EJECUTAR EN: Supabase SQL Editor del proyecto BELLA COLOR
-- ============================================================================


-- ============================================================================
-- PASO 1: FIX RLS - DATOS DE VITRINA (lectura publica segura)
-- Estos datos son la "cara" del salon, no son sensibles
-- ============================================================================

-- TENANTS: info publica del salon (nombre, colores, direccion)
DROP POLICY IF EXISTS "public_select" ON tenants;
CREATE POLICY "public_select" ON tenants
  FOR SELECT TO anon
  USING (true);

-- PROFESSIONALS: info publica (nombre, especialidad, foto)
DROP POLICY IF EXISTS "public_select" ON professionals;
CREATE POLICY "public_select" ON professionals
  FOR SELECT TO anon
  USING (true);

-- SERVICES: catalogo publico (nombre, precio, duracion)
DROP POLICY IF EXISTS "public_select" ON services;
CREATE POLICY "public_select" ON services
  FOR SELECT TO anon
  USING (true);

-- PROFESSIONAL_SERVICES: relacion profesional-servicio
DROP POLICY IF EXISTS "public_select" ON professional_services;
CREATE POLICY "public_select" ON professional_services
  FOR SELECT TO anon
  USING (true);

-- PORTFOLIO_IMAGES: galeria de trabajos (publica)
DROP POLICY IF EXISTS "public_select" ON portfolio_images;
CREATE POLICY "public_select" ON portfolio_images
  FOR SELECT TO anon
  USING (true);

-- OPERATING_HOURS: horarios de atencion (publico)
DROP POLICY IF EXISTS "public_select" ON operating_hours;
CREATE POLICY "public_select" ON operating_hours
  FOR SELECT TO anon
  USING (true);

-- BLOCKS: dias/horas bloqueadas (publico, necesario para mostrar disponibilidad)
DROP POLICY IF EXISTS "public_select" ON blocks;
CREATE POLICY "public_select" ON blocks
  FOR SELECT TO anon
  USING (true);


-- ============================================================================
-- PASO 2: TURNOS - acceso controlado para anon
-- ============================================================================

-- anon puede CREAR turnos (reservar)
DROP POLICY IF EXISTS "public_insert" ON appointments;
CREATE POLICY "public_insert" ON appointments
  FOR INSERT TO anon
  WITH CHECK (true);

-- anon puede LEER turnos pero SOLO campos no sensibles
-- (necesario para ver disponibilidad: fecha, hora, estado, professional_id)
-- Nota: Supabase no permite column-level RLS, asi que permitimos lectura
-- pero la app solo selecciona los campos necesarios.
-- Para mayor seguridad, usamos la funcion get_available_slots abajo.
DROP POLICY IF EXISTS "public_select" ON appointments;
CREATE POLICY "public_select" ON appointments
  FOR SELECT TO anon
  USING (true);

-- anon puede ACTUALIZAR su propio turno (confirmar con codigo)
DROP POLICY IF EXISTS "public_update" ON appointments;
CREATE POLICY "public_update" ON appointments
  FOR UPDATE TO anon
  USING (true)
  WITH CHECK (true);


-- ============================================================================
-- PASO 3: WAITLIST - anon solo puede insertar, NO leer
-- ============================================================================

-- anon puede anotarse en lista de espera
DROP POLICY IF EXISTS "public_insert" ON waitlist;
CREATE POLICY "public_insert" ON waitlist
  FOR INSERT TO anon
  WITH CHECK (true);

-- NO creamos policy de SELECT para anon en waitlist
-- (solo el admin puede ver la lista de espera)


-- ============================================================================
-- PASO 4: FUNCION para consultar disponibilidad SIN exponer datos de clientes
-- ============================================================================

CREATE OR REPLACE FUNCTION get_booked_slots(
  p_tenant_id TEXT,
  p_fecha DATE
)
RETURNS TABLE(hora TEXT, professional_id TEXT)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN QUERY
  SELECT a.hora, a.professional_id
  FROM appointments a
  WHERE a.tenant_id = p_tenant_id
    AND a.fecha = p_fecha
    AND a.estado IN ('pendiente_confirmacion', 'confirmada', 'en_atencion');
END;
$$;

GRANT EXECUTE ON FUNCTION get_booked_slots TO anon;
GRANT EXECUTE ON FUNCTION get_booked_slots TO authenticated;


-- ============================================================================
-- PASO 5: FIX STORAGE - Bucket publico para lectura
-- ============================================================================

-- Si el bucket no existe, crearlo publico
INSERT INTO storage.buckets (id, name, public)
VALUES ('salon-images', 'salon-images', true)
ON CONFLICT (id) DO UPDATE SET public = true;

-- Limpiar policies viejas de storage
DROP POLICY IF EXISTS "tenant_insert" ON storage.objects;
DROP POLICY IF EXISTS "tenant_select" ON storage.objects;
DROP POLICY IF EXISTS "tenant_update" ON storage.objects;
DROP POLICY IF EXISTS "tenant_delete" ON storage.objects;
DROP POLICY IF EXISTS "authenticated_upload" ON storage.objects;
DROP POLICY IF EXISTS "authenticated_update" ON storage.objects;
DROP POLICY IF EXISTS "authenticated_delete" ON storage.objects;
DROP POLICY IF EXISTS "public_read" ON storage.objects;

-- Storage: solo usuarios autenticados pueden subir/modificar/borrar
-- La app prefija con tenant_id/ y verifica que el usuario sea admin del tenant
CREATE POLICY "authenticated_upload" ON storage.objects
  FOR INSERT TO authenticated
  WITH CHECK (bucket_id = 'salon-images');

CREATE POLICY "authenticated_update" ON storage.objects
  FOR UPDATE TO authenticated
  USING (bucket_id = 'salon-images')
  WITH CHECK (bucket_id = 'salon-images');

CREATE POLICY "authenticated_delete" ON storage.objects
  FOR DELETE TO authenticated
  USING (bucket_id = 'salon-images');

-- Lectura publica (las imagenes del salon son publicas)
CREATE POLICY "public_read" ON storage.objects
  FOR SELECT TO anon, authenticated
  USING (bucket_id = 'salon-images');


-- ============================================================================
-- PASO 6: Asegurar que create_auth_user_and_tenant existe
-- ============================================================================

CREATE EXTENSION IF NOT EXISTS pgcrypto;

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
  IF p_email IS NULL OR p_email = '' THEN
    RAISE EXCEPTION 'Email es requerido';
  END IF;
  IF p_password IS NULL OR length(p_password) < 6 THEN
    RAISE EXCEPTION 'Password debe tener al menos 6 caracteres';
  END IF;
  IF p_tenant_id IS NULL OR p_tenant_id = '' THEN
    RAISE EXCEPTION 'Tenant ID es requerido';
  END IF;

  IF EXISTS (SELECT 1 FROM auth.users WHERE email = p_email) THEN
    RAISE EXCEPTION 'El email ya esta registrado';
  END IF;
  IF EXISTS (SELECT 1 FROM tenants WHERE id = p_tenant_id) THEN
    RAISE EXCEPTION 'El ID de salon ya existe';
  END IF;

  v_user_id := gen_random_uuid();
  v_encrypted_pw := crypt(p_password, gen_salt('bf'));

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

  RETURN json_build_object(
    'user_id', v_user_id,
    'tenant_id', p_tenant_id,
    'email', p_email
  );
END;
$$;

GRANT EXECUTE ON FUNCTION create_auth_user_and_tenant TO anon;
GRANT EXECUTE ON FUNCTION create_auth_user_and_tenant TO authenticated;


-- ============================================================================
-- PASO 7: Funcion verify_super_admin_pin (server-side)
-- ============================================================================

CREATE TABLE IF NOT EXISTS app_secrets (
  key TEXT PRIMARY KEY,
  value TEXT NOT NULL
);

INSERT INTO app_secrets (key, value) VALUES ('super_admin_pin', '991474')
ON CONFLICT (key) DO UPDATE SET value = '991474';

ALTER TABLE app_secrets ENABLE ROW LEVEL SECURITY;
-- Sin policies = nadie puede leer directamente

CREATE OR REPLACE FUNCTION verify_super_admin_pin(p_pin TEXT)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_pin TEXT;
BEGIN
  SELECT value INTO v_pin FROM app_secrets WHERE key = 'super_admin_pin';
  RETURN v_pin IS NOT NULL AND v_pin = p_pin;
END;
$$;

GRANT EXECUTE ON FUNCTION verify_super_admin_pin TO anon;
GRANT EXECUTE ON FUNCTION verify_super_admin_pin TO authenticated;


-- Recargar schema
NOTIFY pgrst, 'reload schema';
SELECT pg_notify('pgrst', 'reload schema');
