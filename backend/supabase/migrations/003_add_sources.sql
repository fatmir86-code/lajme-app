-- Add Zëri and Bota Sot as news sources
-- Kosova Sot was excluded — domain is for sale (dead site as of 2026-04-13)

INSERT INTO sources (name, url, rss_url, logo_url, country) VALUES
    ('Zëri', 'https://zeri.info', 'https://zeri.info/rss', NULL, 'XK'),
    ('Bota Sot', 'https://www.botasot.info', 'https://www.botasot.info/rss/lajme', NULL, 'XK');

-- Note: Bota Sot uses /rss/lajme (main news feed) rather than /feed/ to avoid
-- their "Kuriozitete" section, which has no dedicated RSS exclusion otherwise.
