# Polished Desktop Testnet Wallet Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development or superpowers:executing-plans to implement this plan task-by-task after user review and execution-method selection. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Finish a desktop testnet wallet with BTC/L-BTC/TEST holdings, complete wallet lifecycle, asset-aware transactions, accurate history, configurable locking, and usable settings.

**Architecture:** Keep pure wallet rules in Rust and pure presentation selectors/reducers in TypeScript. Inject the wallet client into React; the narrow Tauri command surface authorizes each use case. Preserve shared-core/mobile behavior through additive APIs and keep OS effects in native adapters.

**Tech Stack:** Existing Rust, Tauri 2, React 19, TypeScript, TanStack Query, React Router, React Intl, Base UI, Vitest; reuse pinned dependencies and native storage.

**Spec:** [Approved design](../specs/2026-10-06-polished-testnet-wallet-design.md). Read it alongside this plan.

## Global Constraints

- Bitcoin testnet3 and Liquid testnet only; no mainnet switch, PIX, swaps, pegs, fiat valuation, or portfolio charts.
- Supported send/receive assets: BTC, Liquid testnet policy L-BTC, and TEST `38fca2d939696061a8f76d4e6b5eecd54e3b4221c846f24a6b279e79952850a5`, all precision 8. Unlisted assets are visible as raw units, never sendable.
- Lock intervals: **1, 5, 15, 30, 60 minutes**, default **1 minute**; foreground inactivity and background duration apply. Manual/restart locking and background sync remain.
- Follow `DESIGN.md` with the spec's chart-free testnet exception. Sidebar 224px, header 48px, minimum 1024×700, baseline 1440px. pt-BR reference copy, en/es support.
- Preserve the frozen Dart bridge, current derivation, empty BIP39 passphrase, testnet storage isolation, credential service, retry throttling, session generations, bounded signing, and one-use 60-second reviews.
- Initial native validation target: macOS. Do not claim Windows/Linux, distribution signing, or mainnet readiness.
- Never use an existing personal wallet for tests. No secrets in logs, query caches, URLs, persistent frontend state, or committed artifacts.
- Add no new product dependency without demonstrating a gap in existing capabilities and checking its current official documentation at execution time.
- Commit only task-owned files. Existing modified design documents and untracked MVP documents belong to prior work and must remain untouched.

## Review Focus

1. Delayed activity at the deadline must not unlock an expired session; system suspend/clock rollback must not extend it — Tasks 5–6.
2. Unknown asset amounts above JavaScript's safe-integer limit remain exact and readable — Tasks 2–3.
3. A TEST transfer can afford TEST but lack L-BTC fees; review must never add unlike units — Tasks 9–10.
4. Closing, locking, or restarting during broadcast must not lose an uncertain result or resend — Tasks 10–11.
5. Node-setting or wallet-removal failure halfway through must remain recoverable without silently changing privacy settings — Tasks 13–14.

## Stages and dependencies

This is one coordinated plan with four reviewable delivery stages. Stage A (Tasks 1–4) improves the existing wallet without enabling new sends. Stage B (5–8) completes lifecycle/security. Stage C (9–12) completes transactions/history. Stage D (13–16) finishes settings and validation. Do not enable TEST sending until its host authorization and fee tests pass. Tasks are sequential unless the selected execution workflow explicitly isolates independent changes.

## File ownership and shared contracts

Existing entry points: `apps/frontend/src/app.tsx`, `main.tsx`, `core/client.ts`, `core/tauri.ts`; desktop `src-tauri/src/{session.rs,dto.rs,commands.rs,send_review.rs,lib.rs}`; shared `crates/mooze-app/src/{methods.rs,app/wallets.rs,dto/wallet.rs}`. Keep generated TypeScript generated, not hand-edited.

New frontend responsibilities: `app/client-context.tsx` (injection), `app/session-provider.tsx` (session/query lifecycle), `app/shell.tsx` (navigation), `features/{dashboard,assets,history,receive,settings,setup}` (feature screens/models), `features/send/send-state.ts` (flow reducer), `i18n/` (catalogs/preferences). Each task below names its files and tests.

