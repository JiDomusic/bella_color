-- 021: Permitir a usuarios anónimos subir comprobantes de transferencia
-- Las clientas no están autenticadas, necesitan poder subir al bucket

-- Permitir INSERT anónimo solo en subcarpeta comprobantes/
CREATE POLICY "anon_insert_comprobantes" ON storage.objects
  FOR INSERT TO anon
  WITH CHECK (
    bucket_id = 'salon-images'
    AND (storage.foldername(name))[2] = 'comprobantes'
  );

-- Permitir lectura pública de comprobantes (para que el admin los vea)
CREATE POLICY "anon_select_comprobantes" ON storage.objects
  FOR SELECT TO anon
  USING (
    bucket_id = 'salon-images'
    AND (storage.foldername(name))[2] = 'comprobantes'
  );
