-- ============================================================
-- 013: Clientes + Historia Clínica (Observaciones)
-- Tablas nuevas con aislamiento por tenant_id.
-- Solo acceso admin (authenticated) - sin acceso público (anon).
-- Seguro para salones existentes: tablas nuevas, empiezan vacías.
-- ============================================================

-- =====================
-- Tabla: clientes
-- =====================
CREATE TABLE IF NOT EXISTS clientes (
  id TEXT DEFAULT gen_random_uuid()::text PRIMARY KEY,
  tenant_id TEXT NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  nombre TEXT NOT NULL,
  telefono TEXT NOT NULL,
  email TEXT DEFAULT '',
  notas TEXT DEFAULT '',
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  -- Un mismo teléfono no puede estar dos veces en el mismo salón
  UNIQUE(tenant_id, telefono)
);

-- =====================
-- Tabla: cliente_observaciones (historia clínica)
-- =====================
CREATE TABLE IF NOT EXISTS cliente_observaciones (
  id TEXT DEFAULT gen_random_uuid()::text PRIMARY KEY,
  tenant_id TEXT NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  cliente_id TEXT NOT NULL REFERENCES clientes(id) ON DELETE CASCADE,
  fecha DATE NOT NULL DEFAULT CURRENT_DATE,
  servicio_nombre TEXT DEFAULT '',
  professional_nombre TEXT DEFAULT '',
  observacion TEXT NOT NULL DEFAULT '',
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- =====================
-- Índices para búsqueda rápida
-- =====================
CREATE INDEX IF NOT EXISTS idx_clientes_tenant ON clientes(tenant_id);
CREATE INDEX IF NOT EXISTS idx_clientes_tenant_telefono ON clientes(tenant_id, telefono);
CREATE INDEX IF NOT EXISTS idx_clientes_tenant_nombre ON clientes(tenant_id, lower(nombre));
CREATE INDEX IF NOT EXISTS idx_observaciones_cliente ON cliente_observaciones(cliente_id);
CREATE INDEX IF NOT EXISTS idx_observaciones_tenant ON cliente_observaciones(tenant_id);

-- =====================
-- RLS: clientes
-- Mismo patrón que waitlist: solo admin autenticado, sin acceso anon
-- =====================
ALTER TABLE clientes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "tenant_select" ON clientes FOR SELECT TO authenticated
  USING (
    tenant_id IN (SELECT id FROM tenants WHERE admin_user_id = auth.uid())
    OR current_setting('request.jwt.claim.super_admin', true) = 'true'
  );

CREATE POLICY "tenant_insert" ON clientes FOR INSERT TO authenticated
  WITH CHECK (
    tenant_id IN (SELECT id FROM tenants WHERE admin_user_id = auth.uid())
    OR current_setting('request.jwt.claim.super_admin', true) = 'true'
  );

CREATE POLICY "tenant_update" ON clientes FOR UPDATE TO authenticated
  USING (
    tenant_id IN (SELECT id FROM tenants WHERE admin_user_id = auth.uid())
    OR current_setting('request.jwt.claim.super_admin', true) = 'true'
  )
  WITH CHECK (
    tenant_id IN (SELECT id FROM tenants WHERE admin_user_id = auth.uid())
    OR current_setting('request.jwt.claim.super_admin', true) = 'true'
  );

CREATE POLICY "tenant_delete" ON clientes FOR DELETE TO authenticated
  USING (
    tenant_id IN (SELECT id FROM tenants WHERE admin_user_id = auth.uid())
    OR current_setting('request.jwt.claim.super_admin', true) = 'true'
  );

-- =====================
-- RLS: cliente_observaciones
-- Mismo patrón: solo admin autenticado, sin acceso anon
-- =====================
ALTER TABLE cliente_observaciones ENABLE ROW LEVEL SECURITY;

CREATE POLICY "tenant_select" ON cliente_observaciones FOR SELECT TO authenticated
  USING (
    tenant_id IN (SELECT id FROM tenants WHERE admin_user_id = auth.uid())
    OR current_setting('request.jwt.claim.super_admin', true) = 'true'
  );

CREATE POLICY "tenant_insert" ON cliente_observaciones FOR INSERT TO authenticated
  WITH CHECK (
    tenant_id IN (SELECT id FROM tenants WHERE admin_user_id = auth.uid())
    OR current_setting('request.jwt.claim.super_admin', true) = 'true'
  );

CREATE POLICY "tenant_update" ON cliente_observaciones FOR UPDATE TO authenticated
  USING (
    tenant_id IN (SELECT id FROM tenants WHERE admin_user_id = auth.uid())
    OR current_setting('request.jwt.claim.super_admin', true) = 'true'
  )
  WITH CHECK (
    tenant_id IN (SELECT id FROM tenants WHERE admin_user_id = auth.uid())
    OR current_setting('request.jwt.claim.super_admin', true) = 'true'
  );

CREATE POLICY "tenant_delete" ON cliente_observaciones FOR DELETE TO authenticated
  USING (
    tenant_id IN (SELECT id FROM tenants WHERE admin_user_id = auth.uid())
    OR current_setting('request.jwt.claim.super_admin', true) = 'true'
  );
