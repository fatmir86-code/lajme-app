import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

// Auto-poll: track last poll time in memory (resets on cold start)
let lastPollTime = 0;
const POLL_INTERVAL_MS = 5 * 60 * 1000; // 5 minutes

async function autoPollIfNeeded() {
  const now = Date.now();
  if (now - lastPollTime < POLL_INTERVAL_MS) return;
  lastPollTime = now;

  // Fire-and-forget: trigger poll-rss in background
  try {
    fetch(`${SUPABASE_URL}/functions/v1/poll-rss`, {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${SUPABASE_SERVICE_ROLE_KEY}`,
        "Content-Type": "application/json",
      },
    }).catch(() => {}); // Ignore errors
  } catch {
    // Ignore
  }
}

const ARTICLE_SELECT =
  "id, title, article_url, image_url, published_at, category_slug, is_breaking, related_sources, source:sources(id, name, url, logo_url, country)";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "GET, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type, Authorization",
};

function safeInt(value: string | null, fallback: number, min = 1): number {
  const parsed = parseInt(value || String(fallback));
  return isNaN(parsed) || parsed < min ? fallback : parsed;
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders });
  }

  // Auto-poll RSS feeds if >5 min since last poll
  autoPollIfNeeded();

  const url = new URL(req.url);
  const path = url.pathname.replace("/api", "").replace(/^\/+/, "");

  const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

  try {
    // GET /articles — paginated article feed
    if (path === "articles" || path === "") {
      const category = url.searchParams.get("category");
      const sourceId = url.searchParams.get("source_id");
      const country = url.searchParams.get("country");
      const page = safeInt(url.searchParams.get("page"), 1);
      const perPage = Math.min(safeInt(url.searchParams.get("per_page"), 20), 50);
      const offset = (page - 1) * perPage;

      let query = supabase
        .from("articles")
        .select(ARTICLE_SELECT)
        .order("published_at", { ascending: false })
        .range(offset, offset + perPage - 1);

      if (category === "aktuale" || !category) {
        // Aktuale = curated top stories only (first 5 articles per source per poll)
        // Excludes "bote" (world news has its own dedicated tab).
        // When the user explicitly picks a country, skip the is_top filter —
        // otherwise small markets (Macedonia, diaspora) appear empty because
        // their sources rarely qualify as "trending" cross-source.
        query = query.neq("category_slug", "bote");
        if (!country) {
          query = query.eq("is_top", true);
        }
      } else {
        query = query.eq("category_slug", category);
      }
      if (sourceId) {
        const sid = safeInt(sourceId, 0, 0);
        if (sid > 0) {
          query = query.eq("source_id", sid);
        }
      }
      // Country filter: look up source IDs for the given country, filter articles.
      // Valid codes: XK (Kosovo), AL (Albania), MK (N. Macedonia), CH (diaspora), RS
      if (country && /^[A-Z]{2}$/.test(country)) {
        const { data: countrySources } = await supabase
          .from("sources")
          .select("id")
          .eq("country", country)
          .eq("is_active", true);
        const ids = (countrySources || []).map((s: { id: number }) => s.id);
        if (ids.length === 0) {
          // No active sources for this country — return empty result
          return new Response(
            JSON.stringify({ articles: [], page, per_page: perPage, has_more: false }),
            { headers: { ...corsHeaders, "Content-Type": "application/json", "Cache-Control": "no-cache, no-store, must-revalidate" } },
          );
        }
        query = query.in("source_id", ids);
      }

      const { data, error } = await query;
      if (error) throw error;

      return new Response(
        JSON.stringify({
          articles: data,
          page,
          per_page: perPage,
          has_more: data?.length === perPage,
        }),
        {
          headers: {
            ...corsHeaders,
            "Content-Type": "application/json",
            "Cache-Control": "no-cache, no-store, must-revalidate",
          },
        },
      );
    }

    // GET /articles/search?q=term
    if (path === "articles/search") {
      const q = url.searchParams.get("q")?.trim();
      if (!q || q.length < 2) {
        return new Response(
          JSON.stringify({ error: "Query parameter 'q' requires at least 2 characters" }),
          {
            status: 400,
            headers: { ...corsHeaders, "Content-Type": "application/json" },
          },
        );
      }

      // Limit query length
      const safeQuery = q.slice(0, 200);
      const page = safeInt(url.searchParams.get("page"), 1);
      const perPage = 20;
      const offset = (page - 1) * perPage;

      // Use ILIKE for flexible substring matching (works with Albanian chars)
      // Backed by pg_trgm GIN index for performance
      const { data, error } = await supabase
        .from("articles")
        .select(ARTICLE_SELECT)
        .ilike("title", `%${safeQuery}%`)
        .order("published_at", { ascending: false })
        .range(offset, offset + perPage - 1);

      if (error) throw error;

      return new Response(
        JSON.stringify({
          articles: data,
          page,
          per_page: perPage,
          has_more: data?.length === perPage,
          query: safeQuery,
        }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    // GET /sources
    if (path === "sources") {
      const { data, error } = await supabase
        .from("sources")
        .select("id, name, url, logo_url, country")
        .eq("is_active", true)
        .order("name");

      if (error) throw error;

      return new Response(
        JSON.stringify({ sources: data }),
        {
          headers: {
            ...corsHeaders,
            "Content-Type": "application/json",
            "Cache-Control": "public, max-age=3600",
          },
        },
      );
    }

    // GET /categories
    if (path === "categories") {
      const { data, error } = await supabase
        .from("categories")
        .select("id, name, slug, icon, sort_order")
        .order("sort_order");

      if (error) throw error;

      return new Response(
        JSON.stringify({ categories: data }),
        {
          headers: {
            ...corsHeaders,
            "Content-Type": "application/json",
            "Cache-Control": "public, max-age=3600",
          },
        },
      );
    }

    return new Response(
      JSON.stringify({ error: "Not found" }),
      {
        status: 404,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      },
    );
  } catch (error) {
    console.error("API error:", error);
    return new Response(
      JSON.stringify({ error: "Internal server error" }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      },
    );
  }
});
