# Everyday Wallet Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking. Recommended execution: native implementation in this session, with one final independent review.

**Goal:** Implement the approved Quiet Navy everyday-wallet interface without weakening existing testnet wallet behavior.

**Architecture:** Keep React feature containers, the injected DesktopClient, TanStack Query and Rust host authority. Introduce owned shadcn/Base UI components and pure presentation models, then migrate complete screens. Preserve generated interfaces and wallet state machines unless a demonstrated requirement cannot be represented by the current contract.

**Tech Stack:** Existing React 19, TypeScript, Vite 6, Base UI 1.8, React Router, TanStack Query, react-intl, Lucide, qrcode.react and Tauri 2; selectively copied shadcn/Base UI component source and pinned Tailwind tooling compatible with this Vite installation.

**Spec:** `docs/superpowers/specs/2026-10-06-everyday-wallet-design.md`

## Global Constraints

- Bitcoin testnet3 and Liquid testnet only. No mainnet, fiat pricing, portfolio valuation, PIX, swaps, pegs or light theme.
- TEST ID: `38fca2d939696061a8f76d4e6b5eecd54e3b4221c846f24a6b279e79952850a5`; precision 8; retain sending/receiving and separate L-BTC fees.
- Unknown assets: raw units, full identity, no inferred precision or unsupported sends.
- Integer strings/BigInt for asset amounts; never convert amounts to floating point.
- Compact balances/activity omit trailing fractional zeros. Reviews, receipts and details retain eight decimals in BTC/L-BTC/TEST denominations; sat preference retains exact native-asset integers.
- pt-BR, English and Spanish; self-hosted fonts; no runtime vendor services.
- Host-owned lock intervals: 1, 5, 15, 30, 60 minutes. Preserve fresh authentication, session generations, review expiry, fee bounds, journal recovery, and no automatic resubmission.
- Desktop minimum 1024×700; verify also 1440×900. Normal body text at least 14px, secondary text at least 12px; do not copy scaled prototype typography literally.
- Preserve user changes in `DESIGN.md` and existing MVP documents. The working tree contains the preceding uncommitted implementation: do not reset it, create an isolated checkout that omits it, or blanket-stage unrelated files.
- No product code changes until plan approval. At execution start record the existing diff/untracked inventory and compare each task against that baseline. Commits must distinguish new work from the preceding implementation; if hunks cannot be separated safely, retain them uncommitted and report it rather than misattribute them.
- Read both approved previews under `.superpowers/brainstorm/92550-1791313812/content/`: `quiet-navy-refinement.html` and `send-settings-result.html`. They are presentation references, not production logic.

## Review Focus

1. A pending receive request resolves after the asset changes: never show the former asset's QR/address (Task 4 deferred-promise test).
2. A restored send has a transaction ID but no matching activity yet, or only a legacy journal: retain truthful receipt/unknown states and never invent confirmation (Task 6 model tests).
3. Query refresh arrives while another chain's node draft is dirty: preserve unsaved edits and bind save to the intended chain (Task 7 reducer/component tests).
4. Very large or one-base-unit balances combined with locale, sat preference and privacy: no rounding, misleading zeros, or accessible-text leakage (Tasks 2–3 tests).
5. A dialog is open when the host locks or a send review expires: clear secret views and block stale confirmation; restore focus only to a mounted trigger (Tasks 5, 7–8 tests).

## File and responsibility map

- `src/ui/`: presentational primitives and wallet display components; no DesktopClient/Tauri imports. Keep `index.tsx` as a compatible export surface during migration.
- `src/styles/tokens.css`: semantic Quiet Navy tokens; `main.css`: shell and feature layouts, with obsolete global control rules removed as screens migrate.
- `src/i18n/amount.ts`: exact display formatting. Existing `features/send/amount.ts` continues parsing amounts.
- `src/features/send/`: preserve controller effects in `send-page.tsx`; extract entry, review, result views and a pure receipt selector.
- `src/features/settings/`: routed sections, independently authenticated dialogs, and a pure per-chain draft model.
- Existing dashboard, assets, history, receive, setup and session files retain their feature boundaries.
- `src/testing/client.ts`: extend the existing injected client fixtures only for explicit test scenarios. No runtime mock backend.

Paths below are relative to `apps/frontend/` unless they start with `docs/`, `apps/desktop/`, or `DESIGN.md`.

