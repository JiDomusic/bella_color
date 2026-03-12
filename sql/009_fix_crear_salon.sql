-- ============================================================================
-- 009_fix_crear_salon.sql
-- Fix para crear salones sin depender de FK ni schema cache de PostgREST
--
-- EJECUTAR EN: Supabase SQL Editor del proyecto BELLA COLOR
-- ============================================================================

-- 1. Quitar TODOS los FK constraints en admin_user_id
DO $$
DECLARE
  r RECORD;
BEGIN
  FOR r IN (
    SELECT conname FROM pg_constraint
    WHERE conrelid = 'tenants'::regclass
    AND contype = 'f'
    AND conname LIKE '%admin_user_id%'
  ) LOOP
    EXECUTE 'ALTER TABLE tenants DROP CONSTRAINT ' || r.conname;
  END LOOP;
END $$;

-- 2. Asegurar que admin_user_id permite NULL
ALTER TABLE tenants ALTER COLUMN admin_user_id DROP NOT NULL;

-- 3. Agregar columna onboarding_completed si no existe
ALTER TABLE tenants ADD COLUMN IF NOT EXISTS onboarding_completed BOOLEAN DEFAULT false;

-- 4. Permitir que anon pueda insertar tenants (para crear desde super admin sin auth)
DROP POLICY IF EXISTS "anon_insert_tenants" ON tenants;
CREATE POLICY "anon_insert_tenants" ON tenants
  FOR INSERT TO anon
  WITH CHECK (true);

-- 5. Permitir que anon pueda actualizar tenants recien creados (para vincular admin)
DROP POLICY IF EXISTS "anon_update_tenants" ON tenants;
CREATE POLICY "anon_update_tenants" ON tenants
  FOR UPDATE TO anon
  USING (admin_user_id IS NULL)
  WITH CHECK (true);

-- 6. Funcion para vincular admin al tenant (SECURITY DEFINER)
CREATE OR REPLACE FUNCTION link_admin_to_tenant(
  p_tenant_id TEXT,
  p_user_id UUID
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  UPDATE tenants
  SET admin_user_id = p_user_id
  WHERE id = p_tenant_id;

  -- Auto-confirmar email del usuario
  UPDATE auth.users
  SET email_confirmed_at = NOW()
  WHERE id = p_user_id AND email_confirmed_at IS NULL;
END;
$$;

GRANT EXECUTE ON FUNCTION link_admin_to_tenant TO anon;
GRANT EXECUTE ON FUNCTION link_admin_to_tenant TO authenticated;

-- 7. Recargar schema
NOTIFY pgrst, 'reload schema';
