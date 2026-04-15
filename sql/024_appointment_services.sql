-- 024: Tabla para soportar múltiples servicios por turno
-- RETROCOMPATIBLE: los turnos existentes siguen funcionando con servicio_id/servicio_nombre
-- La tabla appointment_services es OPCIONAL — si no tiene rows, se lee el servicio de appointments

CREATE TABLE IF NOT EXISTS appointment_services (
  id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
  appointment_id TEXT NOT NULL REFERENCES appointments(id) ON DELETE CASCADE,
  service_id TEXT NOT NULL REFERENCES services(id) ON DELETE CASCADE,
  servicio_nombre TEXT NOT NULL,
  duracion_minutos INT NOT NULL DEFAULT 60,
  precio NUMERIC(10,2),
  orden INT NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Índice para buscar servicios por turno
CREATE INDEX IF NOT EXISTS idx_appointment_services_appointment
  ON appointment_services(appointment_id);

-- RLS: misma política que appointments (via tenant del appointment)
ALTER TABLE appointment_services ENABLE ROW LEVEL SECURITY;

-- Política: acceso público para insertar (el booking es anónimo)
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'anon_insert_appointment_services') THEN
    CREATE POLICY "anon_insert_appointment_services"
      ON appointment_services FOR INSERT
      TO anon, authenticated
      WITH CHECK (true);
  END IF;
END $$;

-- Política: lectura pública (para confirmación)
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'anon_select_appointment_services') THEN
    CREATE POLICY "anon_select_appointment_services"
      ON appointment_services FOR SELECT
      TO anon, authenticated
      USING (true);
  END IF;
END $$;

-- Política: delete cascade se maneja por FK, pero admin puede necesitar leer
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'anon_delete_appointment_services') THEN
    CREATE POLICY "anon_delete_appointment_services"
      ON appointment_services FOR DELETE
      TO anon, authenticated
      USING (true);
  END IF;
END $$;