New Rust responsibilities: `crates/mooze-app/src/assets.rs` (testnet product catalog), `crates/mooze-app/src/dto/desktop_wallet.rs` (additive exact DTOs), host `session/{idle.rs,setup.rs,security.rs,settings.rs}` (host use cases), host `platform/idle_clock.rs` (elapsed-time adapter), and `crates/mooze-core/src/payment_request.rs` (exact network/asset request codec). Register modules in their adjacent existing `mod.rs`/`lib.rs` and codegen exports as needed.

Canonical types to introduce:

- `AssetKeyDto { chain: ChainDto, asset_id: Option<String> }`; BTC has no ID, Liquid always has one. Validate combinations on the host.
- `AssetMetadataDto { key: AssetKeyDto, ticker: Option<String>, precision: Option<u8>, approved: bool }`.
- `AssetAmountDto { asset: AssetKeyDto, units: String }`; unsigned quantities are decimal integer strings; history signed movements use a separately named `delta_units: String` field.
- `HoldingDto { metadata: AssetMetadataDto, balance_units: String, available_units: Option<String>, pending_units: Option<String> }`; null means unavailable, never zero.
- `WalletActivityDto { id: String, chain: ChainDto, timestamp_ms: Option<u64>, status: StatusDto, confirmations: u32, movements: Vec<AssetMovementDto>, fee: Option<AssetAmountDto>, addresses: Vec<String> }`; `AssetMovementDto { asset: AssetKeyDto, delta_units: String }`. Movement values exclude the separately represented network fee; normalization must account for backend semantics.
- `DesktopSettingsDto { version: u32, lock_minutes: u16, locale: String, bitcoin_unit: String, privacy: bool, bitcoin_node: Option<String>, liquid_node: Option<String>, public_fallback: bool }`. Validate locale against `pt-BR/en/es`, units against `BTC/sat`, and timeouts against the approved set.

These are additive DTOs, not replacements for the frozen mobile types. Export TypeScript using existing generators. New raw quantities cross IPC as strings; existing safe numeric DTOs remain compatible until their desktop consumers migrate.

## Verification commands

Use these aliases in task descriptions as literal command references, not new shell scripts:

- **F:** `npm run frontend:test`, `npm run frontend:typecheck`, `npm run frontend:build`.
- **H:** `cargo test --locked --manifest-path apps/desktop/src-tauri/Cargo.toml --features codegen`.
- **A:** `cargo test --locked --manifest-path crates/mooze-app/Cargo.toml --features codegen,electrum,http-reqwest`.
- **C:** `cargo test --locked --manifest-path crates/mooze-core/Cargo.toml --features electrum,http-reqwest`.
- **G:** `npm run codegen -w @mooze/desktop`; shared DTO/API changes also use the existing `crates/mooze-app/src/bin/codegen.rs` generator and its freshness test.
- **M:** `cargo check --locked --manifest-path packages/mooze_core_bridge/rust/Cargo.toml`, then `flutter test` from `apps/mobile` when shared behavior changes.

Target one test with `npm run frontend:test -- <path>` or insert its Rust name filter into H/A/C while developing. Expected passing output is zero failures and exit code 0. Run a new behavioral test first to establish its intended failure; build errors from missing scaffolding are not a substitute for checking the assertion once scaffolding compiles.

### Task 1: Inject the client and extract the shell

**Files:** Modify frontend `app.tsx`, `main.tsx`, `core/client.ts`, `testing/client.ts`; create `app/client-context.tsx`, `app/session-provider.tsx`, `app/shell.tsx`, `app/session-provider.test.tsx`.

**Interfaces:** `WalletClientProvider({client, children})`, `useWalletClient(): DesktopClient`, `SessionProvider`, `useWalletSession(): {session: Session | null, startupError: string}`. Session provider owns subscribe/status synchronization and generation-scoped cache invalidation; the entry point selects native availability.

- [ ] Add `lock_discards_late_snapshot`: resolve an in-flight snapshot after a lock event and assert `expect(screen.queryByText(secretBalance)).not.toBeInTheDocument()`. Add an older-generation-event case.
- [ ] Run the focused test and establish the failure.
- [ ] Extract shell/session without changing existing wallet behavior; route all feature calls through the injected client. Keep the explicit non-Tauri launch message in the entry boundary.
- [ ] Run F; confirm subscribe cleanup under StrictMode and no automatic fixture fallback.
- [ ] Commit task files: `refactor(frontend): isolate wallet client session and shell`.

