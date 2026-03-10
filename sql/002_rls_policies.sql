-- ============================================================================
-- 002_rls_policies.sql
-- Row Level Security for Bella Color multitenant system
-- Run in Supabase SQL Editor
-- ============================================================================

-- Enable RLS on all tables
ALTER TABLE tenants ENABLE ROW LEVEL SECURITY;
ALTER TABLE professionals ENABLE ROW LEVEL SECURITY;
ALTER TABLE services ENABLE ROW LEVEL SECURITY;
ALTER TABLE professional_services ENABLE ROW LEVEL SECURITY;
ALTER TABLE portfolio_images ENABLE ROW LEVEL SECURITY;
ALTER TABLE operating_hours ENABLE ROW LEVEL SECURITY;
ALTER TABLE appointments ENABLE ROW LEVEL SECURITY;
ALTER TABLE blocks ENABLE ROW LEVEL SECURITY;
ALTER TABLE waitlist ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- Drop existing policies (clean slate)
-- ============================================================================
DROP POLICY IF EXISTS "tenant_select" ON tenants;
DROP POLICY IF EXISTS "tenant_update" ON tenants;
DROP POLICY IF EXISTS "public_select" ON tenants;

DROP POLICY IF EXISTS "tenant_select" ON professionals;
DROP POLICY IF EXISTS "tenant_insert" ON professionals;
DROP POLICY IF EXISTS "tenant_update" ON professionals;
DROP POLICY IF EXISTS "tenant_delete" ON professionals;
DROP POLICY IF EXISTS "public_select" ON professionals;

DROP POLICY IF EXISTS "tenant_select" ON services;
DROP POLICY IF EXISTS "tenant_insert" ON services;
DROP POLICY IF EXISTS "tenant_update" ON services;
DROP POLICY IF EXISTS "tenant_delete" ON services;
DROP POLICY IF EXISTS "public_select" ON services;

DROP POLICY IF EXISTS "tenant_select" ON professional_services;
DROP POLICY IF EXISTS "tenant_insert" ON professional_services;
DROP POLICY IF EXISTS "tenant_update" ON professional_services;
DROP POLICY IF EXISTS "tenant_delete" ON professional_services;
DROP POLICY IF EXISTS "public_select" ON professional_services;

DROP POLICY IF EXISTS "tenant_select" ON portfolio_images;
DROP POLICY IF EXISTS "tenant_insert" ON portfolio_images;
DROP POLICY IF EXISTS "tenant_update" ON portfolio_images;
DROP POLICY IF EXISTS "tenant_delete" ON portfolio_images;
DROP POLICY IF EXISTS "public_select" ON portfolio_images;

DROP POLICY IF EXISTS "tenant_select" ON operating_hours;
DROP POLICY IF EXISTS "tenant_insert" ON operating_hours;
DROP POLICY IF EXISTS "tenant_update" ON operating_hours;
DROP POLICY IF EXISTS "tenant_delete" ON operating_hours;
DROP POLICY IF EXISTS "public_select" ON operating_hours;

DROP POLICY IF EXISTS "tenant_select" ON appointments;
DROP POLICY IF EXISTS "tenant_insert" ON appointments;
DROP POLICY IF EXISTS "tenant_update" ON appointments;
DROP POLICY IF EXISTS "tenant_delete" ON appointments;
DROP POLICY IF EXISTS "public_select" ON appointments;
DROP POLICY IF EXISTS "public_insert" ON appointments;

DROP POLICY IF EXISTS "tenant_select" ON blocks;
DROP POLICY IF EXISTS "tenant_insert" ON blocks;
DROP POLICY IF EXISTS "tenant_update" ON blocks;
DROP POLICY IF EXISTS "tenant_delete" ON blocks;
DROP POLICY IF EXISTS "public_select" ON blocks;