### Task 1: Owned component foundation and Quiet Navy tokens

**Files:** Modify `package.json`, `vite.config.ts`, `src/styles/main.css`, `src/ui/index.tsx`, root `package-lock.json`, `DESIGN.md`. Create `components.json`, `src/styles/tokens.css`, `src/ui/button.tsx`, `field.tsx`, `dialog.tsx`, `tabs.tsx`, `popover.tsx`, `select.tsx`, `switch.tsx`, `skeleton.tsx`, `separator.tsx`, `utils.ts`, and `src/ui/dialog.test.tsx`. Add AlertDialog/Tooltip source only where a migrated screen consumes it.

**Interfaces:** Preserve existing Button and Field props and Modal's `title`, `children`, `className`, `open`, `onOpenChange`. Add an optional `description` to Modal; remove the generic description from contexts where it is misleading. New components expose controlled state and callbacks; never import wallet effects.

- [ ] Inspect official shadcn Base UI/Vite setup and dependency peer requirements at execution time. Copy only needed component source, retain applicable license notices, pin resolved versions, and record them in the lockfile. Keep Base UI rather than introducing a second primitive library. Configure explicit source scanning and omit Tailwind preflight during migration; do not run a scaffold that overwrites the existing app.
- [ ] Write `dialog.test.tsx` using the existing testing setup: opening focuses the dialog, Escape calls `onOpenChange(false)`, and closing restores the mounted trigger. Run `npm test -w @mooze/frontend -- src/ui/dialog.test.tsx`; confirm any failure is due to the required contract rather than test setup.
- [ ] Implement the owned primitives and CSS tokens from the spec. Compute contrast for actual text/background combinations; adjust action fill if needed for AA. Keep native labeled inputs where a custom widget adds no value. Preserve explicit form button types.
- [ ] Run `npm test -w @mooze/frontend` and `npm run build -w @mooze/frontend`. Inspect setup and settings to catch global-style regressions. No unit tests for purely cosmetic spacing values.
- [ ] Reconcile the relevant `DESIGN.md` sections with Quiet Navy, marking charts/mainnet-related guidance out of this testnet scope without discarding unrelated edits. Commit only attributable task changes: `feat: establish Quiet Navy component foundation`.

### Task 2: Exact compact and full-precision amount display

**Files:** Modify `src/i18n/amount.ts`, `amount.test.ts`, `src/ui/sensitive-value.tsx`, `sensitive-value.test.tsx`. Create `src/ui/amount.tsx`.

**Interfaces:** Extend `displayAssetAmount(units: string, metadata: AssetMetadataDto, preferences: Preferences, mode: 'compact' | 'exact' = 'exact'): {amount: string; ticker: string}`. `Amount({units, metadata, mode, className?})` reads preferences and renders through SensitiveValue; props use the formatter's types and `mode` is required at call sites. Keep parsing and serialized request amounts unchanged.

- [ ] Add formatter assertions for 2,485,000 units → `0.02485` compact/en and `0,02485000` exact/pt-BR; 12,500,000,000 TEST units → `125`; 1 unit → `0.00000001`; zero → `0`; negative values, interior zeros, and `18446744073709551615` without precision loss. Unknown precision stays raw; native sat mode is integer; TEST stays TEST. An unlisted asset claiming ticker BTC must not inherit native sat behavior—use catalog identity/support metadata.
- [ ] Run `npm test -w @mooze/frontend -- src/i18n/amount.test.ts src/ui/sensitive-value.test.tsx` and observe the new expectations fail.
- [ ] Implement string-based formatting and Amount. Honor approved catalog identity, locale separators and precision. Privacy removes amount text from the accessibility tree and includes no sensitive title/tooltip; the visible placeholder remains stable.
- [ ] Run the same tests and frontend typecheck. Commit attributable changes: `feat: format compact wallet amounts without rounding`.

### Task 3: Wallet shell, balances and asset details

**Files:** Modify `src/app/shell.tsx`, `src/features/dashboard/dashboard-page.tsx`, `holdings-model.ts`, `holdings-model.test.ts`, `src/features/assets/assets-page.tsx`, `src/styles/main.css`. Create `src/ui/asset-mark.tsx`, `src/features/dashboard/network-status.tsx`, `dashboard-page.test.tsx`.