### Task 2: Add the catalog and exact holding DTOs

**Files:** Create `crates/mooze-app/src/assets.rs`, `dto/desktop_wallet.rs`; modify `lib.rs`, `dto/mod.rs`, `app/wallets.rs`, `methods.rs`, generator exports; host `dto.rs`, `session.rs`, `commands.rs`; generated files and frontend `core/client.ts`/fake client.

**Interfaces:** Pure `testnet_asset_metadata(key: &AssetKeyDto) -> AssetMetadataDto`; additive facade `wallet_holdings() -> Vec<HoldingDto>`; host/client `approvedAssets(): Promise<AssetMetadata[]>`, `holdings(): Promise<Holding[]>`. Both host reads require an unlocked session and retain generation checks.

- [ ] Add `testnet_catalog_is_exact`: assert TEST precision is `Some(8)`, mainnet IDs are not approved, the testnet policy asset is approved, and the catalog has exactly three approved entries.
- [ ] Add `unknown_large_holding_roundtrips`: serialize `9_007_199_254_740_993u64`; assert JSON contains the exact string `"9007199254740993"`, metadata precision is null, approval false.
- [ ] Run focused A/H failures, then implement catalog and direct domain-to-exact-DTO conversion. Do not route large holdings through JavaScript numbers or the current whole-snapshot safe-number rejection.
- [ ] Run G, A, H, F and M for shared changes.
- [ ] Commit: `feat(wallet): expose approved testnet assets and exact holdings`.

### Task 3: Build holdings dashboard and asset pages

**Files:** Create frontend `features/dashboard/{dashboard-page.tsx,holdings-model.ts,holdings-model.test.ts}`, `features/assets/{assets-page.tsx,asset-page.tsx}`; modify routes and `styles/main.css`.

**Interfaces:** `selectHoldings(holdings: Holding[], chains: ChainState[], activityAssetKeys: string[]): HoldingView[]`; `HoldingView` includes stable key, metadata, formatted balance, availability/freshness, and available actions. Routes `/assets` and `/assets/:chain/:assetKey`; use `native` for BTC, full ID for Liquid.

- [ ] Add assertions that unsynced BTC renders unavailable, known synchronized zero renders zero, unknown raw `9007199254740993` stays exact, and TEST appears with historical activity even at zero. Use `expect(view.balanceText).toBe("9007199254740993")` for raw units.
- [ ] Run the focused model tests to failure.
- [ ] Extract dashboard and asset screens; remove the chart placeholder; render holdings, separate chain status, recent activity, pending/unavailable labels, and contextual actions. Keep TEST in Receive choices independently of holdings visibility.
- [ ] Run F and inspect 1024×700/1440px controlled preview states; no live wallet required.
- [ ] Commit: `feat(frontend): show all testnet holdings and asset details`.

### Task 4: Establish localization and privacy presentation

**Files:** Create frontend `i18n/{messages.ts,pt-BR.json,en.json,es.json}`, `ui/sensitive-value.tsx`, `ui/sensitive-value.test.tsx`; modify shell/pages, `main.tsx`, and existing UI barrel.

**Interfaces:** `SensitiveValue({children, hidden})`; `messagesFor(locale: "pt-BR" | "en" | "es")`; stable error-code message mapping. Reuse mobile ARB copy where meanings match; desktop-specific strings live in these catalogs.

- [ ] Add `privacy_hides_accessible_value`: assert the original amount is absent from visible text, accessible names, and tooltips when hidden. Assert catalog key sets match across three locales.
- [ ] Run failing focused tests; implement the shared component/catalogs and replace hard-coded copy in migrated pages. Future tasks must use the same catalogs.
- [ ] Run F and check expanded English/Spanish labels at minimum width.
- [ ] Commit: `feat(frontend): establish localized private wallet presentation`.

### Task 5: Implement pure inactivity rules and elapsed-time adapter

