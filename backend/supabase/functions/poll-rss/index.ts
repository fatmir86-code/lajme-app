import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";
import { XMLParser } from "https://esm.sh/fast-xml-parser@4.3.2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

// ─── Layer 0: Source-level category overrides ────────────────────────────────
// Sources that only publish one category — override everything.
const SOURCE_CATEGORY_OVERRIDES: Record<string, string> = {
  "supersport.al": "sport",
  "sportekspres.com": "sport",
  // Tech-specific category feeds
  "albeu.com/category/teknologji": "teknologji",
  "indeksonline.net/teknologji": "teknologji",
};

// ─── Layer 3: Weighted keyword matching ──────────────────────────────────────
// weight 3 = definitive, 2 = strong, 1 = weak/contextual
// wholeWord = true means use regex word boundaries (\b)
interface WeightedKeyword {
  term: string;
  weight: number;
  wholeWord?: boolean;
}

const WEIGHTED_KEYWORDS: Record<string, WeightedKeyword[]> = {
  politike: [
    // Weight 3 — definitive
    { term: "parlament", weight: 3 },
    { term: "kuvend", weight: 3 },
    { term: "kushtetut", weight: 3 },
    { term: "kryeminister", weight: 3 },
    { term: "zgjedhje", weight: 3 },
    { term: "votim", weight: 3 },
    // Weight 2 — strong
    { term: "qeveri", weight: 2 },
    { term: "minister", weight: 2 },
    { term: "deputet", weight: 2 },
    { term: "opozit", weight: 2 },
    { term: "koalicion", weight: 2 },
    { term: "politik", weight: 2 },
    { term: "parti", weight: 2 },
    { term: "president", weight: 2 },
    { term: "diplomatik", weight: 2 },
    { term: "ambasad", weight: 2 },
    { term: "kryetar", weight: 2 },
    { term: "ministri", weight: 2 },
    { term: "komisjon", weight: 2 },
    { term: "rezolut", weight: 2 },
    { term: "sanksion", weight: 2 },
    { term: "referendum", weight: 2 },
    { term: "dekret", weight: 2 },
    // Weight 1 — contextual
    { term: "ligj", weight: 1 },
    { term: "shtet", weight: 1 },
    { term: "qytetar", weight: 1 },
    { term: "mazhoranc", weight: 1 },
  ],
  ekonomi: [
    // Weight 3 — definitive
    { term: "inflacion", weight: 3 },
    { term: "buxhet", weight: 3 },
    { term: "bitcoin", weight: 3, wholeWord: true },
    { term: "privatiz", weight: 3 },
    // Weight 2 — strong
    { term: "ekonomi", weight: 2 },
    { term: "biznes", weight: 2 },
    { term: "banka", weight: 2 },
    { term: "invest", weight: 2 },
    { term: "eksport", weight: 2 },
    { term: "import", weight: 2 },
    { term: "tatim", weight: 2 },
    { term: "kredi", weight: 2 },
    { term: "valut", weight: 2 },
    { term: "startup", weight: 2 },
    { term: "kompani", weight: 2 },
    { term: "ndërmarr", weight: 2 },
    { term: "pagë", weight: 2 },
    { term: "rrogë", weight: 2 },
    { term: "punësim", weight: 2 },
    { term: "papunësi", weight: 2 },
    { term: "tender", weight: 2 },
    { term: "borxh", weight: 2 },
    { term: "shtrenjtim", weight: 2 },
    { term: "naftë", weight: 2 },
    { term: "energji", weight: 2 },
    // Weight 1 — contextual (REMOVED: "çmim", "rritje")
    { term: "dollar", weight: 1, wholeWord: true },
    { term: "euro", weight: 1, wholeWord: true },
    { term: "treg", weight: 1 },
  ],
  sport: [
    // Weight 3 — definitive
    { term: "futboll", weight: 3 },
    { term: "basketboll", weight: 3 },
    { term: "volejboll", weight: 3 },
    { term: "champions league", weight: 3 },
    { term: "premier league", weight: 3 },
    { term: "superlig", weight: 3 },
    { term: "kampionat", weight: 3 },
    // Weight 2 — strong
    { term: "ndeshj", weight: 2 },
    { term: "lojtarë", weight: 2 },
    { term: "trajner", weight: 2 },
    { term: "gol", weight: 2, wholeWord: true },
    { term: "skuadër", weight: 2 },
    { term: "tenist", weight: 2 },
    { term: "olimp", weight: 2 },
    { term: "atletik", weight: 2 },
    { term: "transferim", weight: 2 },
    { term: "kupa", weight: 2 },
    { term: "arbitr", weight: 2 },
    { term: "notim", weight: 2 },
    { term: "boks", weight: 2, wholeWord: true },
    // Weight 2 — club/team names frequently in Albanian headlines
    { term: "Real Madrid", weight: 3 },
    { term: "Barcelona", weight: 3 },
    { term: "Bayern", weight: 3 },
    { term: "Liverpool", weight: 3 },
    { term: "Manchester", weight: 2 },
    { term: "Juventus", weight: 3 },
    { term: "Milan", weight: 2 },
    { term: "Inter", weight: 2, wholeWord: true },
    { term: "Arsenal", weight: 2 },
    { term: "Chelsea", weight: 2 },
    { term: "PSG", weight: 2, wholeWord: true },
    { term: "UEFA", weight: 3, wholeWord: true },
    { term: "FIFA", weight: 3, wholeWord: true },
    // Weight 1 — contextual
    { term: "ligë", weight: 1 },
    // REMOVED: "kombëtar", "kombëtarja", "fitore", "humbje", "finale"
  ],
  bote: [
    // Weight 3 — definitive
    { term: "ndërkombëtar", weight: 3 },
    { term: "OKB", weight: 3, wholeWord: true },
    { term: "SHBA", weight: 3, wholeWord: true },
    { term: "Lindja e Mesme", weight: 3 },
    // Weight 2 — strong
    { term: "botë", weight: 2 },
    { term: "global", weight: 2 },
    { term: "Rusi", weight: 2 },
    { term: "Kinë", weight: 2 },
    { term: "luftë", weight: 2 },
    { term: "paqe", weight: 2 },
    { term: "refugjat", weight: 2 },
    { term: "Europë", weight: 2 },
    { term: "Ukrajnë", weight: 2 },
    { term: "Izrael", weight: 2 },
    { term: "Palestin", weight: 2 },
    { term: "Iran", weight: 2, wholeWord: true },
    { term: "samit", weight: 2 },
    { term: "marrëveshje", weight: 2 },
    { term: "traktat", weight: 2 },
    // Weight 1 — contextual
    { term: "migr", weight: 1 },
    { term: "krizë", weight: 1 },
  ],
  kulture: [
    // Weight 3 — definitive
    { term: "festival", weight: 3 },
    { term: "kinema", weight: 3 },
    { term: "teatr", weight: 3 },
    // Weight 2 — strong
    { term: "kulturë", weight: 2 },
    { term: "muzik", weight: 2 },
    { term: "film", weight: 2 },
    { term: "poezi", weight: 2 },
    { term: "ekspozit", weight: 2 },
    { term: "muze", weight: 2 },
    { term: "koncert", weight: 2 },
    { term: "aktor", weight: 2 },
    { term: "regjisor", weight: 2 },
    { term: "shkrimtar", weight: 2 },
    { term: "piktor", weight: 2 },
    { term: "trashëgimi", weight: 2 },
    { term: "letërsi", weight: 2 },
    { term: "showbiz", weight: 2 },
    // Weight 1 — contextual
    // REMOVED: "çmim", "nominim", "art" (matches "parti"), "libr" (matches "liri")
  ],
  teknologji: [
    // Weight 3 — definitive
    { term: "bitcoin", weight: 3, wholeWord: true },
    { term: "blockchain", weight: 3 },
    { term: "kripto", weight: 3 },
    { term: "SpaceX", weight: 3, wholeWord: true },
    { term: "NASA", weight: 3, wholeWord: true },
    // Weight 2 — strong
    { term: "teknologji", weight: 2 },
    { term: "digital", weight: 2 },
    { term: "internet", weight: 2 },
    { term: "softuer", weight: 2 },
    { term: "aplikacion", weight: 2 },
    { term: "iPhone", weight: 2, wholeWord: true },
    { term: "Android", weight: 2, wholeWord: true },
    { term: "robot", weight: 2 },
    { term: "hapësir", weight: 2 },
    { term: "kompjuter", weight: 2 },
    { term: "smartfon", weight: 2 },
    { term: "siguri kibernetike", weight: 2 },
    { term: "hakër", weight: 2 },
    { term: "dron", weight: 2 },
    { term: "satelit", weight: 2 },
    // REMOVED: "AI" (matches Albanian words), "inteligjenc" (intelligence service)
  ],
};

