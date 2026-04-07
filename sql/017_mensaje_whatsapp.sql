-- Agregar campo para mensaje de WhatsApp personalizable
ALTER TABLE tenants ADD COLUMN IF NOT EXISTS mensaje_whatsapp_confirmacion TEXT DEFAULT '';
