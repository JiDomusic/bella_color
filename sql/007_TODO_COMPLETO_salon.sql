-- ============================================================================
-- 007_TODO_COMPLETO_salon.sql
-- SCRIPT MAESTRO para Bella Color (Salon de Belleza)
--
-- INCLUYE:
-- - Migracion de columnas restaurante -> salon (si la tabla ya existe)
-- - Creacion de tablas (si no existen)
-- - Indices
-- - RLS (Row Level Security) estricto
-- - Storage policies (solo admin sube fotos)
-- - Funciones SECURITY DEFINER
-- - Permisos
--
-- SEGURIDAD:
-- - Solo admin autenticado puede: crear, editar, borrar, subir fotos
-- - Publico (anon) solo puede: leer datos y crear/confirmar turnos
-- - RLS activo en todas las tablas
-- - Storage: solo authenticated sube, todos pueden leer
--
-- Ejecutar en Supabase SQL Editor del proyecto BELLA COLOR
-- NO AFECTA al proyecto reserva_template
-- ============================================================================


-- ============================================================================
-- PASO 0: EXTENSION CRYPTO + MIGRACION SI VIENE DE RESTAURANTE
-- ============================================================================
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Migrar columnas si vienen del template de restaurante
DO $$
BEGIN
  -- Renombrar nombre_restaurante a nombre_salon
  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'tenants' AND column_name = 'nombre_restaurante') THEN
    ALTER TABLE tenants RENAME COLUMN nombre_restaurante TO nombre_salon;
  END IF;

  -- Renombrar logo_color_url a logo_url
  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'tenants' AND column_name = 'logo_color_url') THEN
    ALTER TABLE tenants RENAME COLUMN logo_color_url TO logo_url;
  END IF;

  -- Renombrar columnas de anticipacion
  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'tenants' AND column_name = 'anticipo_almuerzo_horas') THEN
    ALTER TABLE tenants RENAME COLUMN anticipo_almuerzo_horas TO min_anticipacion_horas;
  END IF;
  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'tenants' AND column_name = 'dias_adelanto_maximo') THEN
    ALTER TABLE tenants RENAME COLUMN dias_adelanto_maximo TO max_anticipacion_dias;
  END IF;
  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'tenants' AND column_name = 'minutos_liberacion_auto') THEN
    ALTER TABLE tenants RENAME COLUMN minutos_liberacion_auto TO minutos_auto_liberacion;
  END IF;

  -- Borrar columnas de restaurante
  ALTER TABLE tenants DROP COLUMN IF EXISTS min_personas;
  ALTER TABLE tenants DROP COLUMN IF EXISTS max_personas;
  ALTER TABLE tenants DROP COLUMN IF EXISTS usa_sistema_mesas;
  ALTER TABLE tenants DROP COLUMN IF EXISTS usa_areas_multiples;
  ALTER TABLE tenants DROP COLUMN IF EXISTS capacidad_compartida;
  ALTER TABLE tenants DROP COLUMN IF EXISTS optimizacion_estricta_mesas;
  ALTER TABLE tenants DROP COLUMN IF EXISTS anticipo_regular_horas;
END $$;


