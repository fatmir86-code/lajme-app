-- Seed categories
INSERT INTO categories (name, slug, icon, sort_order) VALUES
    ('Aktuale', 'aktuale', 'newspaper', 0),
    ('Politikë', 'politike', 'building.columns', 1),
    ('Ekonomi', 'ekonomi', 'chart.line.uptrend.xyaxis', 2),
    ('Sport', 'sport', 'sportscourt', 3),
    ('Botë', 'bote', 'globe.europe.africa', 4),
    ('Kulturë', 'kulture', 'theatermasks', 5),
    ('Teknologji', 'teknologji', 'desktopcomputer', 6);

-- Seed sources: Kosovo
INSERT INTO sources (name, url, rss_url, logo_url, country) VALUES
    ('Telegrafi', 'https://telegrafi.com', 'https://telegrafi.com/feed/', NULL, 'XK'),
    ('Koha.net', 'https://www.koha.net', 'https://www.koha.net/feed/', NULL, 'XK'),
    ('Gazeta Express', 'https://www.gazetaexpress.com', 'https://www.gazetaexpress.com/feed/', NULL, 'XK'),
    ('Klan Kosova', 'https://klankosova.tv', 'https://klankosova.tv/feed/', NULL, 'XK'),
    ('Indeksonline', 'https://indeksonline.net', 'https://indeksonline.net/feed/', NULL, 'XK'),
    ('Insajderi', 'https://insajderi.org', 'https://insajderi.org/feed/', NULL, 'XK'),
    ('Kallxo', 'https://kallxo.com', 'https://kallxo.com/feed/', NULL, 'XK');

-- Seed sources: Albania
INSERT INTO sources (name, url, rss_url, logo_url, country) VALUES
    ('Balkanweb', 'https://www.balkanweb.com', 'https://www.balkanweb.com/feed/', NULL, 'AL'),
    ('News24', 'https://news24.al', 'https://news24.al/feed/', NULL, 'AL'),
    ('Top Channel', 'https://top-channel.tv', 'https://top-channel.tv/feed/', NULL, 'AL'),
    ('Panorama', 'https://www.panorama.com.al', 'https://www.panorama.com.al/feed/', NULL, 'AL'),
    ('Reporter.al', 'https://reporter.al', 'https://reporter.al/feed/', NULL, 'AL'),
    ('Shqiptarja', 'https://shqiptarja.com', 'https://shqiptarja.com/feed/', NULL, 'AL');

-- Seed sources: Kosovo (additional)
INSERT INTO sources (name, url, rss_url, logo_url, country) VALUES
    ('Zëri',      'https://zeri.info',         'https://zeri.info/rss',                        NULL, 'XK'),
    ('Bota Sot',  'https://www.botasot.info',  'https://www.botasot.info/rss/lajme',           NULL, 'XK'),
    ('Lajmi.net', 'https://lajmi.net',         'https://lajmi.net/feed/',                      NULL, 'XK');

-- Seed sources: Albania (additional)
INSERT INTO sources (name, url, rss_url, logo_url, country) VALUES
    ('Albeu',     'https://albeu.com',         'https://albeu.com/feed/',                      NULL, 'AL'),
    ('ABC News',  'https://abcnews.al',         'https://abcnews.al/feed/',                     NULL, 'AL'),
    ('Shekulli',  'https://shekulli.com.al',   'https://shekulli.com.al/feed/',                NULL, 'AL'),
    ('Standard',  'https://www.standard.al',   'https://www.standard.al/feed/',                NULL, 'AL'),
    ('RTSH',      'https://rtsh.al',           'https://rtsh.al/feed/',                        NULL, 'AL');

-- Seed sources: North Macedonia (Albanian-language)
INSERT INTO sources (name, url, rss_url, logo_url, country) VALUES
    ('Portalb',    'https://portalb.mk',       'https://portalb.mk/feed/',                     NULL, 'MK'),
    ('Tetova Sot', 'https://tetovasot.com',    'https://tetovasot.com/feed/',                  NULL, 'MK');

-- Seed sources: Preshevo Valley / Serbia (Albanian-language)
INSERT INTO sources (name, url, rss_url, logo_url, country) VALUES
    ('Bujanoci',   'https://bujanoci.net',     'https://bujanoci.net/feed/',                   NULL, 'RS');

-- Seed sources: Diaspora
INSERT INTO sources (name, url, rss_url, logo_url, country) VALUES
    ('Albinfo',    'https://albinfo.ch',       'https://albinfo.ch/feed/',                     NULL, 'CH');

-- Seed sources: Sport
INSERT INTO sources (name, url, rss_url, logo_url, country) VALUES
    ('Supersport', 'https://supersport.al', 'https://supersport.al/feed/', NULL, 'AL'),
    ('Sport Ekspres', 'https://sportekspres.com', 'https://sportekspres.com/feed/', NULL, 'XK');
