-- 019: Comprobante de seña obligatorio
-- Guarda la URL del comprobante de transferencia subido por la clienta.
-- Solo se usa cuando el servicio requiere seña.

ALTER TABLE appointments ADD COLUMN IF NOT EXISTS comprobante_url TEXT;
