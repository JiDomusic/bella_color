-- ============================================================================
-- 001_schema.sql
-- Database schema for Bella Color - Beauty Salon Booking System (Multitenant)
-- Run in Supabase SQL Editor
-- ============================================================================

-- Tenants (Salons)
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
  admin_user_id UUID REFERENCES auth.users(id),
  subscription_start_date TEXT,
  subscription_due_day INT DEFAULT 18,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Professionals (staff)
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

-- Services catalog
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

-- Professional-Service relationship
CREATE TABLE IF NOT EXISTS professional_services (
  id TEXT DEFAULT gen_random_uuid()::text PRIMARY KEY,
  tenant_id TEXT NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  professional_id TEXT NOT NULL REFERENCES professionals(id) ON DELETE CASCADE,
  service_id TEXT NOT NULL REFERENCES services(id) ON DELETE CASCADE,
  precio_especial DECIMAL(10,2),
  UNIQUE(professional_id, service_id)
);

-- Portfolio images (work photos)
CREATE TABLE IF NOT EXISTS portfolio_images (
  id TEXT DEFAULT gen_random_uuid()::text PRIMARY KEY,
  tenant_id TEXT NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  professional_id TEXT REFERENCES professionals(id) ON DELETE CASCADE,
  service_id TEXT REFERENCES services(id) ON DELETE SET NULL,
  imagen_url TEXT NOT NULL,
  descripcion TEXT DEFAULT '',
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Operating hours
CREATE TABLE IF NOT EXISTS operating_hours (
  id TEXT DEFAULT gen_random_uuid()::text PRIMARY KEY,
  tenant_id TEXT NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  dia_semana INT NOT NULL,
  hora_inicio TIME NOT NULL,
  hora_fin TIME NOT NULL,
  intervalo_minutos INT DEFAULT 30,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Appointments (bookings)
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

-- Blocks (blocked days/hours/professionals)
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

-- Waitlist
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

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_professionals_tenant ON professionals(tenant_id);
CREATE INDEX IF NOT EXISTS idx_services_tenant ON services(tenant_id);
CREATE INDEX IF NOT EXISTS idx_professional_services_tenant ON professional_services(tenant_id);
CREATE INDEX IF NOT EXISTS idx_portfolio_tenant ON portfolio_images(tenant_id);
CREATE INDEX IF NOT EXISTS idx_hours_tenant ON operating_hours(tenant_id);
CREATE INDEX IF NOT EXISTS idx_appointments_tenant_fecha ON appointments(tenant_id, fecha);
CREATE INDEX IF NOT EXISTS idx_appointments_codigo ON appointments(codigo_confirmacion);
CREATE INDEX IF NOT EXISTS idx_blocks_tenant ON blocks(tenant_id);
CREATE INDEX IF NOT EXISTS idx_waitlist_tenant ON waitlist(tenant_id);
