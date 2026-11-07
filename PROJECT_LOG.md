# Project Log — Anti-Gravity Jump

## 2026-11-07 — Разработка прототипа, обязательный сбор ромбиков, релиз на Cloudflare Pages и телеметрия
- **Что сделано:**
  1. Спроектирована архитектура и GDD по методологии Claude-Code-Game-Studios (`design/gdd/`, `docs/architecture/ADR-0001`).
  2. Реализованы контроллер 4-сторонней гравитации, процедурный 8-bit синтезатор звуков, Ghost Ray, движущиеся платформы и режим обязательного сбора кристаллов-ромбиков (`RechargeCrystal`), отпирающий выход (`Goal`).
  3. Собраны 5 уровней (`Tutorial` + `Level 01..04`), система сохранения рекордов (`SaveManager`) и главное меню.
  4. Настроен обход лимита 25 MiB на Cloudflare Pages через разбиение `index.wasm` (38 МБ) на два чанка по ~19 МБ со склейкой в памяти браузера.
  5. Выполнена публикация на `https://antigravityjump.pages.dev/`, добавлены Quiet SEO заметки (`/notes/`), `sitemap.xml`, `robots.txt`, подтверждение Google Search Console (`googlef3f3c11e41734504.html`), заготовка `public/js/clarity.js` (без чужих ID по правилу аналитики) и Cloudflare Pages Function `/api/pulse`, отправляющая сигнал в Telegram `@altergorbot` при каждом живом запуске и прохождении уровня.
