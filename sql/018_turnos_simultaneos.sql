-- 018: Turnos simultaneos por profesional y solapamiento de servicios
-- Permite que un profesional atienda multiples clientas en el mismo horario
-- cuando el servicio lo permite (ej: color procesando, mientras hace cejas).
-- Defaults preservan comportamiento actual (1 turno, sin solapamiento).

ALTER TABLE professionals ADD COLUMN IF NOT EXISTS max_turnos_simultaneos INT DEFAULT 1;
ALTER TABLE services ADD COLUMN IF NOT EXISTS permite_solapamiento BOOLEAN DEFAULT false;
