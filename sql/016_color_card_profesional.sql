-- Agregar color configurable para las tarjetas de profesionales
ALTER TABLE tenants ADD COLUMN IF NOT EXISTS color_card_profesional TEXT DEFAULT '';