DROP POLICY IF EXISTS "tenant_select" ON waitlist;
DROP POLICY IF EXISTS "tenant_insert" ON waitlist;
DROP POLICY IF EXISTS "tenant_update" ON waitlist;
DROP POLICY IF EXISTS "tenant_delete" ON waitlist;

-- Helper: claims
-- tenant_id claim: requerido para acceso público (selección/insert de reservas).
-- super_admin claim: "true" permite operar sobre todos los tenants (crear, leer, actualizar, borrar).
-- SELECT current_setting('request.jwt.claim.tenant_id', true);
-- SELECT current_setting('request.jwt.claim.super_admin', true);

-- ============================================================================
-- TENANTS: admin read/update own, public read current tenant_id claim
-- ============================================================================
CREATE POLICY "tenant_select" ON tenants FOR SELECT TO authenticated
  USING (
    admin_user_id = auth.uid()
    OR current_setting('request.jwt.claim.super_admin', true) = 'true'
  );
CREATE POLICY "tenant_update" ON tenants FOR UPDATE TO authenticated
  USING (
    admin_user_id = auth.uid()
    OR current_setting('request.jwt.claim.super_admin', true) = 'true'
  )
  WITH CHECK (
    admin_user_id = auth.uid()
    OR current_setting('request.jwt.claim.super_admin', true) = 'true'
  );
CREATE POLICY "tenant_insert" ON tenants FOR INSERT TO authenticated
  WITH CHECK (current_setting('request.jwt.claim.super_admin', true) = 'true');
CREATE POLICY "tenant_delete" ON tenants FOR DELETE TO authenticated
  USING (current_setting('request.jwt.claim.super_admin', true) = 'true');
CREATE POLICY "public_select" ON tenants FOR SELECT TO anon
  USING (
    id = current_setting('request.jwt.claim.tenant_id', true)
    AND current_setting('request.jwt.claim.tenant_id', true) IS NOT NULL
  );

-- ============================================================================
-- PROFESSIONALS: admin CRUD, public read (scoped)
-- ============================================================================
CREATE POLICY "tenant_select" ON professionals FOR SELECT TO authenticated
  USING (
    tenant_id IN (SELECT id FROM tenants WHERE admin_user_id = auth.uid())
    OR current_setting('request.jwt.claim.super_admin', true) = 'true'
  );
CREATE POLICY "tenant_insert" ON professionals FOR INSERT TO authenticated
  WITH CHECK (
    tenant_id IN (SELECT id FROM tenants WHERE admin_user_id = auth.uid())
    OR current_setting('request.jwt.claim.super_admin', true) = 'true'
  );
CREATE POLICY "tenant_update" ON professionals FOR UPDATE TO authenticated
  USING (
    tenant_id IN (SELECT id FROM tenants WHERE admin_user_id = auth.uid())
    OR current_setting('request.jwt.claim.super_admin', true) = 'true'
  )
  WITH CHECK (
    tenant_id IN (SELECT id FROM tenants WHERE admin_user_id = auth.uid())
    OR current_setting('request.jwt.claim.super_admin', true) = 'true'
  );
CREATE POLICY "tenant_delete" ON professionals FOR DELETE TO authenticated
  USING (
    tenant_id IN (SELECT id FROM tenants WHERE admin_user_id = auth.uid())
    OR current_setting('request.jwt.claim.super_admin', true) = 'true'
  );
CREATE POLICY "public_select" ON professionals FOR SELECT TO anon
  USING (
    tenant_id = current_setting('request.jwt.claim.tenant_id', true)
    AND current_setting('request.jwt.claim.tenant_id', true) IS NOT NULL
  );

-- ============================================================================
-- SERVICES: admin CRUD, public read (scoped)
-- ============================================================================
CREATE POLICY "tenant_select" ON services FOR SELECT TO authenticated
  USING (
    tenant_id IN (SELECT id FROM tenants WHERE admin_user_id = auth.uid())
    OR current_setting('request.jwt.claim.super_admin', true) = 'true'
  );