**Interfaces:** Keep existing DashboardPage/AssetsPage/AssetPage props. `AssetMark({metadata}: {metadata: AssetMetadataDto})` is decorative with an accessible adjacent name. `NetworkStatus()` consumes existing holdings query/client refresh inside the dashboard feature, exposing the compact status button/popover; no duplicate network store.

- [ ] Test initial unsynchronized balance as unavailable, refresh/error preserving cached amounts with freshness, a one-unit unknown asset remaining reachable, and privacy hiding balance/pending text. Ensure row navigation still resolves `/assets/:chain/:assetKey`.
- [ ] Run `npm test -w @mooze/frontend -- src/features/dashboard` and record the new failing cases.
- [ ] Replace shell navigation with Wallet, Activity, Settings; retain `/history`, `/assets`, asset details, `/send`, `/receive`. Consolidate Testnet/status indicators. Make balance rows/action hierarchy match the preview; use compact Amount and exact detail amounts. Keep all holdings discoverable, conditional pending information, and an actionable empty state. Remove redundant dashboard text/panels.
- [ ] Verify targeted tests and build; inspect both desktop widths. Commit attributable changes: `feat: simplify wallet navigation and balance hierarchy`.

### Task 4: Receive request panel

**Files:** Modify `src/features/receive/receive-page.tsx`, `receive-page.test.tsx`, `src/styles/main.css`. Create `src/features/receive/request-panel.tsx`.

**Interfaces:** `RequestPanel({request, busy, error, onRetry})` consumes `ReceiveRequestDto | null`, boolean, localized string, and `() => void`. Keep request preparation in ReceivePage through `DesktopClient.receiveRequest`; the panel only displays validated data/copy feedback.

- [ ] Add a deferred-promise test: request TEST, switch to BTC, resolve the older TEST request last; assert no TEST URI/QR reappears. Add assertions distinguishing copy-address versus asset/amount-bearing copy-request. Invalid ninth decimal suppresses the previous QR.
- [ ] Run `npm test -w @mooze/frontend -- src/features/receive/receive-page.test.tsx` and confirm new failure before changing request handling where necessary.
- [ ] Implement two-column/stacked request composition with asset selector, optional amount and existing description/request capability, expandable identity, full wrapping address, actual qrcode.react payload and copy feedback. Keep the selected asset stable when a stale async result arrives. Handle an asset preselection supplied by asset details or L-BTC fee recovery by matching its approved key.
- [ ] Run targeted tests and build; scan a disposable real Liquid QR in native acceptance if available, recording any unverified scan explicitly. Commit attributable changes: `feat: refine asset-aware receive requests`.

### Task 5: Send entry and review presentation

**Files:** Modify `src/features/send/send-page.tsx`, `send-page.test.tsx`, `send-state.ts`, `send-state.test.ts` only if extraction requires explicit transitions, and `src/styles/main.css`. Create `send-form.tsx`, `send-review.tsx`.

**Interfaces:** `SendReviewView({review: Review, busy: boolean, expiresAtMs: number, nowMs: number, onEdit: () => void, onConfirm: () => void})` presents host values. `SendForm` receives a controlled `SendDraft {asset: AssetKeyDto; destination: string; amount: string; rate: string; useMax: boolean}`, `onChange(next: SendDraft)`, `onReview()`, approved metadata, fee options and busy/error state. Existing SendPage owns client calls and authorization.

- [ ] Add tests asserting a TEST review renders separate TEST and L-BTC debits, an expired review disables confirmation, and a generation/lock change prevents a pending response repopulating the review. Fee shortage exposes L-BTC receive navigation without submitting. Editing invalidates the old review; do not retain stale Max intent.
- [ ] Run `npm test -w @mooze/frontend -- src/features/send/send-page.test.tsx src/features/send/send-state.test.ts` and record the failures introduced by the new contract.
- [ ] Extract form and review without changing opaque-review submission. Apply inline wrong-network errors, truthful available amount/Max, returned fee choices, source/time labels and custom rate disclosure. Show full destination and exact amounts; maintain privacy with an explicit reveal control available in review. Disable repeated preparation/submission. Preserve safe send draft only within the unlocked session when detouring to receive; clear on lock/removal, never persist secrets or authorization.
- [ ] Run send tests and build. Commit attributable changes: `feat: refine send entry and exact debit review`.

