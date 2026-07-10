-- 006: Document schema drift (2026-07-10 audit)
--
-- The columns and function below are USED by the edge functions and the iOS
-- app, and EXIST in production, but were created ad hoc (never via a tracked
-- migration). This migration records the known shape so a fresh database can
-- run the code. It is written to be safe to apply against production too
-- (IF NOT EXISTS / OR REPLACE everywhere).
--
-- ⚠️ STILL UNTRACKED: whatever populates articles.related_sources (the
-- "Raportuar edhe nga" feature). Nothing in this repo writes that column,
-- yet it has data in production — so a trigger or pg_cron SQL job exists
-- in the live database only. Run `supabase login && supabase db pull`
-- to capture the real definition, then replace this file's guesswork.

-- Columns used by functions/api (SELECT) and functions/poll-rss (INSERT/UPDATE)
ALTER TABLE articles ADD COLUMN IF NOT EXISTS image_url TEXT;
ALTER TABLE articles ADD COLUMN IF NOT EXISTS is_top BOOLEAN DEFAULT false;
ALTER TABLE articles ADD COLUMN IF NOT EXISTS related_sources JSONB;

-- Used by the "Aktuale" curated feed (api/index.ts filters on is_top = true
-- when no country is selected)
CREATE INDEX IF NOT EXISTS idx_articles_is_top
    ON articles(is_top, published_at DESC) WHERE is_top = true;

-- Called by poll-rss after each poll: "Mark top 5 most recent articles per
-- source as is_top (for 'Aktuale' curated feed)". Reconstructed from that
-- call site — verify against production with `supabase db pull`.
CREATE OR REPLACE FUNCTION mark_top_articles() RETURNS void
LANGUAGE sql AS $$
    UPDATE articles SET is_top = false WHERE is_top = true;
    UPDATE articles SET is_top = true WHERE id IN (
        SELECT id FROM (
            SELECT id, ROW_NUMBER() OVER (
                PARTITION BY source_id ORDER BY published_at DESC
            ) AS rn
            FROM articles
            WHERE published_at > now() - interval '48 hours'
        ) ranked
        WHERE rn <= 5
    );
$$;
