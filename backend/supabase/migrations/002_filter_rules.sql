-- Filter rules table for dynamic content filtering
-- Allows adding new block rules without redeploying the Edge Function.
-- The poll-rss function merges these with its hardcoded base rules at runtime.

CREATE TABLE filter_rules (
    id SERIAL PRIMARY KEY,
    type TEXT NOT NULL CHECK (type IN ('url_pattern', 'title_keyword', 'rss_category')),
    pattern TEXT NOT NULL,
    description TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Allow service role to read (poll-rss uses service role)
ALTER TABLE filter_rules ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Service role full access" ON filter_rules USING (true);

-- Index for fast active-rule lookups
CREATE INDEX idx_filter_rules_active ON filter_rules(type) WHERE is_active = true;

-- Seed: additional site-specific URL patterns observed in Albanian news feeds
INSERT INTO filter_rules (type, pattern, description) VALUES
    -- Telegrafi-specific sections
    ('url_pattern', '/horoskopi-',        'Telegrafi horoscope articles (slug prefix)'),
    ('url_pattern', '/receta-',           'Telegrafi recipe articles (slug prefix)'),
    -- Balkanweb lifestyle section
    ('url_pattern', '/lifestyle',         'Balkanweb lifestyle section'),
    -- Panorama entertainment
    ('url_pattern', '/showbiz',           'Showbiz / celebrity content'),
    ('url_pattern', '/showbizz',          'Showbizz variant'),
    -- Additional title keywords found in Albanian feeds
    ('title_keyword', 'horoskopi për',    'Horoscope for [day/sign]'),
    ('title_keyword', 'shenja e dashes',  'Star sign tabloid'),
    ('title_keyword', 'receta gatimi',    'Cooking recipe in title'),
    ('title_keyword', 'si të humbni',     'Weight loss / lifestyle filler'),
    ('title_keyword', 'këshilla për',     'Generic "tips for" lifestyle content'),
    -- RSS category extras
    ('rss_category', 'showbiz',           'Showbiz RSS category'),
    ('rss_category', 'celebrit',          'Celebrity RSS category'),
    ('rss_category', 'lajme te mira',     '"Good news" feel-good filler section');