CREATE POLICY "tenant_insert" ON services FOR INSERT TO authenticated
  WITH CHECK (
    tenant_id IN (SELECT id FROM tenants WHERE admin_user_id = auth.uid())
    OR current_setting('request.jwt.claim.super_admin', true) = 'true'
  );
CREATE POLICY "tenant_update" ON services FOR UPDATE TO authenticated
  USING (
    tenant_id IN (SELECT id FROM tenants WHERE admin_user_id = auth.uid())
    OR current_setting('request.jwt.claim.super_admin', true) = 'true'
  )
  WITH CHECK (
    tenant_id IN (SELECT id FROM tenants WHERE admin_user_id = auth.uid())
    OR current_setting('request.jwt.claim.super_admin', true) = 'true'
  );
CREATE POLICY "tenant_delete" ON services FOR DELETE TO authenticated
  USING (
    tenant_id IN (SELECT id FROM tenants WHERE admin_user_id = auth.uid())
    OR current_setting('request.jwt.claim.super_admin', true) = 'true'
  );
CREATE POLICY "public_select" ON services FOR SELECT TO anon
  USING (
    tenant_id = current_setting('request.jwt.claim.tenant_id', true)
    AND current_setting('request.jwt.claim.tenant_id', true) IS NOT NULL
  );

-- ============================================================================
-- PROFESSIONAL_SERVICES: admin CRUD, public read (scoped)
-- ============================================================================
CREATE POLICY "tenant_select" ON professional_services FOR SELECT TO authenticated
  USING (
    tenant_id IN (SELECT id FROM tenants WHERE admin_user_id = auth.uid())
    OR current_setting('request.jwt.claim.super_admin', true) = 'true'
  );
CREATE POLICY "tenant_insert" ON professional_services FOR INSERT TO authenticated
  WITH CHECK (
    tenant_id IN (SELECT id FROM tenants WHERE admin_user_id = auth.uid())
    OR current_setting('request.jwt.claim.super_admin', true) = 'true'
  );
CREATE POLICY "tenant_update" ON professional_services FOR UPDATE TO authenticated
  USING (
    tenant_id IN (SELECT id FROM tenants WHERE admin_user_id = auth.uid())
    OR current_setting('request.jwt.claim.super_admin', true) = 'true'
  )
  WITH CHECK (
    tenant_id IN (SELECT id FROM tenants WHERE admin_user_id = auth.uid())
    OR current_setting('request.jwt.claim.super_admin', true) = 'true'
  );
CREATE POLICY "tenant_delete" ON professional_services FOR DELETE TO authenticated
  USING (
    tenant_id IN (SELECT id FROM tenants WHERE admin_user_id = auth.uid())
    OR current_setting('request.jwt.claim.super_admin', true) = 'true'
  );
CREATE POLICY "public_select" ON professional_services FOR SELECT TO anon
  USING (
    tenant_id = current_setting('request.jwt.claim.tenant_id', true)
    AND current_setting('request.jwt.claim.tenant_id', true) IS NOT NULL
  );

-- ============================================================================
-- PORTFOLIO_IMAGES: admin CRUD, public read (scoped)
-- ============================================================================
CREATE POLICY "tenant_select" ON portfolio_images FOR SELECT TO authenticated
  USING (
    tenant_id IN (SELECT id FROM tenants WHERE admin_user_id = auth.uid())
    OR current_setting('request.jwt.claim.super_admin', true) = 'true'
  );
CREATE POLICY "tenant_insert" ON portfolio_images FOR INSERT TO authenticated
  WITH CHECK (
    tenant_id IN (SELECT id FROM tenants WHERE admin_user_id = auth.uid())
    OR current_setting('request.jwt.claim.super_admin', true) = 'true'
  );