### Task 6: Durable transaction result and receipt

**Files:** Modify `src/features/send/send-page.tsx`, `send-page.test.tsx`; create `submission-view.ts`, `submission-view.test.ts`, `send-result.tsx`. Consume existing generated journal/activity types; do not invent generated fields.

**Interfaces:** `selectSubmissionView(snapshot: Snapshot, localReview: Review | null): SubmissionView | null`. Define `SubmissionView` here with `phase: 'broadcast' | 'confirmed' | 'uncertain'`, nullable `txid`, `request` and `debits` typed from the existing journal/review DTOs, and fee provenance `'review' | 'activity' | 'unavailable'`. A definitely-not-sent local error is passed separately by the existing controller; it cannot be inferred from absent activity. `SendResult({view, onCheck, onViewTransaction, onReturn})` has callbacks only.

- [ ] Add selector tests: restored submission ID with no activity → broadcast, matched confirmed chain+ID → confirmed, uncertain journal remains uncertain when no evidence resolves it, legacy missing request/debits → explicit unavailable fields. A known ID on another chain does not match. Activity fee supersedes a review estimate only when actually supplied.
- [ ] Add a component test clicking Check result and assert refresh/reconciliation occurs while `confirmSend` is never called. Verify unresolved notice survives returning to Wallet. Run `npm test -w @mooze/frontend -- src/features/send` and observe the new cases fail.
- [ ] Implement receipt and distinct outcomes from the approved result preview. Restore details from the existing persisted journal, using local review solely as a temporary fallback. Link known IDs to `/history?chain=…&tx=…`; when activity has not arrived, show receipt/pending lookup rather than a blank details view. Use full precision and honest fee labels; unknown is not zero. Retain any existing explicit acknowledgment guard, never auto-clear unresolved sends for navigation.
- [ ] Run send tests/build. If the existing host DTO cannot express required receipt data, document the exact gap and ask before changing backend contracts; current journal v2 already stores request/debits. Commit attributable changes: `feat: present recoverable transaction results`.

### Task 7: Settings sections, dialogs and network drafts

**Files:** Modify `src/main.tsx`, `src/app/shell.tsx`, `src/features/settings/display-page.tsx`, `security-page.tsx`, `network-page.tsx`, `about-page.tsx`, `remove-wallet-dialog.tsx` and existing settings tests. Create `settings-page.tsx`, `network-draft.ts`, `network-draft.test.ts`, `settings-page.test.tsx`, `security-dialog.tsx`.

**Interfaces:** `SettingsPage()` chooses General/Security/Network/About through `/settings?section=general|security|network|about`; existing settings query remains authoritative. `NetworkDraftState` contains saved settings, per-chain endpoint drafts, global fallback draft and dirty flags. `reduceNetworkDraft(state, event)` accepts `loaded`, `editEndpoint`, `editFallback`, `saved` and `reset` discriminated events using `Chain` and `DesktopSettingsDto`; pure reconciliation preserves dirty values. `SecurityDialog({kind: 'pin'|'recovery', open, onOpenChange})` owns ephemeral secret fields and existing client calls.

- [ ] Test Bitcoin draft → Liquid edit → background settings refresh → Bitcoin return preserving both drafts; save callback captures the intended chain, and failure retains the authoritative prior value without dropping the draft. Navigation away presents discard/cancel when dirty. Save one chain must not overwrite the other's unsaved endpoint; global fallback remains explicitly shared.
- [ ] Test recovery requires fresh authentication; lock/close removes secret content; PIN errors remain localized; removal remains gated by acknowledgment/input and host authentication. Use simulated test values, no real credentials.
- [ ] Run `npm test -w @mooze/frontend -- src/features/settings` and confirm the new behaviors fail before implementation.
- [ ] Implement aligned rows and section tabs, save feedback, per-chain drafts, and focused dialogs. Use Base UI focus management. Replace the top-level BrowserRouter in `src/main.tsx` with RouterProvider and a createBrowserRouter wildcard route rendering App; preserve the existing nested screen routes. Use useBlocker in the settings container for dirty route/section exits, with an accessible discard/cancel dialog. Test shell navigation and browser-history transitions with createMemoryRouter fixtures. Window unload uses the supported beforeunload warning where available; host locking takes priority and clears drafts without blocking security.
- [ ] Preserve native diagnostic save/cancel/failure feedback and resumable partial removal. Verify targeted tests/build and native dialog focus. Commit attributable changes: `feat: organize settings and protect unsaved network edits`.

