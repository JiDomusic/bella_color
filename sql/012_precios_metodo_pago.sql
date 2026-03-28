-- ============================================================
-- 012: Precios por Método de Pago (Efectivo / Tarjeta)
-- Agrega precios diferenciados y descuentos opcionales.
-- Seguro para salones existentes: usa IF NOT EXISTS y DEFAULT.
-- El campo 'precio' original NO se elimina (sirve de fallback).
-- ============================================================

-- Precio efectivo y tarjeta en servicios
ALTER TABLE services ADD COLUMN IF NOT EXISTS precio_efectivo DECIMAL(10,2);
ALTER TABLE services ADD COLUMN IF NOT EXISTS precio_tarjeta DECIMAL(10,2);
ALTER TABLE services ADD COLUMN IF NOT EXISTS descuento_efectivo_pct INTEGER DEFAULT 0;
ALTER TABLE services ADD COLUMN IF NOT EXISTS descuento_tarjeta_pct INTEGER DEFAULT 0;

-- Migrar precio existente a precio_efectivo para salones que ya tienen servicios
-- Solo donde precio_efectivo aun no fue seteado
UPDATE services
  SET precio_efectivo = precio
  WHERE precio IS NOT NULL
    AND precio_efectivo IS NULL;

-- Precios por método de pago en professional_services (override por profesional)
ALTER TABLE professional_services ADD COLUMN IF NOT EXISTS precio_efectivo DECIMAL(10,2);
ALTER TABLE professional_services ADD COLUMN IF NOT EXISTS precio_tarjeta DECIMAL(10,2);

-- Porcentaje que se lleva el profesional por cada servicio (0-100)
-- Permite al dueño del salón registrar qué porcentaje corresponde a cada profesional.
-- Default 0 = no configurado aún (no afecta salones existentes).
ALTER TABLE professional_services ADD COLUMN IF NOT EXISTS porcentaje_profesional INTEGER DEFAULT 0;

-- No se necesitan nuevas RLS: son columnas en tablas existentes
-- que ya tienen policies de tenant_select/insert/update/delete + public_select.
