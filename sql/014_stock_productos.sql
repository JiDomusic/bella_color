-- ============================================================
-- 014: Stock de Productos + Movimientos
-- Sistema de inventario para salones de belleza.
-- Solo acceso admin (authenticated) - sin acceso público (anon).
-- Seguro para salones existentes: tablas nuevas, empiezan vacías.
-- ============================================================

-- =====================
-- Tabla: productos (inventario del salón)
-- =====================
CREATE TABLE IF NOT EXISTS productos (
  id TEXT DEFAULT gen_random_uuid()::text PRIMARY KEY,
  tenant_id TEXT NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  nombre TEXT NOT NULL,
  marca TEXT DEFAULT '',
  codigo_barras TEXT DEFAULT '',
  cantidad INTEGER DEFAULT 0,
  categoria TEXT DEFAULT 'otro',
  -- categorías sugeridas: unas, cejas, color, peluqueria, maquillaje,
  --   depilacion, pestanas, cuidado_capilar, corporal, otro
  min_stock_alerta INTEGER DEFAULT 5,
  precio_costo DECIMAL(10,2),
  precio_venta DECIMAL(10,2),
  notas TEXT DEFAULT '',
  activo BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- =====================
-- Tabla: movimientos_stock (historial de entradas/salidas)
-- =====================
CREATE TABLE IF NOT EXISTS movimientos_stock (
  id TEXT DEFAULT gen_random_uuid()::text PRIMARY KEY,
  tenant_id TEXT NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  producto_id TEXT NOT NULL REFERENCES productos(id) ON DELETE CASCADE,
  cantidad INTEGER NOT NULL,  -- positivo = ingreso, negativo = egreso
  tipo TEXT DEFAULT 'ajuste', -- 'ingreso', 'egreso', 'venta', 'ajuste'
  motivo TEXT DEFAULT '',
  created_at TIMESTAMPTZ DEFAULT now()
);

-- =====================
-- Índices
-- =====================
CREATE INDEX IF NOT EXISTS idx_productos_tenant ON productos(tenant_id);
CREATE INDEX IF NOT EXISTS idx_productos_tenant_barcode ON productos(tenant_id, codigo_barras);
CREATE INDEX IF NOT EXISTS idx_productos_tenant_categoria ON productos(tenant_id, categoria);
CREATE INDEX IF NOT EXISTS idx_productos_bajo_stock ON productos(tenant_id, cantidad, min_stock_alerta);
CREATE INDEX IF NOT EXISTS idx_movimientos_producto ON movimientos_stock(producto_id);
CREATE INDEX IF NOT EXISTS idx_movimientos_tenant ON movimientos_stock(tenant_id);

-- =====================
-- RLS: productos
-- Solo admin autenticado, sin acceso público (como waitlist)
-- =====================
ALTER TABLE productos ENABLE ROW LEVEL SECURITY;

CREATE POLICY "tenant_select" ON productos FOR SELECT TO authenticated
  USING (
    tenant_id IN (SELECT id FROM tenants WHERE admin_user_id = auth.uid())
    OR current_setting('request.jwt.claim.super_admin', true) = 'true'
  );

CREATE POLICY "tenant_insert" ON productos FOR INSERT TO authenticated
  WITH CHECK (
    tenant_id IN (SELECT id FROM tenants WHERE admin_user_id = auth.uid())
    OR current_setting('request.jwt.claim.super_admin', true) = 'true'
  );

CREATE POLICY "tenant_update" ON productos FOR UPDATE TO authenticated
  USING (
    tenant_id IN (SELECT id FROM tenants WHERE admin_user_id = auth.uid())
    OR current_setting('request.jwt.claim.super_admin', true) = 'true'
  )
  WITH CHECK (
    tenant_id IN (SELECT id FROM tenants WHERE admin_user_id = auth.uid())
    OR current_setting('request.jwt.claim.super_admin', true) = 'true'
  );

CREATE POLICY "tenant_delete" ON productos FOR DELETE TO authenticated
  USING (
    tenant_id IN (SELECT id FROM tenants WHERE admin_user_id = auth.uid())
    OR current_setting('request.jwt.claim.super_admin', true) = 'true'
  );

-- =====================
-- RLS: movimientos_stock
-- Solo admin autenticado para SELECT e INSERT
-- No se editan ni borran movimientos (son un log)
-- =====================
ALTER TABLE movimientos_stock ENABLE ROW LEVEL SECURITY;

CREATE POLICY "tenant_select" ON movimientos_stock FOR SELECT TO authenticated
  USING (
    tenant_id IN (SELECT id FROM tenants WHERE admin_user_id = auth.uid())
    OR current_setting('request.jwt.claim.super_admin', true) = 'true'
  );

CREATE POLICY "tenant_insert" ON movimientos_stock FOR INSERT TO authenticated
  WITH CHECK (
    tenant_id IN (SELECT id FROM tenants WHERE admin_user_id = auth.uid())
    OR current_setting('request.jwt.claim.super_admin', true) = 'true'
  );
