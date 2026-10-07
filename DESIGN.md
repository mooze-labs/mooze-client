# Design System — Mooze desktop and web

Date: 2026-10-05. Status: approved. Scope: `apps/frontend` (React), shipped first in the Tauri desktop app (`apps/desktop`), then in the browser. The Flutter mobile app keeps its own theme; this system shares its brand (navy surface, pink action) and departs where a wide screen and pointer-friendly controls ask for it.

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
- **Loading:** self-hosted woff2 bundled from pinned Fontsource packages (desktop and web must work offline and under a strict CSP). Google Fonts is for previews only.
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
- **Shell:** sidebar 224px with three groups: Início, Ativos, Histórico; Operar (PIX, Receber, Enviar, Trocar, Peg); Explorador, Ajustes. Active item carries a 2px pink left rule on surface 2. Sidebar footer: Liquid and Bitcoin sync state, "chaves neste computador", lock countdown. Top bar 48px: page title, data freshness, BTC and USDT prices, privacy toggle. Visible navigation and labeled, pointer-friendly controls are the primary interaction. No command palette or advertised keyboard shortcuts in the initial design. Preserve standard keyboard accessibility: logical focus order, visible focus rings, and keyboard-operable controls.
- **Home:** patrimony card (2/3 width): total, 30-day delta, labeled action buttons (PIX, Receber, Enviar, Trocar), without shortcut chips, area chart with range selector. Allocation card (1/3): segmented bar, legend, pegs in progress. Assets table (2/3): asset dot, 30-day sparkline, quantity, price, value. Recent activity card (1/3).
- **Grid:** 12 columns, 20px gap, 24px gutter. Breakpoints: 1440 baseline, 1180 drops to 2 content columns, 1024 minimum for desktop, below 860 the sidebar collapses to icons (web only; desktop enforces a minimum window of 1024×700).
- **Max content width:** 1480px.
- **Border radius:** sm 4px (chips inside tables), md 8px (buttons, inputs, nav items), lg 12px (cards, dialogs), full 9999px (range pills, allocation bar).
- **Charts:** patrimony area in pink `#EA1E63`, 2px line, fill from 22% to 0% opacity; gridlines `#2A2E3B`; axis labels faint 11px; sparklines 110×28 in the asset's color at 1.5px; allocation as a segmented bar with 2px gaps. No market green/red for the patrimony line.

## Motion
- **Approach:** intentional. Nothing moves unless data changed or the user acted. No loops, no bounce.
- **Easing:** enter `cubic-bezier(.2,.7,.2,1)` (ease-out); exit ease-in; move ease-in-out.
- **Duration:** micro 100ms (hover, focus); short 160ms (entrances with 4px shift, chips); medium 240ms (chart interpolation on data change, sidebar collapse); long 400ms (page transitions, used rarely).
- **Reduced motion:** honor `prefers-reduced-motion`; charts then snap.

## Component Foundation
- **Approach:** unstyled React primitives with Mooze-owned styling, shared by desktop and web. The visual rules in this document define the component appearance.
- **Responsibilities:** primitives supply interaction behavior and accessibility foundations; Mooze components supply visual variants, states, and composition. Verify accessibility in the finished screens, including focus management, labels, and keyboard operation.
- **Portability:** keep design tokens in CSS custom properties and encapsulate library-specific composition inside reusable Mooze UI components. Keep wallet business logic and Tauri integration outside these components.
- **Library selection:** the desktop MVP uses Base UI for unstyled interaction primitives, wrapped in Mooze-owned components, alongside semantic native form controls. Styling remains project-owned.

## Components (first set)
- **Buttons:** primary (pink fill, white text), secondary (surface 2 fill, hairline border), ghost (no border, muted text), danger (transparent, error text and 40% error border). Height 34px, radius 8px, 13px 500 weight. Use clear action labels and optional icons; no keyboard shortcut chips.
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
| 2026-10-06 | Remove keyboard-led presentation | Owner approved the initial mockup direction with visible, pointer-friendly actions; remove shortcut chips and the command palette while preserving keyboard accessibility. |
| 2026-10-06 | Unstyled React components with Mooze styling | Preserve the approved visual identity across desktop and web while reusing interaction primitives and keeping styling under project control. Specific library selection remains open. |