### Task 8: Activity, setup and lock consistency

**Files:** Modify `src/features/history/history-page.tsx`, `src/features/history/activity.tsx`, `src/features/history/activity-model.ts`, `src/features/history/activity-model.test.ts`, `src/features/setup/setup-page.tsx`, `setup-page.test.tsx`, `src/features/session/session-screen.tsx`, `session-screen.test.tsx`, `src/styles/main.css`; create `src/features/history/history-page.test.tsx`. Update `src/i18n/{pt-BR,en,es}.json` throughout all tasks, finishing the audit here.

**Interfaces:** Preserve HistoryPage/Activity and setup/session props. Extend `Movement` with an explicit `mode: 'compact' | 'exact'` while keeping its existing asset/units inputs; activity rows use compact, details exact. Existing URL selection and `filterActivity` remain the source of selection/filter behavior.

- [ ] Test active filter count/clear, zero-result versus empty-wallet copy, missing timestamp, direct chain+tx selection before and after data arrives, and exact detail amounts under sat/locale preferences. Cover unknown asset ID wrapping without adding inferred metadata.
- [ ] Test setup/lock form state clears on host lock or setup cancellation and translated errors remain available; use existing behavioral tests rather than duplicating Rust security logic. Run relevant history/setup/session tests before changes.
- [ ] Apply compact Activity rows, secondary filter disclosure and accessible details. Restyle setup/backup/lock with shared primitives while retaining required sequence and warnings. Remove remaining obsolete global controls/card wrappers. Complete translations for every new product string; no untranslated ternary labels.
- [ ] Run `npm test -w @mooze/frontend` and `npm run build -w @mooze/frontend`. Commit attributable changes: `feat: align activity and session screens with Quiet Navy`.

### Task 9: Native acceptance and final review

**Files:** Create `docs/everyday-wallet-validation.md`; update `docs/desktop-mvp.md` with the report link. Update this plan's task status with actual evidence.

**Interfaces:** No new product API. Validation distinguishes mocked UI cases, real native behavior, prior regression evidence and outstanding gaps.

- [ ] Run frontend tests/build once on the final implementation and `git diff --check`. Check generated-file freshness only if DTO/codegen inputs changed. Rust host/core tests are required for actual Rust changes; do not claim earlier results are new runs.
- [ ] Build `npm exec -w @mooze/desktop -- tauri build --debug --bundles app`. Use the existing isolated disposable validation profile, never the personal wallet, and verify the isolated window title before interaction. Inspect 1440×900 and 1024×700 in pt-BR/en/es, keyboard/focus, long addresses, privacy, amount precision, dialogs and reduced motion. Record each pass/failure with screen/state/size/locale.
- [ ] Verify real copy-address/request, restart locking, settings save/rollback and diagnostic export/cancel. Test send/review/result with mocked adverse responses plus existing Nigiri/OrbStack regtest tools for transaction changes. Never reset shared chains or submit public faucet requests just for layout checks. Public TEST funding remains distinct from a locally issued test asset.
- [ ] Perform one final independent review of the actual implementation diff and shared dependencies, using the approved execution method. Fix important findings with targeted verification. Native testing must explicitly report any previously open acceptance items still unverified.
- [ ] Record dependency versions, contrast measurements, visual/behavioral evidence, limitations and final commands in the validation report. Preserve design artifacts and prior user work. No push, merge, release or installer publication is part of this plan. Commit only attributable validation changes.

## Self-review and handoff

Coverage: foundation/visual rules → Task 1; amounts/privacy → Tasks 2–3; shell/assets → Task 3; Receive → Task 4; Send → Tasks 5–6; Settings → Task 7; Activity/setup/lock → Task 8; accessibility/localization/native verification → Task 9 and owning tasks. Each Review Focus case has an owning test. UI extraction does not authorize changing backend transaction semantics.

Plan awaits user review. Recommendation: native execution, because the tasks share closely coupled screen/component interfaces and the existing working tree must be preserved carefully; use one independent review at the end. Do not begin implementation until the user approves the plan and execution approach.
