-- 020: Bloqueos por categoría
-- Permite bloquear rangos horarios para categorías específicas de servicios
-- Si categoria es NULL, el bloqueo aplica a todos los servicios (comportamiento actual)

ALTER TABLE blocks ADD COLUMN IF NOT EXISTS categoria TEXT DEFAULT NULL;

-- Índice para consultas filtradas por categoría
CREATE INDEX IF NOT EXISTS idx_blocks_categoria ON blocks(categoria);