## Quiet Navy everyday wallet — approved 2026-10-06

For the current desktop testnet implementation, the approved everyday-wallet direction below supersedes the instrument-panel shell, chart-led hierarchy and component appearance above. Preserve those older sections as design history and broader product context, not current testnet acceptance requirements.

Use continuous navy surfaces, Wallet/Activity/Settings navigation, compact exact balances, contextual Send/Receive actions, and technical details on demand. Background #10121A, raised surface #1B1E29, paper text #F0EDE9, secondary text #A1A5B4, accent #FF7AA7. The primary button uses #CF1855 (hover #DB1B5C) with white text for contrast. CSS custom properties in `apps/frontend/src/styles/tokens.css` are authoritative implementation tokens. Retain bundled Geist and JetBrains Mono; body 14px, secondary 12px minimum.

Selectively owned shadcn/Base UI source supplies interaction primitives; Tailwind utilities have no global preflight. Business logic remains outside primitives. Balances and activity trim trailing zeros; reviews, receipts and details retain full approved precision. Dark only; no invented portfolio valuation or testnet price charts. Respect reduced motion, accessible focus and value masking.

## Desktop composition — 2026-10-07

Retain Quiet Navy and the bundled typefaces. Shared `PageHeader` supplies heading rhythm; `FlowStep` transfers keyboard focus when a transaction or setup step changes. `styles/layout.css` owns page widths, responsive composition and density; component internals remain in the existing component styles.

List pages use a 1120px maximum width; focused Send/Swap pages use 600px. The overview places holdings and recent activity side by side above 1200px and stacks them below. Quick actions are compact labeled controls. Asset details emphasize the exact balance and expose identifiers on demand.

Swap explicitly progresses from editing to review in the same area. Pix shows either a new request form or its payment, with history alongside. Receive exposes optional request fields through disclosure and matches the primary copy action to the selected QR content. Setup separates recovery verification from PIN creation.

Use existing 140–200ms interaction/step motion; honor reduced motion. Navigation alone may use subtle CSS backdrop blur, progressively enhanced over an opaque navy surface and disabled for reduced transparency. This is a portable web treatment, not native Apple Liquid Glass. Transaction data, forms and QR surfaces remain opaque. The activity detail drawer uses Motion’s small React animation API for a 280ms slide and 200ms backdrop fade. Reduced-motion preferences and background windows skip the entrance. Keep animation in the shared dialog presentation layer; Base UI retains focus and dismissal behavior. The drawer emphasizes exact amounts and status, groups metadata into labeled rows, and keeps technical identifiers behind disclosure.

## Account and market data — 2026-10-07

Account level is a dedicated page with current tier, progression and a tier comparison. The separate personal Pix limits card has been removed. Asset details may show public reference-market charts: 1D/7D/1M, BRL/USD, timestamped observations, accessible pointer/keyboard exploration and visible source/update time. L-BTC uses a labeled Bitcoin reference. Unsupported assets and test coins receive no fabricated valuation. Network failure must not produce a default tier or simulated price curve.

## Sidebar modes — 2026-10-07

The existing Quiet Navy shell supports an expanded 208px sidebar and a compact 72px icon rail. A persistent toggle switches modes; the local device preference is stored separately from wallet display settings. Without a saved preference, windows at or below 1100px start compact. Resizing does not override an explicit choice. Compact navigation retains accessible labels, hover/focus tooltips, active-route styling, network status, and wallet locking. Layout motion respects reduced motion. Native window styling remains outside this change.

## Holdings in BRL — 2026-10-07

Display estimated BRL values alongside asset quantities and an overview total. Verified mainnet DePix uses the requested fixed rate of 1 DePix = R$1; BTC and L-BTC share the Bitcoin reference price, and USDT uses the Tether market price. Reuse the existing public price-history service's latest one-day observation, refreshing every five minutes and expiring observations after one hour (also reevaluate on focus/visibility changes). Keep wallet quantities in integer base units and round valuations to cents. Missing prices, unknown assets, unsynchronized or stale balances, and test coins are unavailable; label incomplete totals as partial. Pending balances are already included and must not be added again. Both per-asset and total fiat values follow privacy masking. Show market source/time and conversion assumptions.