// ─── LAYER 1: URL path patterns ────────────────────────────────────────────
// Matches path segments like /horoskopi/, /receta/, /mot/ etc.
// Using word-boundary anchors (surrounding slashes) to avoid false positives.
const BASE_BLOCKED_URL_PATTERNS: RegExp[] = [
  // Horoscope / astrology
  /\/horoskopi?\//i,
  /\/horoscope\//i,
  /\/astrologi\//i,
  /\/numerologji\//i,
  // Recipes / cooking
  /\/receta[\/s]?/i,
  /\/gatim\//i,
  /\/kuzhina?\//i,
  // Lifestyle / fashion / beauty
  /\/lifestyle\//i,
  /\/stil-jetes\//i,
  /\/jeta-dhe-stili\//i,
  /\/moda\//i,
  /\/bukuri\//i,
  /\/femra\//i,
  /\/burra\//i,
  // Entertainment / trivia / humor
  /\/kuriozitete\//i,
  /\/zbavitje\//i,
  /\/humor\//i,
  /\/entertainment\//i,
  /\/lojra\//i,
  /\/anekdota\//i,
  // Quizzes
  /\/quiz\//i,
  /\/kuiz\//i,
  // Weather (only as a dedicated section, not articles mentioning weather)
  /\/mot\//i,
  /\/moti\//i,
  /\/parashikim-i-motit\//i,
  // Weddings / relationships tabloid
  /\/dasma\//i,
  /\/martesa\//i,
  // Magazine / tabloid sections
  /\/magazin[ae]?\//i,
  /\/tabloid\//i,
  // Auto-translated articles (Telegrafi & others publish multi-language versions
  // with /de/, /es/, /en/ etc. path prefixes — we only want the Albanian originals).
  // Matches language code as the FIRST path segment after the domain.
  /^https?:\/\/[^\/]+\/(de|es|en|fr|it|tr|ar|ru|pl|nl|sv|no|da|fi|pt|ja|zh|ko|hi|ro|hu|cs|sk|el|hr|sr|bg|uk)\//i,
];

// ─── LAYER 2: Title keyword blocklist ──────────────────────────────────────
// Applied as substring match on lowercased title.
// Keywords chosen to avoid false positives (e.g. "mot" alone would hit "motiv").
const BASE_BLOCKED_TITLE_KEYWORDS: string[] = [
  // Horoscope
  "horoskop",             // horoskopi, horoskopet, horoskopi i ditës…
  "horoscope",
  "shenja e horoskopit",
  "shenja juaj",
  "i lindur më",          // "nëse je i lindur më…" — horoscope birth date
  // Recipes / cooking
  "recetë",
  "receta e ",
  "si të gatuaj",
  "si të përgatisni",
  "përbërësit e ",        // "ingredients of…" — recipe signal
  // Weather forecasts (specific phrases, not just "mot")
  "moti sot",
  "moti nesër",
  "moti për ",
  "parashikim i motit",
  "koha e motit",
  "temperatura sot",
  "reshje shiu",
  // Quizzes / trivia
  " kuiz",
  " quiz",
  "gënjeshtra apo e vërtetë",  // "true or false" trivia
  // Lifestyle filler
  "horoskopi për ditën",
  "horoskopi i datës",
];

