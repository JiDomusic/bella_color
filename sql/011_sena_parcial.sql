-- ============================================================
-- 011: Sistema de Seña (Pago Parcial/Total)
-- ============================================================
-- Configuración global de seña en el salón
ALTER TABLE tenants ADD COLUMN IF NOT EXISTS sena_habilitada BOOLEAN DEFAULT false;
ALTER TABLE tenants ADD COLUMN IF NOT EXISTS sena_porcentaje INTEGER DEFAULT 0;
ALTER TABLE tenants ADD COLUMN IF NOT EXISTS sena_cbu TEXT DEFAULT '';
ALTER TABLE tenants ADD COLUMN IF NOT EXISTS sena_alias TEXT DEFAULT '';
ALTER TABLE tenants ADD COLUMN IF NOT EXISTS sena_titular TEXT DEFAULT '';

-- Toggle por servicio: el admin elige cuáles piden seña
ALTER TABLE services ADD COLUMN IF NOT EXISTS requiere_sena BOOLEAN DEFAULT false;
