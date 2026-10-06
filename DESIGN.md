# Design System — Mooze desktop and web

Date: 2026-10-05. Status: approved. Scope: `apps/frontend` (React), shipped first in the Tauri desktop app (`apps/desktop`), then in the browser. The Flutter mobile app keeps its own theme; this system shares its brand (navy surface, pink action) and departs where a wide screen with a keyboard and a mouse asks for it.

Preview with real fonts and a rendered home screen: `~/.gstack/projects/mooze-labs-mooze-client/designs/design-system-20261005/preview.html` (user data, not in the repository).

## Product Context
- **What this is:** a self-custody Bitcoin and Liquid wallet with a PIX on-ramp, Liquid swaps and Bitcoin-Liquid pegs.
- **Who it's for:** everyday Brazilians and bitcoiners; pt-BR is the reference copy, en and es follow.
- **Space:** desktop Bitcoin wallets (Sparrow, Blockstream app), consumer Liquid wallets (Aqua), Brazilian neobanks (Nubank). They converge on dark plus one bright accent, balance and chart first. Power-user wallets are dense and plain.
- **Project type:** desktop app and web app, data-forward dashboard.
- **The one thing to remember:** privacy and self-custody. Your keys on this machine. The sidebar footer says it, the lock timer shows it, privacy mode proves it in one click.

## Aesthetic Direction
- **Direction:** Industrial/Utilitarian dashboard, data-forward. Charts carry the hierarchy. Cards on a dark field.
- **Decoration level:** intentional. One level of card elevation, chart gridlines, 1px hairlines. No illustrations, coin logos, blobs, glassmorphism, 3D or decorative gradients. The only gradient allowed is a chart area fill fading to transparent.
- **Mood:** an instrument panel: calm, precise, in control. Numbers read at a glance; nothing performs for an audience.
- **Reference sites:** blockstream.com/app (dark, one accent), aqua.net (consumer, playful), bullbitcoin.com (editorial, sovereignty), nubank.com.br (single-color brand). We take the dark discipline and leave the marketing gloss.

## Typography
- **Interface and numbers:** Geist, weights 400, 500, 600. Built for dashboards, native tabular figures, clean pt-BR and es diacritics. Enable `font-feature-settings: "tnum" 1` globally and `font-variant-numeric: tabular-nums` on every numeric cell.
- **Display/Hero:** Geist 600, letter-spacing -0.02em. No serif, no separate display face.
- **Data/Tables:** Geist with tabular figures.
- **Code, addresses, txids, PSETs:** JetBrains Mono 400/500 at 13px. Slashed zero; 0/O and 1/l unmistakable.
- **Retired:** Inter (mobile legacy). Never use system-ui as the primary face.
- **Loading:** self-hosted woff2 in `apps/frontend/public/fonts` (desktop and web must work offline and under a strict CSP). Google Fonts is for previews only.
- **Scale (px / line-height):**
  - total: 40 / 1.05, 600
  - page title: 28 / 1.15, 600
  - section title: 18 / 1.3, 600
  - card title: 13 / 1.4, 500, muted color
  - body: 14 / 1.5, 400
  - small: 12 / 1.4
  - label caps: 11 / 1.4, 500, letter-spacing 0.1em, uppercase
  - mono: 13 / 1.5