CREATE POLICY "tenant_update" ON portfolio_images FOR UPDATE TO authenticated
  USING (
    tenant_id IN (SELECT id FROM tenants WHERE admin_user_id = auth.uid())
    OR current_setting('request.jwt.claim.super_admin', true) = 'true'
  )
  WITH CHECK (
    tenant_id IN (SELECT id FROM tenants WHERE admin_user_id = auth.uid())
    OR current_setting('request.jwt.claim.super_admin', true) = 'true'
  );
CREATE POLICY "tenant_delete" ON portfolio_images FOR DELETE TO authenticated
  USING (
    tenant_id IN (SELECT id FROM tenants WHERE admin_user_id = auth.uid())
    OR current_setting('request.jwt.claim.super_admin', true) = 'true'
  );
CREATE POLICY "public_select" ON portfolio_images FOR SELECT TO anon
  USING (
    tenant_id = current_setting('request.jwt.claim.tenant_id', true)
    AND current_setting('request.jwt.claim.tenant_id', true) IS NOT NULL
  );

-- ============================================================================
-- OPERATING_HOURS: admin CRUD, public read (scoped)
-- ============================================================================
CREATE POLICY "tenant_select" ON operating_hours FOR SELECT TO authenticated
  USING (
    tenant_id IN (SELECT id FROM tenants WHERE admin_user_id = auth.uid())
    OR current_setting('request.jwt.claim.super_admin', true) = 'true'
  );
CREATE POLICY "tenant_insert" ON operating_hours FOR INSERT TO authenticated
  WITH CHECK (
    tenant_id IN (SELECT id FROM tenants WHERE admin_user_id = auth.uid())
    OR current_setting('request.jwt.claim.super_admin', true) = 'true'
  );
CREATE POLICY "tenant_update" ON operating_hours FOR UPDATE TO authenticated
  USING (
    tenant_id IN (SELECT id FROM tenants WHERE admin_user_id = auth.uid())
    OR current_setting('request.jwt.claim.super_admin', true) = 'true'
  )
  WITH CHECK (
    tenant_id IN (SELECT id FROM tenants WHERE admin_user_id = auth.uid())
    OR current_setting('request.jwt.claim.super_admin', true) = 'true'
  );
CREATE POLICY "tenant_delete" ON operating_hours FOR DELETE TO authenticated
  USING (
    tenant_id IN (SELECT id FROM tenants WHERE admin_user_id = auth.uid())
    OR current_setting('request.jwt.claim.super_admin', true) = 'true'
  );
CREATE POLICY "public_select" ON operating_hours FOR SELECT TO anon
  USING (
    tenant_id = current_setting('request.jwt.claim.tenant_id', true)
    AND current_setting('request.jwt.claim.tenant_id', true) IS NOT NULL
  );

-- ============================================================================
-- APPOINTMENTS: admin full CRUD, public read + insert (scoped)
-- ============================================================================
CREATE POLICY "tenant_select" ON appointments FOR SELECT TO authenticated
  USING (
    tenant_id IN (SELECT id FROM tenants WHERE admin_user_id = auth.uid())
    OR current_setting('request.jwt.claim.super_admin', true) = 'true'
  );
CREATE POLICY "tenant_insert" ON appointments FOR INSERT TO authenticated
  WITH CHECK (
    tenant_id IN (SELECT id FROM tenants WHERE admin_user_id = auth.uid())
    OR current_setting('request.jwt.claim.super_admin', true) = 'true'
  );
CREATE POLICY "tenant_update" ON appointments FOR UPDATE TO authenticated
  USING (
    tenant_id IN (SELECT id FROM tenants WHERE admin_user_id = auth.uid())
    OR current_setting('request.jwt.claim.super_admin', true) = 'true'
  )
  WITH CHECK (
    tenant_id IN (SELECT id FROM tenants WHERE admin_user_id = auth.uid())
    OR current_setting('request.jwt.claim.super_admin', true) = 'true'
  );
