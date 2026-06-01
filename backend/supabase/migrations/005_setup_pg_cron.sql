-- Migration 005: Set up pg_cron for automatic RSS polling
-- This migration was applied manually via Supabase Management API on 2026-04-15

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS pg_cron WITH SCHEMA pg_catalog;
CREATE EXTENSION IF NOT EXISTS pg_net WITH SCHEMA extensions;

-- Poll RSS feeds every 10 minutes using pg_net to call the Edge Function
-- NOTE: The service_role key is stored directly in the cron job command.
-- This is secure because pg_cron runs server-side within Supabase infrastructure.
-- The key never leaves the database.
SELECT cron.schedule(
    'poll-rss-feeds',
    '*/10 * * * *',
    $$SELECT net.http_post(
        url := 'https://cgjqcjksdlzoheoyhmwg.supabase.co/functions/v1/poll-rss',
        headers := '{"Authorization": "Bearer SERVICE_ROLE_KEY_PLACEHOLDER", "Content-Type": "application/json"}'::jsonb,
        body := '{}'::jsonb
    );$$
);

-- Clean up old articles daily at 3 AM UTC
SELECT cron.schedule(
    'cleanup-old-articles',
    '0 3 * * *',
    $$DELETE FROM articles WHERE published_at < now() - interval '7 days';$$
);