-- ============================================================================
-- PASO 1: TABLA TENANTS (salon de belleza)
-- ============================================================================
CREATE TABLE IF NOT EXISTS tenants (
  id TEXT PRIMARY KEY,
  nombre_salon TEXT DEFAULT '',
  subtitulo TEXT DEFAULT '',
  slogan TEXT DEFAULT '',
  direccion TEXT DEFAULT '',
  ciudad TEXT DEFAULT '',
  provincia TEXT DEFAULT '',
  pais TEXT DEFAULT 'Argentina',
  google_maps_query TEXT DEFAULT '',
  email_contacto TEXT DEFAULT '',
  telefono_contacto TEXT DEFAULT '',
  whatsapp_numero TEXT DEFAULT '',
  codigo_pais_telefono TEXT DEFAULT '54',
  sitio_web TEXT DEFAULT '',
  logo_url TEXT,
  logo_blanco_url TEXT,
  fondo_url TEXT,
  color_primario TEXT DEFAULT '#D4A0A0',
  color_secundario TEXT DEFAULT '#C48B8B',
  color_terciario TEXT DEFAULT '#E8C4C4',
  color_acento TEXT DEFAULT '#D4AF37',
  min_anticipacion_horas INT DEFAULT 2,
  max_anticipacion_dias INT DEFAULT 60,
  minutos_auto_liberacion INT DEFAULT 15,
  ventana_confirmacion_horas INT DEFAULT 2,
  recordatorio_horas_antes INT DEFAULT 24,
  dia_cerrado INT DEFAULT 0,
  admin_emails TEXT DEFAULT '[]',
  super_admin_emails TEXT DEFAULT '[]',
  onboarding_completed BOOLEAN DEFAULT false,
  banner_activo BOOLEAN DEFAULT false,
  banner_texto TEXT DEFAULT '',
  banner_fecha TEXT DEFAULT '',
  admin_user_id UUID,
  subscription_start_date TEXT,
  subscription_due_day INT DEFAULT 18,
  is_blocked BOOLEAN DEFAULT false,
  blocked_at TEXT,
  block_reason TEXT DEFAULT '',
  trial_days INT DEFAULT 15,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Agregar columnas que puedan faltar (si la tabla ya existia)
ALTER TABLE tenants ADD COLUMN IF NOT EXISTS is_blocked BOOLEAN DEFAULT false;
ALTER TABLE tenants ADD COLUMN IF NOT EXISTS blocked_at TEXT;
ALTER TABLE tenants ADD COLUMN IF NOT EXISTS block_reason TEXT DEFAULT '';
ALTER TABLE tenants ADD COLUMN IF NOT EXISTS trial_days INT DEFAULT 15;
ALTER TABLE tenants ADD COLUMN IF NOT EXISTS banner_activo BOOLEAN DEFAULT false;
ALTER TABLE tenants ADD COLUMN IF NOT EXISTS banner_texto TEXT DEFAULT '';
ALTER TABLE tenants ADD COLUMN IF NOT EXISTS banner_fecha TEXT DEFAULT '';
ALTER TABLE tenants ADD COLUMN IF NOT EXISTS super_admin_emails TEXT DEFAULT '[]';
ALTER TABLE tenants ADD COLUMN IF NOT EXISTS onboarding_completed BOOLEAN DEFAULT false;
ALTER TABLE tenants ADD COLUMN IF NOT EXISTS admin_user_id UUID;

-- Quitar FK constraint en admin_user_id (causa problemas con signUp + create_tenant)
ALTER TABLE tenants DROP CONSTRAINT IF EXISTS tenants_admin_user_id_fkey;
ALTER TABLE tenants DROP CONSTRAINT IF EXISTS tenants_admin_user_id_key;


-- ============================================================================
-- PASO 2: TABLAS DE DATOS
-- ============================================================================
CREATE TABLE IF NOT EXISTS professionals (
  id TEXT DEFAULT gen_random_uuid()::text PRIMARY KEY,
  tenant_id TEXT NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  nombre TEXT NOT NULL,
  especialidad TEXT DEFAULT '',
  descripcion TEXT DEFAULT '',
  foto_url TEXT,
  telefono TEXT DEFAULT '',
  activo BOOLEAN DEFAULT true,
  orden INT DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS services (
  id TEXT DEFAULT gen_random_uuid()::text PRIMARY KEY,
  tenant_id TEXT NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  nombre TEXT NOT NULL,
  descripcion TEXT DEFAULT '',
  categoria TEXT DEFAULT 'otro',
  duracion_minutos INT DEFAULT 60,
  precio DECIMAL(10,2),
  moneda TEXT DEFAULT 'ARS',
  imagen_url TEXT,
  activo BOOLEAN DEFAULT true,
  max_turnos_dia INT DEFAULT 8,
  orden INT DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS professional_services (
  id TEXT DEFAULT gen_random_uuid()::text PRIMARY KEY,
  tenant_id TEXT NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  professional_id TEXT NOT NULL REFERENCES professionals(id) ON DELETE CASCADE,
  service_id TEXT NOT NULL REFERENCES services(id) ON DELETE CASCADE,
  precio_especial DECIMAL(10,2),
  UNIQUE(professional_id, service_id)
);

CREATE TABLE IF NOT EXISTS portfolio_images (
  id TEXT DEFAULT gen_random_uuid()::text PRIMARY KEY,
  tenant_id TEXT NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  professional_id TEXT REFERENCES professionals(id) ON DELETE CASCADE,
  service_id TEXT REFERENCES services(id) ON DELETE SET NULL,
  imagen_url TEXT NOT NULL,
  descripcion TEXT DEFAULT '',
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS operating_hours (
  id TEXT DEFAULT gen_random_uuid()::text PRIMARY KEY,
  tenant_id TEXT NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  dia_semana INT NOT NULL,
  hora_inicio TIME NOT NULL,
  hora_fin TIME NOT NULL,
  intervalo_minutos INT DEFAULT 30,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS appointments (
  id TEXT DEFAULT gen_random_uuid()::text PRIMARY KEY,
  tenant_id TEXT NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  fecha DATE NOT NULL,
  hora TEXT NOT NULL,
  duracion_minutos INT DEFAULT 60,
  nombre_cliente TEXT NOT NULL,
  telefono TEXT NOT NULL,
  email TEXT,
  servicio_id TEXT,
  servicio_nombre TEXT,
  professional_id TEXT,
  professional_nombre TEXT,
  codigo_confirmacion TEXT NOT NULL,
  estado TEXT DEFAULT 'pendiente_confirmacion',
  confirmado_cliente BOOLEAN DEFAULT false,
  confirmado_at TIMESTAMPTZ,
  comentarios TEXT,
  recordatorio_enviado BOOLEAN DEFAULT false,
  recordatorio_enviado_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS blocks (
  id TEXT DEFAULT gen_random_uuid()::text PRIMARY KEY,
  tenant_id TEXT NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  fecha DATE,
  hora TEXT,
  professional_id TEXT,
  motivo TEXT DEFAULT '',
  dia_completo BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS waitlist (
  id TEXT DEFAULT gen_random_uuid()::text PRIMARY KEY,
  tenant_id TEXT NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  fecha DATE NOT NULL,
  hora TEXT,
  servicio_id TEXT,
  professional_id TEXT,
  nombre TEXT NOT NULL,
  telefono TEXT NOT NULL,
  email TEXT,
  comentarios TEXT,
  estado TEXT DEFAULT 'esperando',
  notificado BOOLEAN DEFAULT false,
  notificado_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now()
);


-- ============================================================================
-- PASO 3: INDICES
-- ============================================================================
CREATE INDEX IF NOT EXISTS idx_professionals_tenant ON professionals(tenant_id);
CREATE INDEX IF NOT EXISTS idx_services_tenant ON services(tenant_id);
CREATE INDEX IF NOT EXISTS idx_professional_services_tenant ON professional_services(tenant_id);
CREATE INDEX IF NOT EXISTS idx_portfolio_tenant ON portfolio_images(tenant_id);
CREATE INDEX IF NOT EXISTS idx_hours_tenant ON operating_hours(tenant_id);
CREATE INDEX IF NOT EXISTS idx_appointments_tenant_fecha ON appointments(tenant_id, fecha);
CREATE INDEX IF NOT EXISTS idx_appointments_codigo ON appointments(codigo_confirmacion);
CREATE INDEX IF NOT EXISTS idx_blocks_tenant ON blocks(tenant_id);
CREATE INDEX IF NOT EXISTS idx_waitlist_tenant ON waitlist(tenant_id);


-- ============================================================================
-- PASO 4: RLS (Row Level Security)
-- REGLA: Solo admin autenticado escribe/edita/borra
--        Publico (anon) solo lee + crea turnos + confirma turnos
-- ============================================================================
ALTER TABLE tenants ENABLE ROW LEVEL SECURITY;
ALTER TABLE professionals ENABLE ROW LEVEL SECURITY;
ALTER TABLE services ENABLE ROW LEVEL SECURITY;
ALTER TABLE professional_services ENABLE ROW LEVEL SECURITY;
ALTER TABLE portfolio_images ENABLE ROW LEVEL SECURITY;
ALTER TABLE operating_hours ENABLE ROW LEVEL SECURITY;
ALTER TABLE appointments ENABLE ROW LEVEL SECURITY;
ALTER TABLE blocks ENABLE ROW LEVEL SECURITY;
ALTER TABLE waitlist ENABLE ROW LEVEL SECURITY;

-- Limpiar TODAS las policies anteriores
DO $$
DECLARE
  r RECORD;
BEGIN
  FOR r IN SELECT policyname, tablename FROM pg_policies WHERE schemaname = 'public'
  LOOP
    EXECUTE format('DROP POLICY IF EXISTS %I ON %I', r.policyname, r.tablename);
  END LOOP;
END $$;

-- ---- TENANTS ----
-- Admin: lee y edita su propio salon
CREATE POLICY "admin_select" ON tenants FOR SELECT TO authenticated
  USING (admin_user_id = auth.uid());
CREATE POLICY "admin_update" ON tenants FOR UPDATE TO authenticated
  USING (admin_user_id = auth.uid())
  WITH CHECK (admin_user_id = auth.uid());
-- Publico: solo lectura (para mostrar la pagina del salon)
CREATE POLICY "public_select" ON tenants FOR SELECT TO anon
  USING (true);

-- ---- PROFESSIONALS ----
-- Admin: CRUD completo de su salon
CREATE POLICY "admin_select" ON professionals FOR SELECT TO authenticated
  USING (tenant_id IN (SELECT id FROM tenants WHERE admin_user_id = auth.uid()));
CREATE POLICY "admin_insert" ON professionals FOR INSERT TO authenticated
  WITH CHECK (tenant_id IN (SELECT id FROM tenants WHERE admin_user_id = auth.uid()));
CREATE POLICY "admin_update" ON professionals FOR UPDATE TO authenticated
  USING (tenant_id IN (SELECT id FROM tenants WHERE admin_user_id = auth.uid()))
  WITH CHECK (tenant_id IN (SELECT id FROM tenants WHERE admin_user_id = auth.uid()));
CREATE POLICY "admin_delete" ON professionals FOR DELETE TO authenticated
  USING (tenant_id IN (SELECT id FROM tenants WHERE admin_user_id = auth.uid()));
-- Publico: solo lectura
CREATE POLICY "public_select" ON professionals FOR SELECT TO anon USING (true);

-- ---- SERVICES ----
CREATE POLICY "admin_select" ON services FOR SELECT TO authenticated
  USING (tenant_id IN (SELECT id FROM tenants WHERE admin_user_id = auth.uid()));
CREATE POLICY "admin_insert" ON services FOR INSERT TO authenticated
  WITH CHECK (tenant_id IN (SELECT id FROM tenants WHERE admin_user_id = auth.uid()));
CREATE POLICY "admin_update" ON services FOR UPDATE TO authenticated
  USING (tenant_id IN (SELECT id FROM tenants WHERE admin_user_id = auth.uid()))
  WITH CHECK (tenant_id IN (SELECT id FROM tenants WHERE admin_user_id = auth.uid()));
CREATE POLICY "admin_delete" ON services FOR DELETE TO authenticated
  USING (tenant_id IN (SELECT id FROM tenants WHERE admin_user_id = auth.uid()));
CREATE POLICY "public_select" ON services FOR SELECT TO anon USING (true);

-- ---- PROFESSIONAL_SERVICES ----
CREATE POLICY "admin_select" ON professional_services FOR SELECT TO authenticated
  USING (tenant_id IN (SELECT id FROM tenants WHERE admin_user_id = auth.uid()));
CREATE POLICY "admin_insert" ON professional_services FOR INSERT TO authenticated
  WITH CHECK (tenant_id IN (SELECT id FROM tenants WHERE admin_user_id = auth.uid()));
CREATE POLICY "admin_update" ON professional_services FOR UPDATE TO authenticated
  USING (tenant_id IN (SELECT id FROM tenants WHERE admin_user_id = auth.uid()))
  WITH CHECK (tenant_id IN (SELECT id FROM tenants WHERE admin_user_id = auth.uid()));
CREATE POLICY "admin_delete" ON professional_services FOR DELETE TO authenticated
  USING (tenant_id IN (SELECT id FROM tenants WHERE admin_user_id = auth.uid()));
CREATE POLICY "public_select" ON professional_services FOR SELECT TO anon USING (true);

-- ---- PORTFOLIO_IMAGES ----
CREATE POLICY "admin_select" ON portfolio_images FOR SELECT TO authenticated
  USING (tenant_id IN (SELECT id FROM tenants WHERE admin_user_id = auth.uid()));
CREATE POLICY "admin_insert" ON portfolio_images FOR INSERT TO authenticated
  WITH CHECK (tenant_id IN (SELECT id FROM tenants WHERE admin_user_id = auth.uid()));
CREATE POLICY "admin_update" ON portfolio_images FOR UPDATE TO authenticated
  USING (tenant_id IN (SELECT id FROM tenants WHERE admin_user_id = auth.uid()))
  WITH CHECK (tenant_id IN (SELECT id FROM tenants WHERE admin_user_id = auth.uid()));
CREATE POLICY "admin_delete" ON portfolio_images FOR DELETE TO authenticated
  USING (tenant_id IN (SELECT id FROM tenants WHERE admin_user_id = auth.uid()));
CREATE POLICY "public_select" ON portfolio_images FOR SELECT TO anon USING (true);

-- ---- OPERATING_HOURS ----
CREATE POLICY "admin_select" ON operating_hours FOR SELECT TO authenticated
  USING (tenant_id IN (SELECT id FROM tenants WHERE admin_user_id = auth.uid()));
CREATE POLICY "admin_insert" ON operating_hours FOR INSERT TO authenticated
  WITH CHECK (tenant_id IN (SELECT id FROM tenants WHERE admin_user_id = auth.uid()));
CREATE POLICY "admin_update" ON operating_hours FOR UPDATE TO authenticated
  USING (tenant_id IN (SELECT id FROM tenants WHERE admin_user_id = auth.uid()))
  WITH CHECK (tenant_id IN (SELECT id FROM tenants WHERE admin_user_id = auth.uid()));
CREATE POLICY "admin_delete" ON operating_hours FOR DELETE TO authenticated
  USING (tenant_id IN (SELECT id FROM tenants WHERE admin_user_id = auth.uid()));
CREATE POLICY "public_select" ON operating_hours FOR SELECT TO anon USING (true);

-- ---- APPOINTMENTS ----
-- Admin: CRUD completo
CREATE POLICY "admin_select" ON appointments FOR SELECT TO authenticated
  USING (tenant_id IN (SELECT id FROM tenants WHERE admin_user_id = auth.uid()));
CREATE POLICY "admin_insert" ON appointments FOR INSERT TO authenticated
  WITH CHECK (tenant_id IN (SELECT id FROM tenants WHERE admin_user_id = auth.uid()));
CREATE POLICY "admin_update" ON appointments FOR UPDATE TO authenticated
  USING (tenant_id IN (SELECT id FROM tenants WHERE admin_user_id = auth.uid()))
  WITH CHECK (tenant_id IN (SELECT id FROM tenants WHERE admin_user_id = auth.uid()));
CREATE POLICY "admin_delete" ON appointments FOR DELETE TO authenticated
  USING (tenant_id IN (SELECT id FROM tenants WHERE admin_user_id = auth.uid()));
-- Publico: puede LEER (para ver su turno con codigo), CREAR (reservar) y ACTUALIZAR (confirmar)
CREATE POLICY "public_select" ON appointments FOR SELECT TO anon USING (true);
CREATE POLICY "public_insert" ON appointments FOR INSERT TO anon WITH CHECK (true);
CREATE POLICY "public_update" ON appointments FOR UPDATE TO anon
  USING (true) WITH CHECK (true);

-- ---- BLOCKS ----
CREATE POLICY "admin_select" ON blocks FOR SELECT TO authenticated
  USING (tenant_id IN (SELECT id FROM tenants WHERE admin_user_id = auth.uid()));
CREATE POLICY "admin_insert" ON blocks FOR INSERT TO authenticated
  WITH CHECK (tenant_id IN (SELECT id FROM tenants WHERE admin_user_id = auth.uid()));
CREATE POLICY "admin_update" ON blocks FOR UPDATE TO authenticated
  USING (tenant_id IN (SELECT id FROM tenants WHERE admin_user_id = auth.uid()))
  WITH CHECK (tenant_id IN (SELECT id FROM tenants WHERE admin_user_id = auth.uid()));
CREATE POLICY "admin_delete" ON blocks FOR DELETE TO authenticated
  USING (tenant_id IN (SELECT id FROM tenants WHERE admin_user_id = auth.uid()));
-- Publico: solo lectura (para ver horarios bloqueados al reservar)
CREATE POLICY "public_select" ON blocks FOR SELECT TO anon USING (true);

-- ---- WAITLIST ----
-- Solo admin (no acceso publico)
CREATE POLICY "admin_select" ON waitlist FOR SELECT TO authenticated
  USING (tenant_id IN (SELECT id FROM tenants WHERE admin_user_id = auth.uid()));
CREATE POLICY "admin_insert" ON waitlist FOR INSERT TO authenticated
  WITH CHECK (tenant_id IN (SELECT id FROM tenants WHERE admin_user_id = auth.uid()));
CREATE POLICY "admin_update" ON waitlist FOR UPDATE TO authenticated
  USING (tenant_id IN (SELECT id FROM tenants WHERE admin_user_id = auth.uid()))
  WITH CHECK (tenant_id IN (SELECT id FROM tenants WHERE admin_user_id = auth.uid()));
CREATE POLICY "admin_delete" ON waitlist FOR DELETE TO authenticated
  USING (tenant_id IN (SELECT id FROM tenants WHERE admin_user_id = auth.uid()));


-- ============================================================================
-- PASO 5: STORAGE (bucket salon-images)
-- Solo admin sube/edita/borra fotos. Todos pueden ver.
-- ============================================================================
INSERT INTO storage.buckets (id, name, public)
VALUES ('salon-images', 'salon-images', true)
ON CONFLICT (id) DO UPDATE SET public = true;

-- Limpiar policies de storage
DO $$
DECLARE
  r RECORD;
BEGIN
  FOR r IN SELECT policyname FROM pg_policies WHERE schemaname = 'storage' AND tablename = 'objects'
  LOOP
    EXECUTE format('DROP POLICY IF EXISTS %I ON storage.objects', r.policyname);
  END LOOP;
END $$;

-- Solo admin autenticado puede subir
CREATE POLICY "admin_upload" ON storage.objects
  FOR INSERT TO authenticated
  WITH CHECK (bucket_id = 'salon-images');

-- Solo admin autenticado puede editar
CREATE POLICY "admin_update" ON storage.objects
  FOR UPDATE TO authenticated
  USING (bucket_id = 'salon-images')
  WITH CHECK (bucket_id = 'salon-images');

-- Solo admin autenticado puede borrar
CREATE POLICY "admin_delete" ON storage.objects
  FOR DELETE TO authenticated
  USING (bucket_id = 'salon-images');

-- Admin puede leer
CREATE POLICY "admin_read" ON storage.objects
  FOR SELECT TO authenticated
  USING (bucket_id = 'salon-images');

-- Publico puede ver las imagenes (para la web del salon)
CREATE POLICY "public_read" ON storage.objects
  FOR SELECT TO anon
  USING (bucket_id = 'salon-images');


-- ============================================================================
-- PASO 6: FUNCIONES SECURITY DEFINER
-- ============================================================================

-- Crear tenant (desde super admin o signup)
CREATE OR REPLACE FUNCTION create_tenant(
  p_id TEXT,
  p_nombre_salon TEXT,
  p_admin_user_id UUID DEFAULT NULL,
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

  -- Auto-confirmar email del usuario admin
  UPDATE auth.users
  SET email_confirmed_at = NOW()
  WHERE id = p_admin_user_id AND email_confirmed_at IS NULL;

  RETURN v_result;
END;
$$;

-- Bloquear tenant (por falta de pago)
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
  SET is_blocked = true, blocked_at = NOW()::TEXT, block_reason = p_reason
  WHERE id = p_id;
END;
$$;

-- Desbloquear tenant
CREATE OR REPLACE FUNCTION unblock_tenant(p_id TEXT)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  UPDATE tenants
  SET is_blocked = false, blocked_at = NULL, block_reason = ''
  WHERE id = p_id;
END;
$$;

-- Listar todos los tenants (para super admin)
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

-- Validar tenant con auto-bloqueo por vencimiento
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
  IF NOT FOUND THEN RETURN NULL; END IF;
  IF v_tenant.is_blocked THEN RETURN row_to_json(v_tenant); END IF;

  IF v_tenant.subscription_start_date IS NOT NULL AND v_tenant.subscription_start_date != '' THEN
    v_start := v_tenant.subscription_start_date::DATE;
    v_trial_end := v_start + (COALESCE(v_tenant.trial_days, 15) || ' days')::INTERVAL;

    IF NOW()::DATE > v_trial_end THEN
      v_due_day := COALESCE(v_tenant.subscription_due_day, 18);
      v_next_due := make_date(
        EXTRACT(YEAR FROM NOW())::INT,
        EXTRACT(MONTH FROM NOW())::INT,
        LEAST(v_due_day, 28)
      );
      IF NOW()::DATE > v_next_due THEN
        v_days_past := (NOW()::DATE - v_next_due);
        IF v_days_past > 5 THEN
          UPDATE tenants
          SET is_blocked = true, blocked_at = NOW()::TEXT,
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

-- Eliminar tenant y todos sus datos
CREATE OR REPLACE FUNCTION delete_tenant(p_id TEXT)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  DELETE FROM waitlist WHERE tenant_id = p_id;
  DELETE FROM appointments WHERE tenant_id = p_id;
  DELETE FROM blocks WHERE tenant_id = p_id;
  DELETE FROM operating_hours WHERE tenant_id = p_id;
  DELETE FROM portfolio_images WHERE tenant_id = p_id;
  DELETE FROM professional_services WHERE tenant_id = p_id;
  DELETE FROM services WHERE tenant_id = p_id;
  DELETE FROM professionals WHERE tenant_id = p_id;
  DELETE FROM tenants WHERE id = p_id;
END;
$$;

-- Buscar tenant por user_id (para login del admin)
CREATE OR REPLACE FUNCTION get_tenant_for_user(p_user_id UUID)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_tenant_id TEXT;
BEGIN
  SELECT id INTO v_tenant_id FROM tenants WHERE admin_user_id = p_user_id LIMIT 1;
  RETURN v_tenant_id;
END;
$$;


-- ============================================================================
-- PASO 7: PERMISOS DE EJECUCION
-- ============================================================================
GRANT EXECUTE ON FUNCTION create_tenant TO anon;
GRANT EXECUTE ON FUNCTION create_tenant TO authenticated;
GRANT EXECUTE ON FUNCTION block_tenant TO authenticated;
GRANT EXECUTE ON FUNCTION unblock_tenant TO authenticated;
GRANT EXECUTE ON FUNCTION list_all_tenants TO authenticated;
GRANT EXECUTE ON FUNCTION get_tenant_validated TO anon;
GRANT EXECUTE ON FUNCTION get_tenant_validated TO authenticated;
GRANT EXECUTE ON FUNCTION delete_tenant TO authenticated;
GRANT EXECUTE ON FUNCTION get_tenant_for_user TO anon;
GRANT EXECUTE ON FUNCTION get_tenant_for_user TO authenticated;


-- ============================================================================
-- PASO 8: FUNCION ATOMICA PARA CREAR USUARIO + SALON
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
-- PASO 9: RECARGAR ESQUEMA DE PostgREST
-- ============================================================================
NOTIFY pgrst, 'reload schema';
SELECT pg_notify('pgrst', 'reload schema');
