-- Lajme: Albanian News Aggregator - Initial Schema

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS pg_cron WITH SCHEMA pg_catalog;
CREATE EXTENSION IF NOT EXISTS pg_net WITH SCHEMA extensions;

-- Categories table
CREATE TABLE categories (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    slug TEXT NOT NULL UNIQUE,
    icon TEXT,
    sort_order INTEGER DEFAULT 0
);

-- News sources table
CREATE TABLE sources (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    url TEXT NOT NULL,
    rss_url TEXT NOT NULL,
    logo_url TEXT,
    country TEXT NOT NULL CHECK (country IN ('XK', 'AL', 'MK', 'RS', 'CH')),
    is_active BOOLEAN DEFAULT true,
    last_fetched_at TIMESTAMPTZ,
    last_fetch_status TEXT,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Articles table
CREATE TABLE articles (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    source_id INTEGER NOT NULL REFERENCES sources(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    article_url TEXT NOT NULL UNIQUE,
    category_slug TEXT REFERENCES categories(slug) ON DELETE SET NULL,
    published_at TIMESTAMPTZ NOT NULL,
    is_breaking BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Indexes for fast queries
CREATE INDEX idx_articles_published_at ON articles(published_at DESC);
CREATE INDEX idx_articles_category_published ON articles(category_slug, published_at DESC);
CREATE INDEX idx_articles_source_published ON articles(source_id, published_at DESC);
CREATE INDEX idx_articles_created_at ON articles(created_at DESC);

-- Full-text search index (simple config — no Albanian stemmer available)
ALTER TABLE articles ADD COLUMN fts tsvector
    GENERATED ALWAYS AS (to_tsvector('simple', coalesce(title, ''))) STORED;
CREATE INDEX idx_articles_fts ON articles USING gin(fts);

-- Trigram index for fuzzy search
CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE INDEX idx_articles_title_trgm ON articles USING gin(title gin_trgm_ops);

-- Enable Row Level Security
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE sources ENABLE ROW LEVEL SECURITY;
ALTER TABLE articles ENABLE ROW LEVEL SECURITY;

-- Public read access policies
CREATE POLICY "Public read categories" ON categories FOR SELECT USING (true);
CREATE POLICY "Public read sources" ON sources FOR SELECT USING (is_active = true);
CREATE POLICY "Public read articles" ON articles FOR SELECT USING (true);

-- Cron job: poll RSS feeds every 5 minutes
-- NOTE: Before running this migration, you must:
-- 1. Enable pg_cron and pg_net extensions in Supabase Dashboard > Database > Extensions
-- 2. Replace YOUR_PROJECT_REF and YOUR_SERVICE_ROLE_KEY below
SELECT cron.schedule(
    'poll-rss-feeds',
    '*/5 * * * *',
    $$SELECT net.http_post(
        url := 'https://YOUR_PROJECT_REF.supabase.co/functions/v1/poll-rss',
        headers := '{"Authorization": "Bearer YOUR_SERVICE_ROLE_KEY", "Content-Type": "application/json"}'::jsonb,
        body := '{}'::jsonb
    );$$
);

-- Cron job: clean up old articles daily at 3 AM
SELECT cron.schedule(
    'cleanup-old-articles',
    '0 3 * * *',
    $$DELETE FROM articles WHERE published_at < now() - interval '7 days';$$
);
