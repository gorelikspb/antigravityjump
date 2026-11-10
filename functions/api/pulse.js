/**
 * Cloudflare Pages Function: /api/pulse
 * Sends an instant signal to the owner's Telegram (@altergorbot) when a human player
 * launches Anti-Gravity Jump or completes a stage, and exposes summary counters on GET.
 * Based on c:\dev\common\descriptions\telegram_lead_capture_worker.md
 */

const CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type",
};

const statsMem = {
  launches: 0,
  completions: 0,
  lastSeenAt: null,
  recentCountries: [],
};

export async function onRequestOptions() {
  return new Response(null, { status: 204, headers: CORS });
}

export async function onRequestGet() {
  return new Response(
    JSON.stringify({
      ok: true,
      project: "antigravityjump",
      ...statsMem,
    }),
    {
      status: 200,
      headers: { ...CORS, "Content-Type": "application/json" },
    }
  );
}

export async function onRequestPost(context) {
  try {
    const req = context.request;
    const ua = req.headers.get("user-agent") || "";
    if (/bot|crawl|spider|slurp|headless|lighthouse/i.test(ua)) {
      return new Response(JSON.stringify({ ok: true, bot: true }), {
        headers: { ...CORS, "Content-Type": "application/json" },
      });
    }

    const body = await req.json().catch(() => ({}));
    const event = String(body.event || "game_start").slice(0, 40);
    const level = String(body.level || "").slice(0, 60);
    const ref = String(body.referrer || "direct").slice(0, 120);
    const cf = req.cf || {};
    const country = cf.country || "XX";
    const city = cf.city || "";

    statsMem.lastSeenAt = new Date().toISOString();
    if (event === "level_complete") {
      statsMem.completions += 1;
    } else {
      statsMem.launches += 1;
    }
    if (country && !statsMem.recentCountries.includes(country)) {
      statsMem.recentCountries = [country, ...statsMem.recentCountries].slice(0, 8);
    }

    // Telegram notifications completely disabled per user preference.
    return new Response(
      JSON.stringify({ ok: true, country }),
      {
        status: 200,
        headers: { ...CORS, "Content-Type": "application/json" },
      }
    );
  } catch (err) {
    return new Response(
      JSON.stringify({ ok: false, error: String(err?.message || err) }),
      {
        status: 500,
        headers: { ...CORS, "Content-Type": "application/json" },
      }
    );
  }
}