**Files:** Create host `session/idle.rs`, `platform/idle_clock.rs`; modify `session.rs`, `platform/mod.rs`, `dto.rs`, `session/tests.rs`.

**Interfaces:** `IdleState`, `IdleEvent::{Activity,Foreground,Background,SetInterval}`, pure `transition_idle(state: &IdleState, event: IdleEvent, elapsed_ms: u64) -> IdleDecision`; `IdleDecision::{Continue(IdleState),Lock}`. Native `IdleClock::elapsed_ms() -> u64` uses suspend-inclusive elapsed time on supported macOS; inject a manual clock in tests. Invalid timing observations fail closed.

- [ ] Add table-driven boundaries for `[1,5,15,30,60]`: at `interval*60_000-1` continue; at `interval*60_000` lock. Assert late activity locks; backgrounding at 50 seconds cannot extend the one-minute deadline; return without interaction does not reset it.
- [ ] Add shortened-interval, rollback, and simulated suspend assertions; run focused H to failure.
- [ ] Implement rules and adapter without wall-clock-only authorization. Preserve wall time only for presentation/persistence where appropriate. If platform suspend behavior cannot be established, stop and resolve it before claiming timeout completion.
- [ ] Run H; manually verify native suspend/resume timing with a disposable profile.
- [ ] Commit: `feat(desktop): enforce inactivity deadlines with elapsed time`.

### Task 6: Integrate auto-lock into host and frontend

**Files:** Modify host `lib.rs`, `session.rs`, `commands.rs`, `dto.rs`; frontend session provider/client/transport; create `app/activity.ts`, `app/activity.test.tsx`; update session tests.

**Interfaces:** client `recordActivity(generation: number): Promise<void>`; native focus/background lifecycle calls IdleEvent directly. Host timestamps eligible notifications, checks deadline before resetting, and applies expiry in `authorize` and signing callbacks.

- [ ] Add `expired_command_locks_without_timer_tick` and `old_generation_activity_cannot_extend_session`. UI test dispatches keyboard/pointer activity versus a sync event and asserts only eligible focused user interaction calls `recordActivity`.
- [ ] Run focused H/F failures; integrate deadline scheduling, generation checks, trusted focused interaction reporting, and late response suppression. Rate-limit activity IPC without losing the last real interaction or extending expiry. Remove immediate focus-loss lock.
- [ ] Run G/H/F; assert lock clears secret forms/reviews but keeps runtime synchronization.
- [ ] Commit: `feat(desktop): connect foreground and background auto-lock`.

### Task 7: Create and back up a wallet

**Files:** Create host `session/setup.rs`; modify session/commands/DTOs; create frontend `features/setup/{setup-page.tsx,setup-state.ts,setup-page.test.tsx}`; adapt session screen and client.

**Interfaces:** `beginSetup(extended: boolean): Promise<{setup_id: string, words: string[], challenge_indices: number[]}>`; `completeSetup(setupId: string, answers: string[], pin: string): Promise<Session>`; `cancelSetup(setupId: string): Promise<void>`. Host generates and owns candidate/challenge; client cannot mark backup complete arbitrarily. Existing `importWallet` remains.

- [ ] Add setup tests: 12/24 word counts, wrong answer refusal, duplicate completion refusal, cancellation, persistence failure followed by retry, and valid import lengths 12/15/18/21/24. Assert no installed-wallet marker on incomplete setup.
- [ ] Run failing focused H/F; implement bounded setup lifetime and native persistence using existing import cleanup guarantees. Never overwrite a configured wallet.
- [ ] Build welcome/create/verify/PIN/import screens with localized errors and explicit testnet identity; clear candidate UI on exit/lock/completion.
- [ ] Run H/F/C and M if shared mnemonic behavior changes; exercise native creation with isolated credentials.
- [ ] Commit: `feat(desktop): complete wallet creation and backup flow`.

### Task 8: Add security preferences and fresh authentication

**Files:** Create host `session/security.rs`, `session/settings.rs`; frontend `features/settings/{settings-page.tsx,security-page.tsx,security-page.test.tsx}`; modify commands/DTOs/client and storage tests.

