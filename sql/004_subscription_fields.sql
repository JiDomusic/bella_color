-- ============================================================================
-- 004_subscription_fields.sql
-- Add subscription/blocking fields to tenants
-- Run in Supabase SQL Editor
-- ============================================================================

ALTER TABLE tenants ADD COLUMN IF NOT EXISTS is_blocked BOOLEAN DEFAULT false;
ALTER TABLE tenants ADD COLUMN IF NOT EXISTS blocked_at TIMESTAMPTZ;
ALTER TABLE tenants ADD COLUMN IF NOT EXISTS block_reason TEXT DEFAULT '';
ALTER TABLE tenants ADD COLUMN IF NOT EXISTS trial_days INT DEFAULT 15;