CREATE POLICY "tenant_delete" ON appointments FOR DELETE TO authenticated
  USING (
    tenant_id IN (SELECT id FROM tenants WHERE admin_user_id = auth.uid())
    OR current_setting('request.jwt.claim.super_admin', true) = 'true'
  );
CREATE POLICY "public_select" ON appointments FOR SELECT TO anon
  USING (
    tenant_id = current_setting('request.jwt.claim.tenant_id', true)
    AND current_setting('request.jwt.claim.tenant_id', true) IS NOT NULL
  );
CREATE POLICY "public_insert" ON appointments FOR INSERT TO anon
  WITH CHECK (
    tenant_id = current_setting('request.jwt.claim.tenant_id', true)
    AND current_setting('request.jwt.claim.tenant_id', true) IS NOT NULL
  );

-- ============================================================================
-- BLOCKS: admin CRUD, public read (scoped)
-- ============================================================================
CREATE POLICY "tenant_select" ON blocks FOR SELECT TO authenticated
  USING (
    tenant_id IN (SELECT id FROM tenants WHERE admin_user_id = auth.uid())
    OR current_setting('request.jwt.claim.super_admin', true) = 'true'
  );
CREATE POLICY "tenant_insert" ON blocks FOR INSERT TO authenticated
  WITH CHECK (
    tenant_id IN (SELECT id FROM tenants WHERE admin_user_id = auth.uid())
    OR current_setting('request.jwt.claim.super_admin', true) = 'true'
  );
CREATE POLICY "tenant_update" ON blocks FOR UPDATE TO authenticated
  USING (
    tenant_id IN (SELECT id FROM tenants WHERE admin_user_id = auth.uid())
    OR current_setting('request.jwt.claim.super_admin', true) = 'true'
  )
  WITH CHECK (
    tenant_id IN (SELECT id FROM tenants WHERE admin_user_id = auth.uid())
    OR current_setting('request.jwt.claim.super_admin', true) = 'true'
  );
CREATE POLICY "tenant_delete" ON blocks FOR DELETE TO authenticated
  USING (
    tenant_id IN (SELECT id FROM tenants WHERE admin_user_id = auth.uid())
    OR current_setting('request.jwt.claim.super_admin', true) = 'true'
  );
CREATE POLICY "public_select" ON blocks FOR SELECT TO anon
  USING (
    tenant_id = current_setting('request.jwt.claim.tenant_id', true)
    AND current_setting('request.jwt.claim.tenant_id', true) IS NOT NULL
  );

-- ============================================================================
-- WAITLIST: admin full CRUD (no acceso público)
-- ============================================================================
CREATE POLICY "tenant_select" ON waitlist FOR SELECT TO authenticated
  USING (
    tenant_id IN (SELECT id FROM tenants WHERE admin_user_id = auth.uid())
    OR current_setting('request.jwt.claim.super_admin', true) = 'true'
  );
CREATE POLICY "tenant_insert" ON waitlist FOR INSERT TO authenticated
  WITH CHECK (
    tenant_id IN (SELECT id FROM tenants WHERE admin_user_id = auth.uid())
    OR current_setting('request.jwt.claim.super_admin', true) = 'true'
  );
CREATE POLICY "tenant_update" ON waitlist FOR UPDATE TO authenticated
  USING (
    tenant_id IN (SELECT id FROM tenants WHERE admin_user_id = auth.uid())
    OR current_setting('request.jwt.claim.super_admin', true) = 'true'
  )
  WITH CHECK (
    tenant_id IN (SELECT id FROM tenants WHERE admin_user_id = auth.uid())
    OR current_setting('request.jwt.claim.super_admin', true) = 'true'
  );
CREATE POLICY "tenant_delete" ON waitlist FOR DELETE TO authenticated
  USING (
    tenant_id IN (SELECT id FROM tenants WHERE admin_user_id = auth.uid())
    OR current_setting('request.jwt.claim.super_admin', true) = 'true'
  );
