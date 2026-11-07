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

    const BOT_TOKEN = context.env?.TELEGRAM_BOT_TOKEN;
    const CHAT_ID = context.env?.TELEGRAM_CHAT_ID;

    let tgSent = false;
    if (BOT_TOKEN && CHAT_ID && body.notify !== false) {
      const when = new Date().toLocaleString("ru-RU", { timeZone: "Europe/Berlin" });
      const loc = city ? `${country} (${city})` : country;
      const title =
        event === "level_complete"
          ? `🏆 *Anti-Gravity Jump: пройден уровень!*`
          : `🎮 *Anti-Gravity Jump: новый игрок запустил игру!*`;
      const details = level ? `\n📍 *Уровень:* ${level}` : "";
      const text = `${title}${details}\n🌍 *Локация:* ${loc}\n🔗 *Источник:* ${ref}\n🕒 *Время:* ${when}`;

      const tgRes = await fetch(`https://api.telegram.org/bot${BOT_TOKEN}/sendMessage`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          chat_id: CHAT_ID,
          text,
          parse_mode: "Markdown",
          disable_web_page_preview: true,
        }),
      });
      const tgJson = await tgRes.json().catch(() => ({}));
      tgSent = Boolean(tgJson.ok);
    }

    return new Response(
      JSON.stringify({ ok: true, telegram: tgSent, country }),
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
