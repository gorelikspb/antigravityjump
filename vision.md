# Vision — Anti-Gravity Jump (`antigravityjump.pages.dev`)

Короткий, плотный неоновый 2D пазл-платформер на Godot 4.7 (WebAssembly + Windows), где игрок переключает вектор собственной гравитации в **4 стороны (`UP`, `DOWN`, `LEFT`, `RIGHT`)**, а выход из каждой комнаты заперт до тех пор, пока не собраны все висящие в воздухе кристаллы-ромбики (`◆`).

## Продакшен и дистрибуция
- **Cloudflare Pages:** https://antigravityjump.pages.dev/
- **GitHub Pages (зеркало):** https://gorelikspb.github.io/antigravityjump/
- **Репозиторий и релизы:** https://github.com/gorelikspb/antigravityjump
- **Телеметрия и сигналы:** Cloudflare Pages Function `/api/pulse` → мгновенный пуш в Telegram (`@altergorbot`) при запуске игры живым игроком и при прохождении уровня + готовность под Microsoft Clarity (`public/js/clarity.js`).