// ─── LAYER 3: RSS <category> tag blocklist ─────────────────────────────────
// Checked as substring against each category tag value (lowercased).
// Only applied when the RSS feed actually provides category tags.
const BASE_BLOCKED_RSS_CATEGORIES: string[] = [
  "horoskop", "horoscope", "astrologi",
  "receta", "gatim", "kuzhina", "food",
  "lifestyle", "stil jetes", "stil-jetes",
  "moda", "bukuri", "fashion", "beauty",
  "kuriozitete", "curiosities",
  "zbavitje", "humor", "entertainment",
  "mot ", "parashikim",
  "quiz", "kuiz",
  "femra", "burra", "dasma",
  "magazin",
];

interface FilterRules {
  urlPatterns: RegExp[];
  titleKeywords: string[];
  rssCategories: string[];
}

interface Source {
  id: number;
  name: string;
  rss_url: string;
}

interface ParsedArticle {
  source_id: number;
  title: string;
  article_url: string;
  published_at: string;
  category_slug: string;
  is_top?: boolean;
  image_url?: string | null;
}

// Number of top-ranked articles to mark per source per poll.
// RSS/HTML feeds typically list newest/most-important articles first,
// so we use position in the feed as a proxy for "editor's pick".
const TOP_ARTICLES_PER_SOURCE = 5;

// ─── Layer 1: Comprehensive URL path segment map ─────────────────────────────
// "strong" segments return immediately; "weak" segments are fallback to aktuale
const URL_SEGMENT_STRONG: Record<string, string> = {
  // Sport
  "sport": "sport", "sports": "sport", "sporti": "sport",
  "futboll": "sport", "football": "sport",
  "basketboll": "sport",
  "champions-league": "sport", "premier-league": "sport", "superliga": "sport",
  // Politike
  "politike": "politike", "politika": "politike", "politik": "politike",
  "kosove": "politike", "kosovo": "politike",
  "shqiperi": "politike", "drejtesi": "politike", "vendi": "politike",
  // Ekonomi
  "ekonomi": "ekonomi", "ekonomia": "ekonomi",
  "biznes": "ekonomi", "biznesi": "ekonomi", "business": "ekonomi",
  "financa": "ekonomi", "finance": "ekonomi",
  // Bote
  "bote": "bote", "bota": "bote",
  "nderkombetare": "bote", "world": "bote", "international": "bote",
  "rajoni": "bote", "ballkan": "bote", "europa": "bote",
  // Kulture
  "kulture": "kulture", "kultura": "kulture", "culture": "kulture",
  "art": "kulture", "arte": "kulture",
  "muzike": "kulture", "showbiz": "kulture", "argetim": "kulture", "filmi": "kulture",
  // Teknologji
  "teknologji": "teknologji", "teknologjia": "teknologji",
  "tech": "teknologji", "shkence": "teknologji",
  "auto": "teknologji", "gaming": "teknologji",
};

// Weak URL segments — only used as fallback (map to aktuale)
const URL_SEGMENT_WEAK: Set<string> = new Set([
  "lajme", "lajmet", "aktuale", "kronika", "kronike",
  "sociale", "shendetesi", "arsim",
]);

// ─── Layer 2: RSS <category> tag to slug mapping ─────────────────────────────
const RSS_CATEGORY_MAP: Record<string, string> = {
  // Sport
  "sport": "sport", "sports": "sport", "sporti": "sport",
  "futboll": "sport", "football": "sport", "soccer": "sport",
  "basketboll": "sport", "basketball": "sport",
  "champions league": "sport", "premier league": "sport",
  // Politike
  "politike": "politike", "politika": "politike", "politik": "politike",
  "politikë": "politike",
  "kosove": "politike", "kosovë": "politike",
  "shqiperi": "politike", "shqipëri": "politike",
  "drejtesi": "politike", "drejtësi": "politike",
  // Ekonomi
  "ekonomi": "ekonomi", "ekonomia": "ekonomi",
  "biznes": "ekonomi", "biznesi": "ekonomi", "business": "ekonomi",
  "financa": "ekonomi", "financë": "ekonomi", "finance": "ekonomi",
  // Bote
  "bote": "bote", "bota": "bote", "botë": "bote",
  "nderkombetare": "bote", "ndërkombëtare": "bote",
  "world": "bote", "international": "bote",
  "ballkan": "bote", "europa": "bote", "evropa": "bote",
  "rajoni": "bote",
  // Kulture
  "kulture": "kulture", "kultura": "kulture", "kulturë": "kulture",
  "arte": "kulture", "muzike": "kulture", "muzikë": "kulture",
  "showbiz": "kulture", "argetim": "kulture", "argëtim": "kulture",
  "film": "kulture", "filmi": "kulture",
  // Teknologji
  "teknologji": "teknologji", "teknologjia": "teknologji",
  "tech": "teknologji", "technology": "teknologji",
  "shkence": "teknologji", "shkencë": "teknologji", "science": "teknologji",
  "auto": "teknologji", "gaming": "teknologji",
  // Weak / aktuale
  "lajme": "aktuale", "lajmet": "aktuale", "aktuale": "aktuale",
  "kronika": "aktuale", "kronike": "aktuale", "kronikë": "aktuale",
  "sociale": "aktuale", "shendetesi": "aktuale", "shëndetësi": "aktuale",
  "arsim": "aktuale", "arsimi": "aktuale",
};

// Categories that exist in the database — any category not in this set must
// fall back to "aktuale" to avoid foreign key constraint violations.
const VALID_CATEGORIES = new Set([
  "aktuale",
  "politike",
  "ekonomi",
  "sport",
  "bote",
  "kulture",
]);

function categorize(
  title: string,
  articleUrl: string,
  rssCategories: string[],
  sourceUrl: string,
): string {
  const result = categorizeInner(title, articleUrl, rssCategories, sourceUrl);
  return VALID_CATEGORIES.has(result) ? result : "aktuale";
}

