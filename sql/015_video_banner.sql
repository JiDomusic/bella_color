-- ============================================================
-- 015: Video Banner para Promociones
-- Agrega soporte de video MP4 en el banner del salón.
-- Seguro para salones existentes: columnas nuevas con DEFAULT.
-- banner_tipo default 'texto' = comportamiento actual sin cambios.
-- ============================================================

-- URL del video subido a Supabase Storage
ALTER TABLE tenants ADD COLUMN IF NOT EXISTS banner_video_url TEXT DEFAULT '';

-- Tipo de banner: 'texto' (default actual), 'video', 'ambos'
ALTER TABLE tenants ADD COLUMN IF NOT EXISTS banner_tipo TEXT DEFAULT 'texto';

-- No se necesitan nuevas RLS: son columnas en la tabla tenants
-- que ya tiene policies de tenant_select/update + public_select.
