-- Expand country codes to cover full Albanian-language media landscape:
-- XK (Kosovo), AL (Albania), MK (North Macedonia), RS (Serbia/Preshevo), ME (Montenegro), CH (Diaspora/Switzerland)

ALTER TABLE sources DROP CONSTRAINT IF EXISTS sources_country_check;
ALTER TABLE sources ADD CONSTRAINT sources_country_check
    CHECK (country IN ('XK', 'AL', 'MK', 'RS', 'ME', 'CH'));

-- ── Kosovo (XK) ──────────────────────────────────────────────────────────────
INSERT INTO sources (name, url, rss_url, logo_url, country) VALUES
    ('Lajmi.net',  'https://lajmi.net',         'https://lajmi.net/feed/',         NULL, 'XK')
ON CONFLICT (url) DO NOTHING;

-- ── Albania (AL) ─────────────────────────────────────────────────────────────
INSERT INTO sources (name, url, rss_url, logo_url, country) VALUES
    ('Albeu',      'https://albeu.com',          'https://albeu.com/feed/',          NULL, 'AL'),
    ('ABC News',   'https://abcnews.al',          'https://abcnews.al/feed/',         NULL, 'AL'),
    ('Shekulli',   'https://shekulli.com.al',     'https://shekulli.com.al/feed/',    NULL, 'AL'),
    ('Standard',   'https://www.standard.al',     'https://www.standard.al/feed/',    NULL, 'AL'),
    ('RTSH',       'https://rtsh.al',             'https://rtsh.al/feed/',            NULL, 'AL')
ON CONFLICT (url) DO NOTHING;

-- ── North Macedonia / MK ─────────────────────────────────────────────────────
-- Albanian-language outlets only (TV21.mk excluded — publishes in Macedonian/Cyrillic)
INSERT INTO sources (name, url, rss_url, logo_url, country) VALUES
    ('Portalb',    'https://portalb.mk',          'https://portalb.mk/feed/',         NULL, 'MK'),
    ('Tetova Sot', 'https://tetovasot.com',       'https://tetovasot.com/feed/',      NULL, 'MK')
ON CONFLICT (url) DO NOTHING;

-- ── Preshevo Valley / Serbia (RS) ─────────────────────────────────────────────
-- Bujanoci.net: Albanian-language outlet from Bujanovac, covering Preshevo valley
INSERT INTO sources (name, url, rss_url, logo_url, country) VALUES
    ('Bujanoci',   'https://bujanoci.net',        'https://bujanoci.net/feed/',       NULL, 'RS')
ON CONFLICT (url) DO NOTHING;

-- ── Diaspora (CH) ─────────────────────────────────────────────────────────────
-- Albinfo.ch: Swiss-based Albanian diaspora news, covers community across Europe
INSERT INTO sources (name, url, rss_url, logo_url, country) VALUES
    ('Albinfo',    'https://albinfo.ch',          'https://albinfo.ch/feed/',         NULL, 'CH')
ON CONFLICT (url) DO NOTHING;

-- Sources NOT added and why:
-- Kosova Sot    — domain for sale (dead)
-- Syri.net      — RSS feed returns empty (no items)
-- Lapsi.al      — Cloudflare bot protection blocks feed
-- Gazeta Shqip  — Next.js SPA, no RSS endpoint
-- OraNews.tv    — 403 on feed
-- Koha.mk       — 403 on feed
-- Alsat-M       — redirect fails
-- Presheva Jonë — connection refused
-- TV21.mk       — Macedonian/Cyrillic language
-- Bujanoci.net (www) — works via non-www URL
-- Portal Ulqini — connection refused (Montenegro)