## Color
- **Approach:** balanced. Surfaces and text are neutral; pink is action and brand; four categorical colors tell assets apart in charts and legends; semantics are conventional.
- **Surfaces:** background `#0B0D12`; surface 1 (cards, sidebar) `#141722`; surface 2 (hover, active nav, chips) `#1D2130`; surface 3 (pressed, nested) `#262B3D`; hairline `#2A2E3B`.
- **Text:** primary `#ECE8E1` (paper white, never `#FFF`); muted `#9194A6`; faint `#5E6275` (axis labels, hints).
- **Action and brand:** `#EA1E63`. Uses: the primary button, the keyboard focus ring (2px, 2px offset), the 2px active-nav rule, the wordmark dot, the patrimony curve. Hover `#F02C6E`. Never a text color on dark surfaces below 16px.
- **Asset palette (charts, legends, dots only):** DePix `#FF6FA5`, L-BTC `#58A6FF`, BTC `#E8A33D`, USDT `#2DB7A3`. DePix is a lighter sibling of the brand pink on purpose; never place the DePix series and a pink primary button in the same chart frame.
- **Semantic:** success `#32B153`, warning `#FB8C00`, error `#E5484D` (lifted from mobile's `#D73131` for contrast on `#0B0D12`), info uses the action pink border.
- **Dark mode:** dark only at launch, matching mobile. A light theme is a separate later pass; keep every color behind CSS custom properties so it stays possible.
- **Contrast:** text on background 15:1; muted on background 6.5:1; pink on background 4.5:1 (UI elements only).

## Spacing
- **Base unit:** 8px (4px half-step).
- **Density:** medium. Body 14px, table rows 44px, card padding 20px, content gutter 24px, sidebar 224px (64px collapsed).
- **Scale:** 2xs(2) xs(4) sm(8) md(16) lg(24) xl(32) 2xl(48) 3xl(64)

## Layout
- **Approach:** grid-disciplined. Sidebar plus a 12-column content grid. Nothing centered.
- **Shell:** sidebar 224px with three groups: Início, Ativos, Histórico; Operar (PIX, Receber, Enviar, Trocar, Peg); Explorador, Ajustes. Active item carries a 2px pink left rule on surface 2. Sidebar footer: Liquid and Bitcoin sync state, "chaves neste computador", lock countdown. Top bar 48px: page title, data freshness, BTC and USDT prices, privacy toggle. Command palette (Cmd/Ctrl+K) as a shortcut to everything, never the only door. The browser build maps shortcuts that collide with the browser to alternatives.
- **Home:** patrimony card (2/3 width): total, 30-day delta, verb buttons with key hints (P, R, E, T), area chart with range selector. Allocation card (1/3): segmented bar, legend, pegs in progress. Assets table (2/3): asset dot, 30-day sparkline, quantity, price, value. Recent activity card (1/3).
- **Grid:** 12 columns, 20px gap, 24px gutter. Breakpoints: 1440 baseline, 1180 drops to 2 content columns, 1024 minimum for desktop, below 860 the sidebar collapses to icons (web only; desktop enforces a minimum window of 1024×700).
- **Max content width:** 1480px.
- **Border radius:** sm 4px (keys, chips inside tables), md 8px (buttons, inputs, nav items), lg 12px (cards, dialogs), full 9999px (range pills, allocation bar).
- **Charts:** patrimony area in pink `#EA1E63`, 2px line, fill from 22% to 0% opacity; gridlines `#2A2E3B`; axis labels faint 11px; sparklines 110×28 in the asset's color at 1.5px; allocation as a segmented bar with 2px gaps. No market green/red for the patrimony line.

## Motion
- **Approach:** intentional. Nothing moves unless data changed or the user acted. No loops, no bounce.
- **Easing:** enter `cubic-bezier(.2,.7,.2,1)` (ease-out); exit ease-in; move ease-in-out.
- **Duration:** micro 100ms (hover, focus); short 160ms (entrances with 4px shift, chips); medium 240ms (chart interpolation on data change, sidebar collapse); long 400ms (page transitions, used rarely).
- **Reduced motion:** honor `prefers-reduced-motion`; charts then snap.

## Components (first set)
- **Buttons:** primary (pink fill, white text), secondary (surface 2 fill, hairline border), ghost (no border, muted text), danger (transparent, error text and 40% error border). Height 34px, radius 8px, 13px 500 weight. Key hint: 11px mono chip inside the button.
- **Inputs:** 34px, surface 1 fill, hairline border, focus ring pink. Addresses and amounts in mono.
- **Status:** 6px dot plus 12px text; success, warning, error, muted for pending.
- **Alerts:** surface 1 card, 1px semantic border at 45% opacity, 13px title 600 and muted body.
- **Privacy mode:** one toggle in the top bar, persisted. Blurs every numeric value (7px) and desaturates and blurs charts (6px). First run explains it once.

## Decisions Log
| Date | Decision | Rationale |
|------|----------|-----------|
| 2026-10-05 | Initial design system created | /design-consultation with web research, screenshots of four reference products and one outside design voice (Claude subagent; Codex unavailable on this account). |
| 2026-10-05 | First proposal (type-led, serif display, no sidebar, balances veiled by default) rejected | Owner wants charts visible and a sidebar. |
| 2026-10-05 | Instrument-panel dashboard approved | Charts carry hierarchy; sidebar navigation; Geist replaces the serif; privacy mode replaces the default veil. |
| 2026-10-05 | Pink stays action and brand; assets get their own categorical palette | Pink would otherwise collide with data series; DePix gets the light-pink seat as the house asset. |
| 2026-10-05 | Dark only at launch | Matches mobile; tokens stay theme-ready. |
