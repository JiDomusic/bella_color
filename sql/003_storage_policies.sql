-- ============================================================================
-- 003_storage_policies.sql
-- Storage policies for salon-images bucket (privado y scope por tenant)
-- Ejecutar en Supabase SQL Editor
-- ============================================================================

-- Asegurar bucket privado (solo una vez; si ya existe, solo actualizar "public")
-- INSERT INTO storage.buckets (id, name, public) VALUES ('salon-images', 'salon-images', false);
UPDATE storage.buckets SET public = false WHERE id = 'salon-images';

-- Limpiar policies anteriores
DROP POLICY IF EXISTS "authenticated_upload" ON storage.objects;
DROP POLICY IF EXISTS "authenticated_update" ON storage.objects;
DROP POLICY IF EXISTS "authenticated_delete" ON storage.objects;
DROP POLICY IF EXISTS "public_read" ON storage.objects;
DROP POLICY IF EXISTS "authenticated_read" ON storage.objects;
DROP POLICY IF EXISTS "tenant_insert" ON storage.objects;
DROP POLICY IF EXISTS "tenant_select" ON storage.objects;
DROP POLICY IF EXISTS "tenant_update" ON storage.objects;
DROP POLICY IF EXISTS "tenant_delete" ON storage.objects;

-- Notas:
-- - Requiere que el JWT tenga el claim "tenant_id".
-- - Las rutas de objetos deben llevar prefijo "<tenant_id>/archivo.ext".
-- - Lectura pública queda deshabilitada; usar signed URLs si hace falta exponer públicamente.

CREATE POLICY "tenant_insert" ON storage.objects
  FOR INSERT TO authenticated
  WITH CHECK (
    bucket_id = 'salon-images'
    AND current_setting('request.jwt.claim.tenant_id', true) IS NOT NULL
    AND (storage.foldername(name))[1] = current_setting('request.jwt.claim.tenant_id', true)
  );

CREATE POLICY "tenant_select" ON storage.objects
  FOR SELECT TO authenticated
  USING (
    bucket_id = 'salon-images'
    AND current_setting('request.jwt.claim.tenant_id', true) IS NOT NULL
    AND (storage.foldername(name))[1] = current_setting('request.jwt.claim.tenant_id', true)
  );

CREATE POLICY "tenant_update" ON storage.objects
  FOR UPDATE TO authenticated
  USING (
    bucket_id = 'salon-images'
    AND current_setting('request.jwt.claim.tenant_id', true) IS NOT NULL
    AND (storage.foldername(name))[1] = current_setting('request.jwt.claim.tenant_id', true)
  )
  WITH CHECK (
    bucket_id = 'salon-images'
    AND current_setting('request.jwt.claim.tenant_id', true) IS NOT NULL
    AND (storage.foldername(name))[1] = current_setting('request.jwt.claim.tenant_id', true)
  );

CREATE POLICY "tenant_delete" ON storage.objects
  FOR DELETE TO authenticated
  USING (
    bucket_id = 'salon-images'
    AND current_setting('request.jwt.claim.tenant_id', true) IS NOT NULL
    AND (storage.foldername(name))[1] = current_setting('request.jwt.claim.tenant_id', true)
  );