function categorizeInner(
  title: string,
  articleUrl: string,
  rssCategories: string[],
  sourceUrl: string,
): string {
  // ── LAYER 0: Source-level override ──
  // Some sources only publish one category.
  try {
    const parsedSource = new URL(sourceUrl);
    const sourceHost = parsedSource.hostname.replace(/^www\./, "");
    // Check hostname only (e.g. "supersport.al")
    if (SOURCE_CATEGORY_OVERRIDES[sourceHost]) {
      return SOURCE_CATEGORY_OVERRIDES[sourceHost];
    }
    // Check hostname + path (e.g. "albeu.com/category/teknologji")
    const sourceKey = sourceHost + parsedSource.pathname.replace(/\/feed\/?$/, "").replace(/\/+$/, "");
    if (SOURCE_CATEGORY_OVERRIDES[sourceKey]) {
      return SOURCE_CATEGORY_OVERRIDES[sourceKey];
    }
  } catch { /* ignore bad sourceUrl */ }

  // ── LAYER 1: URL path extraction (most reliable) ──
  // Walk segments deepest-first. Strong segments return immediately.
  // Weak segments ("lajme") are stored as fallback.
  try {
    const urlPath = new URL(articleUrl).pathname.toLowerCase();
    const segments = urlPath.split("/").filter(Boolean);
    let weakHit: string | null = null;

    // Walk from deepest to shallowest
    for (let i = segments.length - 1; i >= 0; i--) {
      const seg = segments[i];
      if (URL_SEGMENT_STRONG[seg]) {
        return URL_SEGMENT_STRONG[seg];
      }
      if (!weakHit && URL_SEGMENT_WEAK.has(seg)) {
        weakHit = "aktuale";
      }
    }
    // If we found a weak match but no strong, use it as fallback
    // (continue to other layers which may find something better)
    // weakHit is stored but not returned yet — let layers 2 & 3 try first
  } catch {
    // Invalid URL, fall through
  }

  // ── LAYER 2: RSS <category> tag mapping ──
  if (rssCategories.length > 0) {
    for (const cat of rssCategories) {
      const mapped = RSS_CATEGORY_MAP[cat];
      if (mapped && mapped !== "aktuale") {
        return mapped;
      }
    }
  }

  // ── LAYER 3: Weighted keyword matching on title ──
  const text = title.toLowerCase();
  let bestCategory = "aktuale";
  let bestScore = 0;

  for (const [category, keywords] of Object.entries(WEIGHTED_KEYWORDS)) {
    let score = 0;
    for (const kw of keywords) {
      if (kw.wholeWord) {
        const regex = new RegExp(`\\b${kw.term}\\b`, "i");
        if (regex.test(text)) {
          score += kw.weight;
        }
      } else {
        if (text.includes(kw.term.toLowerCase())) {
          score += kw.weight;
        }
      }
    }
    if (score > bestScore) {
      bestScore = score;
      bestCategory = category;
    }
  }

  // Minimum confidence threshold: if best score < 2, default to aktuale
  if (bestScore < 2) {
    return "aktuale";
  }

  return bestCategory;
}

function normalizeUrl(url: string): string {
  try {
    const u = new URL(url);
    u.protocol = "https:";
    // Strip tracking params
    ["utm_source", "utm_medium", "utm_campaign", "utm_content", "utm_term",
     "ref", "fbclid", "gclid", "_ga", "mc_cid", "mc_eid", "amp"]
      .forEach((p) => u.searchParams.delete(p));
    // Strip hash fragments
    u.hash = "";
    // Strip trailing slashes
    u.pathname = u.pathname.replace(/\/+$/, "") || "/";
    // Normalize www
    u.hostname = u.hostname.replace(/^www\./, "");
    return u.toString();
  } catch {
    return url;
  }
}

function parseRssItems(parsed: Record<string, unknown>): Array<Record<string, unknown>> {
  // RSS 2.0: rss.channel.item
  const channel = (parsed as any)?.rss?.channel;
  if (channel?.item) {
    return Array.isArray(channel.item) ? channel.item : [channel.item];
  }

  // Atom: feed.entry
  const feed = (parsed as any)?.feed;
  if (feed?.entry) {
    return Array.isArray(feed.entry) ? feed.entry : [feed.entry];
  }

  // RDF/RSS 1.0: rdf:RDF.item
  const rdf = (parsed as any)?.["rdf:RDF"];
  if (rdf?.item) {
    return Array.isArray(rdf.item) ? rdf.item : [rdf.item];
  }

  return [];
}

function extractLink(item: Record<string, unknown>): string | null {
  // RSS 2.0: <link> is a string
  if (typeof item.link === "string" && item.link.startsWith("http")) {
    return item.link;
  }

  // Atom: <link> can be object with href, or array of objects
  if (item.link && typeof item.link === "object") {
    const links = Array.isArray(item.link) ? item.link : [item.link];
    // Prefer rel="alternate", fallback to first with href
    const alternate = links.find((l: any) => l["@_rel"] === "alternate" && l["@_href"]);
    if (alternate) return (alternate as any)["@_href"];
    const first = links.find((l: any) => l["@_href"]);
    if (first) return (first as any)["@_href"];
  }

  return null;
}