**Interfaces:** `settings(): Promise<DesktopSettings>`, `setLockMinutes(minutes: number): Promise<DesktopSettings>`, `revealRecoveryPhrase(pin: string): Promise<string[]>`, `changePin(currentPin: string, newPin: string): Promise<void>`. Fresh PIN checks happen inside the scoped operation, reuse throttling, and recheck session after awaits.

- [ ] Add assertions that missing settings migrate to version 1/one minute; unsupported intervals fail; wrong PIN cannot reveal/change credentials; locking during authentication rejects the result. Assert recovery words disappear on lock.
- [ ] Run focused H/F failures; implement validated persistence, selected interval application, secret-view clearing, and recovery/change-PIN screens. Do not return reusable unrestricted authorization tokens.
- [ ] Run G/H/F and storage-failure cases; existing PIN remains usable after failed change persistence.
- [ ] Commit: `feat(desktop): add security preferences and protected recovery`.

### Task 9: Add exact payment requests and asset-aware receiving

**Files:** Create core `payment_request.rs` and module export; modify `payment_uri.rs` only to share safe internals without changing legacy API; add facade DTO/method wrappers; host commands/client; frontend `features/receive/{receive-page.tsx,receive-page.test.tsx}` and amount utilities/tests.

**Interfaces:** `PaymentRequestDto { asset: AssetKeyDto, address: String, amount_units: Option<String>, description: Option<String> }`; `ParsedPaymentDto` is a tagged union of `BareAddress { chain: ChainDto, address: String }` and `Request(PaymentRequestDto)`. Client `parsePaymentRequest(input: string): Promise<ParsedPayment>` and `receiveRequest(asset: AssetKey, amountUnits: string | null, description: string | null): Promise<{address: string, uri: string}>`. Bare Liquid addresses carry no inferred asset; the send flow requires explicit selection. Asset-less Liquid URIs also require selection: represent their parsed request as `UnspecifiedLiquidRequest { address: String, amount_text: Option<String>, description: Option<String> }`, retaining amount text until the asset/precision is selected and validated. Implement exact codec via integer decimal parsing, not the legacy floating-point path.

- [ ] Add round-trip fixtures for BTC/L-BTC/TEST, one base unit, eight decimals, encoded descriptions, wrong networks, unsupported IDs, and malformed/duplicate amount fields. Assert TEST URI preserves the exact approved ID and `"1"` base unit.
- [ ] Run focused C/H/F failures; implement codec and receive commands. Reuse an address across amount/description changes; chain/asset changes must update QR and copy feedback consistently.
- [ ] Run C/A/G/H/F/M and UI tests asserting distinct Copy address/Copy payment request contents.
- [ ] Commit: `feat(wallet): support exact testnet asset payment requests`.

### Task 10: Extend send reviews for asset debits, estimates, and Max

**Files:** Modify host `dto.rs`, `send_review.rs`, `session.rs`, `commands.rs`, tests; facade `app/wallets.rs` and additive DTOs; core `wallet/{bitcoin.rs,liquid/mod.rs,backend.rs,fees.rs}` as needed for builder-backed estimation/Max.

**Interfaces:** New review request `{asset: AssetKeyDto, destination: String, amount: SendAmountDto, fee_rate_sat_per_vbyte: f64}`, `SendAmountDto::{Exact(String),Max}`. Review returns resolved exact request, `fee: AssetAmountDto`, `debits: Vec<AssetAmountDto>`, ID/expiry/generation. Remove desktop consumers of ambiguous `total_sat`. Client `feeOptions(asset: AssetKey): Promise<FeeOptions>`; options carry source/freshness and kind `live|configured|unavailable`.

- [ ] Add fixtures: TEST `100000000` plus fee `100` yields TEST debit `100000000` and L-BTC debit `100`; no unlike-unit addition. Unknown asset request is rejected; insufficient L-BTC blocks TEST; Max handles each asset correctly; nine decimals/overflow fail.
- [ ] Preserve tests for review expiry, duplicate confirmation, exact/exceeded actual fee, lock before signing, and asset/destination tampering. Run focused H/C to failure.
- [ ] Implement host policy and builder-backed fee/debit review. Use the selected testnet backend for fee estimates; never silently query the current mainnet Blockstream/BitGo URLs. Configured Liquid rates are labeled configured, not live estimates.
- [ ] Run C/A/G/H/F/M as touched; ensure TEST signing fixture validates both asset selection and fee denomination before enabling sending.
- [ ] Commit: `feat(desktop): authorize testnet asset sends with separate fee debits`.

### Task 11: Build the send state machine and durable result UI

**Files:** Create frontend `features/send/{send-state.ts,send-state.test.ts}`; modify `send-page.tsx`, tests, amount helpers; host submission DTO/persistence/session tests and client.

**Interfaces:** `reduceSend(state: SendState, event: SendEvent): SendState` with discriminated editing/preparing/reviewing/submitting/submitted/failed/uncertain states. Submission record version 2 includes resolved asset/debits and optional txid; migrate version 1 without inventing missing details. Confirmation still takes only review ID.

- [ ] Assert edited inputs invalidate review; bare Liquid address requires explicit asset; insufficient fee balance explains L-BTC; uncertain result never calls confirm a second time. Restart fixture retains uncertain state and blocks casual repeat submission.
- [ ] Run focused H/F failures; implement reducer/effect separation, quote expiry feedback, exact review rows, history link, and result recovery. Persist submission intent before broadcast and distinguish definite pre-submit failures from unknown post-submit outcomes.
- [ ] Run H/F; simulate navigation, lock, and transport loss at preparation/signing/broadcast boundaries. No secret draft is persisted.
- [ ] Commit: `feat(frontend): finish asset send review and recovery states`.

### Task 12: Normalize multi-asset history and add details panel

**Files:** Modify core `wallet/liquid/{mod.rs,classify.rs}`, `wallet/history.rs` only as required to retain movements; add facade activity projection in `app/wallets.rs` and DTOs; create frontend `features/history/{history-page.tsx,activity-model.ts,activity-model.test.ts,transaction-panel.tsx}`.

**Interfaces:** facade `wallet_activity() -> Vec<WalletActivityDto>`; client `activity(): Promise<WalletActivity[]>`; pure `filterActivity(rows: WalletActivity[], filter: ActivityFilter): WalletActivity[]`. History selection is addressable by chain+txid; asset details/home reuse these rows.

- [ ] Add a multi-asset fixture asserting one transaction, all signed asset deltas, one separately denominated fee, and correct wallet net effect. Null timestamps sort predictably and do not render 1970; incoming/self-transfer/failed statuses remain distinct.
- [ ] Run focused A/C/F failures; preserve movements before any legacy lossy mapping. Implement localized filters, accessible panel focus restoration, full copyable identifiers, unavailable fields, and separate empty/filter/loading states.
- [ ] Run C/A/G/H/F/M as touched; verify TEST activity never presents L-BTC fee as TEST or counts it twice.
- [ ] Commit: `feat(wallet): preserve multi-asset activity in desktop history`.

### Task 13: Add validated node settings and preferences

**Files:** Extend host `session/settings.rs`, session connection configuration, commands/DTOs; facade `dto/config.rs`/wallet initialization where necessary; frontend `features/settings/{network-page.tsx,display-page.tsx,network-page.test.tsx}`.

**Interfaces:** `testNode(chain: Chain, endpoint: string): Promise<NodeCheck>`; `saveNode(chain: Chain, endpoint: string | null, publicFallback: boolean): Promise<DesktopSettings>`; `saveDisplay(locale: string, bitcoinUnit: string, privacy: boolean): Promise<DesktopSettings>`. Testnet validation requires chain/network evidence, not merely an open TCP port.

- [ ] Assert invalid/wrong-chain nodes do not persist; failed connection retains previous settings; explicit fallback=false never contacts public nodes. A successful switch cannot expose a mixed old/new snapshot or race a prepared send.
- [ ] Run focused H/F failures; implement probe-before-save, serialized runtime reconfiguration, review invalidation, rollback, defaults restoration, and persisted display settings. Resolve current core implicit fallback behavior in the native config path without changing mobile defaults.
- [ ] Run H/A/F/M for shared config changes; inspect three locales and BTC/sat versus fixed TEST units.
- [ ] Commit: `feat(desktop): configure testnet nodes and display preferences`.