function decodeHtmlEntities(str: string): string {
  return str
    .replace(/&#(\d+);/g, (_, code) => String.fromCharCode(parseInt(code, 10)))
    .replace(/&#x([0-9a-fA-F]+);/g, (_, code) => String.fromCharCode(parseInt(code, 16)))
    .replace(/&amp;/g, "&")
    .replace(/&lt;/g, "<")
    .replace(/&gt;/g, ">")
    .replace(/&quot;/g, '"')
    .replace(/&apos;/g, "'")
    .replace(/&nbsp;/g, " ");
}

function extractTitle(item: Record<string, unknown>): string | null {
  const title = item.title;
  if (typeof title === "string") return decodeHtmlEntities(title.trim());
  if (title && typeof title === "object" && "#text" in title) {
    return decodeHtmlEntities(String((title as any)["#text"]).trim());
  }
  return null;
}

function extractPubDate(item: Record<string, unknown>): string {
  const raw = item.pubDate || item.published || item.updated || item["dc:date"];
  if (typeof raw === "string") {
    try {
      return new Date(raw).toISOString();
    } catch {
      // fall through
    }
  }
  return new Date().toISOString();
}

// Extract image URL from a parsed RSS item.
// Tries (in order):
// 1. <media:content url="..." medium="image"/>  (MRSS — Telegrafi uses this)
// 2. <media:thumbnail url="..."/>
// 3. <enclosure url="..." type="image/*"/>     (Koha, Bota Sot)
// 4. First <img src="..."> in description/content:encoded HTML
function extractImageUrl(item: Record<string, unknown>): string | null {
  // 1. media:content
  const mediaContent = item["media:content"] || (item as any).content;
  if (mediaContent) {
    const arr = Array.isArray(mediaContent) ? mediaContent : [mediaContent];
    for (const m of arr) {
      const url = (m as any)?.["@_url"];
      if (url && typeof url === "string" && /\.(jpg|jpeg|png|webp|gif)/i.test(url)) {
        return url;
      }
    }
  }

  // 2. media:thumbnail
  const mediaThumb = item["media:thumbnail"];
  if (mediaThumb) {
    const arr = Array.isArray(mediaThumb) ? mediaThumb : [mediaThumb];
    for (const m of arr) {
      const url = (m as any)?.["@_url"];
      if (url && typeof url === "string") return url;
    }
  }

  // 3. enclosure with image type
  const enc = item.enclosure;
  if (enc) {
    const arr = Array.isArray(enc) ? enc : [enc];
    for (const e of arr) {
      const url = (e as any)?.["@_url"];
      const type = String((e as any)?.["@_type"] ?? "");
      if (url && typeof url === "string" && (type.startsWith("image/") || /\.(jpg|jpeg|png|webp|gif)/i.test(url))) {
        return url;
      }
    }
  }

  // 4. First <img src="..."> in description or content:encoded
  const html = String(item.description ?? item["content:encoded"] ?? "");
  if (html) {
    const m = html.match(/<img[^>]+src=["']([^"']+)["']/i);
    if (m && /^https?:\/\//i.test(m[1])) {
      return m[1];
    }
  }

  return null;
}

// Fetch og:image from an article HTML page. Used as a fallback when the RSS
// feed doesn't include an image. We only download the first 32KB of HTML
// (head section) to keep this fast — og:image is always in <head>.
async function fetchOgImage(articleUrl: string): Promise<string | null> {
  const BROWSER_UA = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) " +
    "AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36";
  try {
    const response = await fetch(articleUrl, {
      headers: {
        "User-Agent": BROWSER_UA,
        "Accept": "text/html,application/xhtml+xml,*/*;q=0.8",
        "Range": "bytes=0-32767",
      },
      signal: AbortSignal.timeout(5000),
    });
    if (!response.ok && response.status !== 206) return null;
    const html = await response.text();
    // Match <meta property="og:image" content="...">
    // Also handle name="og:image" and twitter:image as fallback
    const patterns = [
      /<meta[^>]+property=["']og:image(?::secure_url)?["'][^>]+content=["']([^"']+)["']/i,
      /<meta[^>]+content=["']([^"']+)["'][^>]+property=["']og:image(?::secure_url)?["']/i,
      /<meta[^>]+name=["']og:image["'][^>]+content=["']([^"']+)["']/i,
      /<meta[^>]+name=["']twitter:image["'][^>]+content=["']([^"']+)["']/i,
    ];
    for (const p of patterns) {
      const m = html.match(p);
      if (m && /^https?:\/\//i.test(m[1])) {
        return m[1];
      }
    }
  } catch {
    // Silent fail — image is optional
  }
  return null;
}

// ─── Layer 3 helper: extract RSS <category> tags from an item ──────────────
function extractRssCategories(item: Record<string, unknown>): string[] {
  const cat = item.category;
  if (!cat) return [];
  const cats = Array.isArray(cat) ? cat : [cat];
  return cats.map((c) => {
    if (typeof c === "string") return c.toLowerCase().trim();
    if (c && typeof c === "object" && "#text" in c) {
      return String((c as any)["#text"]).toLowerCase().trim();
    }
    return "";
  }).filter(Boolean);
}

// ─── Three-layer relevance filter ─────────────────────────────────────────
function isRelevantArticle(
  title: string,
  url: string,
  rssCategories: string[],
  rules: FilterRules,
): { relevant: boolean; reason?: string } {
  // Layer 1: URL path
  for (const pattern of rules.urlPatterns) {
    if (pattern.test(url)) {
      return { relevant: false, reason: `url:${pattern.source}` };
    }
  }

  // Layer 2: Title keywords
  const normalizedTitle = title.toLowerCase();
  for (const keyword of rules.titleKeywords) {
    if (normalizedTitle.includes(keyword)) {
      return { relevant: false, reason: `title:"${keyword}"` };
    }
  }

  // Layer 3: RSS categories (only if the feed provides them)
  if (rssCategories.length > 0) {
    for (const blocked of rules.rssCategories) {
      for (const cat of rssCategories) {
        if (cat.includes(blocked)) {
          return { relevant: false, reason: `rss-category:"${cat}"` };
        }
      }
    }
  }

  return { relevant: true };
}

// ─── Load extra rules from DB (merged with base rules) ────────────────────
async function loadFilterRules(
  supabase: ReturnType<typeof createClient>,
): Promise<FilterRules> {
  const rules: FilterRules = {
    urlPatterns: [...BASE_BLOCKED_URL_PATTERNS],
    titleKeywords: [...BASE_BLOCKED_TITLE_KEYWORDS],
    rssCategories: [...BASE_BLOCKED_RSS_CATEGORIES],
  };

  try {
    const { data } = await supabase
      .from("filter_rules")
      .select("type, pattern")
      .eq("is_active", true);

    if (data) {
      for (const row of data) {
        if (row.type === "url_pattern") {
          try {
            rules.urlPatterns.push(new RegExp(row.pattern, "i"));
          } catch {
            console.warn(`Invalid url_pattern regex: ${row.pattern}`);
          }
        } else if (row.type === "title_keyword") {
          rules.titleKeywords.push(row.pattern.toLowerCase());
        } else if (row.type === "rss_category") {
          rules.rssCategories.push(row.pattern.toLowerCase());
        }
      }
    }
  } catch (err) {
    // Non-fatal: fall back to base rules if table doesn't exist yet
    console.warn("Could not load filter_rules from DB, using base rules:", err);
  }

  return rules;
}

// HTML-scraping for sites that block RSS (e.g. Top Channel).
// Sources use rss_url like "scrape:https://top-channel.tv/" to trigger this mode.
// Article URLs are extracted via regex matching YYYY/MM/DD/slug pattern.
async function scrapeHtmlFeed(
  source: Source,
  rules: FilterRules,
): Promise<{ articles: ParsedArticle[]; filtered: number }> {
  const articles: ParsedArticle[] = [];
  let filtered = 0;
  const url = source.rss_url.replace(/^scrape:/, "");
  const BROWSER_UA = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) " +
    "AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36";

  try {
    const response = await fetch(url, {
      headers: {
        "User-Agent": BROWSER_UA,
        "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
        "Accept-Language": "sq,en;q=0.9",
      },
      signal: AbortSignal.timeout(15000),
    });
    if (!response.ok) {
      console.error(`Failed to fetch ${source.name}: ${response.status}`);
      return { articles, filtered };
    }
    const html = await response.text();

    // Top Channel: <a href="https://top-channel.tv/YYYY/MM/DD/slug/" class="articleTitle">TITLE</a>
    // Generic regex: match any <a class="articleTitle"> with date-based URL
    const regex = /<a\s+href="(https?:\/\/[^"]+\/(\d{4})\/(\d{2})\/(\d{2})\/[^"]+)"\s+class="articleTitle">\s*([^<\n]+?)(?:<br\s*\/?>|<)/gi;
    const seen = new Set<string>();
    let match;
    while ((match = regex.exec(html)) !== null) {
      const articleUrl = normalizeUrl(match[1]);
      if (seen.has(articleUrl)) continue;
      seen.add(articleUrl);

      const year = match[2];
      const month = match[3];
      const day = match[4];
      // Decode HTML entities in title and trim
      const title = match[5]
        .replace(/&#8243;/g, '"')
        .replace(/&#8220;/g, '"')
        .replace(/&#8221;/g, '"')
        .replace(/&#8217;/g, "'")
        .replace(/&#8216;/g, "'")
        .replace(/&#8211;/g, "-")
        .replace(/&#8212;/g, "—")
        .replace(/&amp;/g, "&")
        .replace(/&nbsp;/g, " ")
        .replace(/&quot;/g, '"')
        .trim();

      if (!title) continue;

      const { relevant, reason } = isRelevantArticle(title, articleUrl, [], rules);
      if (!relevant) {
        console.log(`[FILTERED:${source.name}] (${reason}) ${title}`);
        filtered++;
        continue;
      }

      // HTML date-only URLs don't give us a specific time.
      // Use position in feed as a secondary ordering signal:
      // - Position 0 = newest (spread over the last 2 hours)
      // - Older positions get progressively older timestamps
      // - Never exceed current time (to avoid "future" sort preference)
      const positionOffsetMinutes = articles.length * 5;
      const nowMs = Date.now();
      const urlDate = new Date(`${year}-${month}-${day}T12:00:00Z`);
      // If the article's date is today, use position-based offset from now
      // Otherwise use the URL date (capped to not exceed now)
      const todayUTC = new Date().toISOString().slice(0, 10);
      const urlDateStr = `${year}-${month}-${day}`;
      let publishedAt: string;
      if (urlDateStr === todayUTC) {
        publishedAt = new Date(nowMs - positionOffsetMinutes * 60 * 1000).toISOString();
      } else {
        // Past date — use 12:00 UTC of that date
        publishedAt = urlDate.toISOString();
      }
      const categorySlug = categorize(title, articleUrl, [], source.rss_url);

      articles.push({
        source_id: source.id,
        title,
        article_url: articleUrl,
        published_at: publishedAt,
        category_slug: categorySlug,
      });
    }

    console.log(`[SCRAPE:${source.name}] Found ${articles.length} articles, filtered ${filtered}`);
  } catch (error) {
    console.error(`Error scraping ${source.name}:`, error);
  }

  return { articles, filtered };
}

async function fetchAndParseFeed(
  source: Source,
  rules: FilterRules,
): Promise<{ articles: ParsedArticle[]; filtered: number }> {
  // Dispatch to HTML scraper if rss_url has "scrape:" prefix
  if (source.rss_url.startsWith("scrape:")) {
    return scrapeHtmlFeed(source, rules);
  }

  const articles: ParsedArticle[] = [];
  let filtered = 0;

  try {
    const response = await fetch(source.rss_url, {
      headers: { "User-Agent": "Lajme/1.0 NewsAggregator" },
      signal: AbortSignal.timeout(10000),
    });

    if (!response.ok) {
      console.error(`Failed to fetch ${source.name}: ${response.status}`);
      return { articles, filtered };
    }

    // Handle encoding: check XML prolog for non-UTF-8
    const buffer = await response.arrayBuffer();
    const bytes = new Uint8Array(buffer);
    const preamble = new TextDecoder("ascii").decode(bytes.slice(0, 200));
    const encodingMatch = preamble.match(/encoding=["']([^"']+)["']/i);
    const encoding = encodingMatch?.[1] || "utf-8";
    const xml = new TextDecoder(encoding).decode(bytes);

    const parser = new XMLParser({
      ignoreAttributes: false,
      attributeNamePrefix: "@_",
    });
    const parsed = parser.parse(xml);

    const items = parseRssItems(parsed);

    for (const item of items) {
      const title = extractTitle(item);
      const link = extractLink(item);

      if (!title || !link) continue;

      const articleUrl = normalizeUrl(link);
      const rssCategories = extractRssCategories(item);

      // ── Apply three-layer filter ──
      const { relevant, reason } = isRelevantArticle(title, articleUrl, rssCategories, rules);
      if (!relevant) {
        console.log(`[FILTERED:${source.name}] (${reason}) ${title}`);
        filtered++;
        continue;
      }

      const publishedAt = extractPubDate(item);
      const categorySlug = categorize(title, articleUrl, rssCategories, source.rss_url);
      const imageUrl = extractImageUrl(item);

      articles.push({
        source_id: source.id,
        title,
        article_url: articleUrl,
        published_at: publishedAt,
        category_slug: categorySlug,
        image_url: imageUrl,
      });
    }
  } catch (error) {
    console.error(`Error processing ${source.name}:`, error);
  }

  return { articles, filtered };
}

// Breaking news detection: if 3+ sources publish about same topic within 30min
async function detectBreakingNews(
  supabase: ReturnType<typeof createClient>,
  newArticles: ParsedArticle[],
) {
  const thirtyMinAgo = new Date(Date.now() - 30 * 60 * 1000).toISOString();

  const { data: recentArticles } = await supabase
    .from("articles")
    .select("title, source_id")
    .gte("published_at", thirtyMinAgo);

  if (!recentArticles) return;

  for (const article of newArticles) {
    // Use first 5 chars of each word for stemming approximation
    const titleWords = new Set(
      article.title.toLowerCase().split(/\s+/)
        .filter((w) => w.length > 3)
        .map((w) => w.slice(0, 6)),
    );

    const matchingSources = new Set<number>();
    matchingSources.add(article.source_id);

    for (const recent of recentArticles) {
      if (recent.source_id === article.source_id) continue;

      const recentWords = recent.title.toLowerCase().split(/\s+/)
        .filter((w: string) => w.length > 3)
        .map((w: string) => w.slice(0, 6));
      const overlap = recentWords.filter((w: string) => titleWords.has(w)).length;

      if (overlap >= 3) {
        matchingSources.add(recent.source_id);
      }
    }

    if (matchingSources.size >= 3) {
      await supabase
        .from("articles")
        .update({ is_breaking: true })
        .eq("article_url", article.article_url);
    }
  }
}

Deno.serve(async (req) => {
  // Auth: verify the caller sent the service_role JWT
  const authHeader = req.headers.get("Authorization") ?? "";
  const token = authHeader.replace("Bearer ", "");
  try {
    // Decode JWT payload and check role
    const payload = JSON.parse(atob(token.split(".")[1] || ""));
    if (payload.role !== "service_role") {
      return new Response(JSON.stringify({ error: "Unauthorized" }), {
        status: 401,
        headers: { "Content-Type": "application/json" },
      });
    }
  } catch {
    return new Response(JSON.stringify({ error: "Unauthorized" }), {
      status: 401,
      headers: { "Content-Type": "application/json" },
    });
  }

  const url = new URL(req.url);

  // Debug endpoint — show parsed RSS item keys + extracted image
  if (url.searchParams.get("debug") === "rss-item") {
    const targetUrl = url.searchParams.get("url") ?? "https://telegrafi.com/feed/";
    const resp = await fetch(targetUrl, {
      headers: { "User-Agent": "Mozilla/5.0" },
      signal: AbortSignal.timeout(15000),
    });
    const xml = await resp.text();
    const parser = new XMLParser({
      ignoreAttributes: false,
      attributeNamePrefix: "@_",
    });
    const parsed = parser.parse(xml);
    const items = parseRssItems(parsed);
    const firstItem = items[0] ?? {};
    return new Response(JSON.stringify({
      itemKeys: Object.keys(firstItem),
      mediaContentRaw: firstItem["media:content"],
      enclosureRaw: firstItem.enclosure,
      extractedImage: extractImageUrl(firstItem),
    }, null, 2), { status: 200, headers: { "Content-Type": "application/json" } });
  }

  // Debug endpoint — run scraper directly and return what it sees
  if (url.searchParams.get("debug") === "scrape") {
    const testSource: Source = {
      id: 10,
      name: "Top Channel",
      rss_url: "scrape:https://top-channel.tv/",
    };
    const supabase2 = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);
    const rules = await loadFilterRules(supabase2);
    const result = await scrapeHtmlFeed(testSource, rules);
    return new Response(JSON.stringify({
      articlesFound: result.articles.length,
      filtered: result.filtered,
      samples: result.articles.slice(0, 3),
    }, null, 2), { status: 200, headers: { "Content-Type": "application/json" } });
  }

  // Debug endpoint — fetch a URL and return status + snippet
  if (url.searchParams.get("debug") === "fetch") {
    const targetUrl = url.searchParams.get("url") ?? "https://top-channel.tv/";
    const BROWSER_UA = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) " +
      "AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36";
    try {
      const resp = await fetch(targetUrl, {
        headers: {
          "User-Agent": BROWSER_UA,
          "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
          "Accept-Language": "sq,en;q=0.9",
        },
        signal: AbortSignal.timeout(15000),
      });
      const text = await resp.text();
      const articleTitleCount = (text.match(/class="articleTitle"/gi) || []).length;
      return new Response(JSON.stringify({
        status: resp.status,
        ok: resp.ok,
        contentLength: text.length,
        articleTitleMatches: articleTitleCount,
        contentSnippet: text.substring(0, 500),
        headers: Object.fromEntries(resp.headers.entries()),
      }, null, 2), {
        status: 200,
        headers: { "Content-Type": "application/json" },
      });
    } catch (err) {
      return new Response(JSON.stringify({ error: String(err) }), {
        status: 200,
        headers: { "Content-Type": "application/json" },
      });
    }
  }

  try {
    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

    // Load filter rules (base + any extras from DB)
    const rules = await loadFilterRules(supabase);

    const { data: sources, error: sourcesError } = await supabase
      .from("sources")
      .select("id, name, rss_url")
      .eq("is_active", true);

    if (sourcesError || !sources) {
      throw new Error(`Failed to fetch sources: ${sourcesError?.message}`);
    }

    console.log(`Polling ${sources.length} sources...`);

    const results = await Promise.allSettled(
      sources.map((source: Source) => fetchAndParseFeed(source, rules)),
    );

    const allArticles: ParsedArticle[] = [];
    let totalErrors = 0;
    let totalFiltered = 0;
    const perSource: Record<string, { parsed: number; filtered: number; status: string }> = {};

    for (let idx = 0; idx < results.length; idx++) {
      const result = results[idx];
      const sourceName = sources[idx].name;
      if (result.status === "rejected") {
        totalErrors++;
        perSource[sourceName] = { parsed: 0, filtered: 0, status: "rejected: " + String(result.reason).substring(0, 100) };
        continue;
      }
      allArticles.push(...result.value.articles);
      totalFiltered += result.value.filtered;
      perSource[sourceName] = {
        parsed: result.value.articles.length,
        filtered: result.value.filtered,
        status: "ok"
      };
    }

    // Enrich articles without image_url by fetching og:image from the article HTML.
    // Skip articles that already exist in DB AND already have an image — those don't need work.
    let imagesEnriched = 0;
    if (allArticles.length > 0) {
      const articlesNeedingImages = allArticles.filter((a) => !a.image_url);
      if (articlesNeedingImages.length > 0) {
        // Find existing rows that already have an image — those we can skip.
        const urls = articlesNeedingImages.map((a) => a.article_url);
        const { data: existing } = await supabase
          .from("articles")
          .select("article_url, image_url")
          .in("article_url", urls);
        const alreadyHasImage = new Set(
          (existing ?? [])
            .filter((r: { image_url: string | null }) => r.image_url)
            .map((r: { article_url: string }) => r.article_url),
        );
        const toFetch = articlesNeedingImages.filter((a) => !alreadyHasImage.has(a.article_url));

        // Run in parallel batches of 20 to avoid spawning too many connections
        const PARALLEL = 20;
        for (let i = 0; i < toFetch.length; i += PARALLEL) {
          const batch = toFetch.slice(i, i + PARALLEL);
          const results = await Promise.allSettled(
            batch.map((a) => fetchOgImage(a.article_url)),
          );
          for (let j = 0; j < batch.length; j++) {
            const r = results[j];
            if (r.status === "fulfilled" && r.value) {
              batch[j].image_url = r.value;
              imagesEnriched++;
            }
          }
        }
        console.log(`Enriched ${imagesEnriched}/${toFetch.length} articles with og:image`);
      }
    }

    let totalInserted = 0;
    let insertFailed = false;
    const insertErrors: string[] = [];
    if (allArticles.length > 0) {
      // Insert in batches of 50 to avoid payload size limits
      const BATCH_SIZE = 50;
      for (let i = 0; i < allArticles.length; i += BATCH_SIZE) {
        const batch = allArticles.slice(i, i + BATCH_SIZE);
        const { error: insertError } = await supabase
          .from("articles")
          .upsert(batch, {
            onConflict: "article_url",
            ignoreDuplicates: true,
          });

        if (insertError) {
          const batchNum = Math.floor(i / BATCH_SIZE) + 1;
          const sourceIds = [...new Set(batch.map(a => a.source_id))];
          insertErrors.push(`Batch ${batchNum} (sources: ${sourceIds.join(",")}): ${insertError.message}`);
          console.error(`Batch ${batchNum} INSERT FAILED:`, insertError.message);
          totalErrors++;
          insertFailed = true;
        } else {
          totalInserted += batch.length;
        }
      }

      if (!insertFailed) {
        await detectBreakingNews(supabase, allArticles);
      }

      // Backfill image_url for existing rows that don't have one yet.
      // Upsert with ignoreDuplicates skips updates, so we patch them here.
      const withImages = allArticles.filter((a) => a.image_url);
      // Group by image URL to issue fewer queries (max 100 article URLs per call)
      for (let i = 0; i < withImages.length; i += 50) {
        const batch = withImages.slice(i, i + 50);
        // We need one query per article since each has its own image URL.
        // Run them in parallel for speed.
        await Promise.allSettled(
          batch.map((a) =>
            supabase
              .from("articles")
              .update({ image_url: a.image_url })
              .eq("article_url", a.article_url)
              .is("image_url", null)
          ),
        );
      }
    }

    // Reset is_breaking on articles older than 2 hours
    const twoHoursAgo = new Date(Date.now() - 2 * 60 * 60 * 1000).toISOString();
    await supabase
      .from("articles")
      .update({ is_breaking: false })
      .eq("is_breaking", true)
      .lt("published_at", twoHoursAgo);

    // Post-poll: re-categorize articles based on URL path patterns
    // This catches articles that were inserted by general feeds but have
    // category-specific URLs (e.g. albeu.com/teknologji/...)
    const recatRules = [
      { pattern: "%/kulture/%", slug: "kulture" },
      { pattern: "%/kultura/%", slug: "kulture" },
      { pattern: "%/arte/%", slug: "kulture" },
      { pattern: "%/showbiz/%", slug: "kulture" },
      { pattern: "%/ekonomi/%", slug: "ekonomi" },
      { pattern: "%/biznes/%", slug: "ekonomi" },
    ];
    for (const rule of recatRules) {
      await supabase
        .from("articles")
        .update({ category_slug: rule.slug })
        .like("article_url", rule.pattern)
        .neq("category_slug", rule.slug);
    }

    // Mark top 5 most recent articles per source as is_top (for "Aktuale" curated feed)
    // Uses DB function that handles clearing + re-marking atomically.
    await supabase.rpc("mark_top_articles");

    // Clean up articles older than 7 days
    const weekAgo = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000).toISOString();
    await supabase.from("articles").delete().lt("published_at", weekAgo);

    console.log(
      `Done: ${totalInserted} inserted, ${totalFiltered} filtered, ${totalErrors} errors`,
    );

    return new Response(
      JSON.stringify({
        success: true,
        sources_polled: sources.length,
        articles_parsed: allArticles.length,
        articles_inserted: totalInserted,
        articles_filtered: totalFiltered,
        errors: totalErrors,
        insert_errors: insertErrors,
        per_source: perSource,
      }),
      { headers: { "Content-Type": "application/json" } },
    );
  } catch (error) {
    console.error("Poll RSS error:", error);
    return new Response(
      JSON.stringify({ error: "Internal server error" }),
      { status: 500, headers: { "Content-Type": "application/json" } },
    );
  }
});

// Deployed: 2026-04-14T13:57:17Z