### Task 14: Add redacted diagnostics and recoverable local removal

**Files:** Create host `diagnostics.rs`; extend `session/security.rs` and settings; frontend `features/settings/{about-page.tsx,remove-wallet-dialog.tsx,remove-wallet-dialog.test.tsx}`; host isolated storage tests.

**Interfaces:** `diagnostics(): Promise<DiagnosticReport>` returns an allowlisted version/chain-health/error-code report without credentials, addresses, txids, or raw provider text; native export uses a specific user-selected destination. `removeWallet(pin: string): Promise<void>` owns scoped reauthentication, runtime stop, revocation, and wallet namespace cleanup.

- [ ] Assert diagnostic serialization contains no seeded secret/identifier values. Fault-inject deletion after partial cleanup; assert explicit failure and safe retry, with unrelated credential items untouched.
- [ ] Run focused H/F failures; implement cleanup progress metadata sufficient for retry after restart, clear UI caches, and pending/uncertain-send warning. Never imply removal cancels a network transaction.
- [ ] Run H/F and isolated native cleanup; test export cancellation and failed destination writes.
- [ ] Commit: `feat(desktop): add safe diagnostics and wallet removal`.

### Task 15: Complete interactive and regression verification

**Files:** Update feature tests for discovered defects; create `docs/testnet-polish-validation.md`; extend `apps/desktop/src-tauri/tests/native_smoke.rs` with isolated non-broadcast lifecycle checks.

- [ ] Run F/H/A/C, generated freshness checks, and M; record actual commands/results. Fix failures in focused commits before continuing.
- [ ] Build debug native app with `npm exec -w @mooze/desktop -- tauri build --debug --bundles app`. Run the isolated native smoke test using its explicit ignored-test command from `docs/desktop-mvp.md`.
- [ ] Inspect each screen at 1024×700 and 1440px in pt-BR/en/es; cover keyboard focus, panel/dialog return focus, privacy, error/empty/loading, reduced motion, and long asset IDs. Record screenshots without secrets.
- [ ] Exercise offline/reconnect, one chain failure, stale balance/history, node switching, first sync, timeout/suspend, and restart with unresolved send using isolated fixtures/profiles. Record observed results, not assumed passes.
- [ ] Commit validation evidence and focused corrections: `test(desktop): validate polished testnet wallet flows`.

### Task 16: Funded testnet acceptance and milestone record

**Files:** Update `docs/testnet-polish-validation.md` and `docs/desktop-mvp.md` with the new capability/limitation record; no unrelated documentation rewrite.

- [ ] Prepare dedicated disposable test wallets and confirm access to BTC, L-BTC, and the exact TEST asset. If funds are unavailable, ask for a test-funding source; do not substitute a different asset or claim completion.
- [ ] Within the user's authorized test-wallet scope, perform receive/send checks for each supported asset, including TEST with L-BTC fee accounting, Max, review, history, and confirmation. Record public transaction IDs and amounts from these test wallets only.
- [ ] Compare GUI results with observed chain confirmations; record any broadcast uncertainty honestly. Never retry an uncertain send automatically.
- [ ] Update milestone documentation with verified platform/build, command results, screenshots, transaction evidence, and unresolved limitations. Mainnet and distribution remain separate milestones.
- [ ] Commit: `docs: record polished wallet testnet acceptance`.

## Plan self-review and handoff

Coverage: shell/home/assets → 1–4; setup/recovery/locking → 5–8; receive/send/results/history → 9–12; nodes/display/diagnostics/removal → 13–14; behavioral/native/funded verification → 15–16. Every Review Focus item has a named owner/test. Generated clients and frozen bridge compatibility apply whenever shared types change.

The plan does not authorize using personal credentials or mainnet funds. External TEST funding and real network availability can block Task 16 without blocking earlier implementation. Report that dependency instead of marking funded validation complete.

Execution recommendation: **native execution**, implementing sequentially in this session, because these tasks share DTOs, session state, and transaction semantics. Perform independent whole-branch review before completion under the chosen execution workflow. The alternative is subagent-driven execution with task-level independent reviews; it carries more coordination overhead but offers earlier independent review. User reviews this plan and chooses the method before product implementation.
