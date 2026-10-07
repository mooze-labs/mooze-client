# Desktop Mainnet Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox syntax for tracking.

**Goal:** Deliver a mainnet desktop wallet with native backend authentication, Pix deposits, and Liquid swaps, retaining testnet through a compile-time feature.

**Architecture:** React consumes narrow typed Tauri commands; `WalletSession` owns authorization and lifecycle; `mooze-app` and `mooze-core` own wallet and service operations. A single immutable build-network definition selects endpoints, asset metadata, storage, and capabilities. Pure conversion and transition functions sit alongside explicit I/O boundaries.

**Tech Stack:** Existing Rust, Tauri 2, React, TypeScript, React Query, Vitest, native credential storage, and core HTTP/WebSocket ports. No new provider SDK.

**Spec:** `docs/superpowers/specs/2026-10-06-desktop-mainnet-design.md`

## Global Constraints

- Mainnet is the default desktop build; Cargo feature `testnet` selects testnet only.
- No runtime network switching or multi-wallet UI.
- Preserve the existing testnet bundle identity, data location, and credential service; never copy its secrets into mainnet.
- Backend authentication, signing, and provider calls remain in Rust. Tokens and API keys never enter React.
- Testnet cannot invoke production Pix or SideSwap operations.
- Reuse existing components, translations, and pure amount conversion patterns. Keep existing mobile facade callers compatible.
- Do not create real Pix orders or broadcast mainnet transactions during verification.
- Leave unrelated working-tree changes, including `apps/mobile/ios/Podfile.lock`, untouched.

## Review Focus

- Existing testnet installations must reopen their original wallet after a testnet build update: Task 1 migration-path assertions.
- Inverse SideSwap markets must preserve source/receive units and fee denominations: Tasks 5–6 inverse-market assertions.
- Late events after locking/reconnecting must not become valid in a new session: Tasks 3 and 5 lifecycle assertions.
- Lost provider responses must not trigger duplicate spending or automatic Pix creation: Tasks 4–6 uncertainty assertions.
- Amounts above JavaScript's safe integer boundary must not silently round: Tasks 2, 4, and 5 string-serialization assertions.

## Delivery order

Tasks 1–2 produce a usable mainnet/testnet on-chain desktop client. Task 3 provides the backend lifecycle required by Task 4. Tasks 5–6 add swap authorization and UI on the same session boundary. Task 7 verifies their integration. Execute sequentially because the session and generated command interfaces are shared.

### Task 1: Compile-time network and isolated application identities

**Files:** Create `apps/desktop/src-tauri/src/network.rs` and `apps/desktop/src-tauri/tauri.testnet.conf.json`. Modify desktop `Cargo.toml`, `build.rs`, `tauri.conf.json`, `src/lib.rs`, `src/platform/mod.rs`, `src/commands.rs`, `src/dto.rs`, desktop/root `package.json`, and `docs/desktop-mvp.md`.

**Interfaces:** `network::app_network() -> AppNetwork`, `network::network_dto() -> NetworkDto`, `network::data_directory() -> &'static str`, `network::credential_service() -> &'static str`, and `network::production_services_enabled() -> bool`. Extend `HostInfoDto` with `pix_enabled: bool` and `swaps_enabled: bool`; keep its existing network field.

- [ ] Add failing tests in `network.rs` and platform tests: default selects mainnet and `app.mooze.desktop`; testnet selects `AppNetwork::Testnet`, data suffix `testnet`, and `app.mooze.desktop.testnet`; neither mainnet path nor credential service equals testnet's. Debug validation profiles fail outside testnet builds.
- [ ] Run `cargo test --manifest-path apps/desktop/src-tauri/Cargo.toml --lib network` and repeat with `--features testnet`; confirm missing-feature/interface failures.
- [ ] Implement feature selection and platform namespace construction. Default bundle ID is `app.mooze.desktop`; the overlay preserves `app.mooze.desktop.testnet`. Keep the existing testnet app-data-root plus `testnet` suffix unchanged.
- [ ] Add build scripts that pair `--features testnet` with the testnet configuration overlay. Validate the effective Tauri bundle identifier against the Cargo network selection in `build.rs`, using the effective configuration rather than only the base JSON. Keep codegen/test invocations compatible with the documented testnet configuration mechanism.
- [ ] Rerun both network test variants and verify mismatched bundle/feature configuration fails with an actionable build error. Document exact supported commands and commit only this task's files.

### Task 2: Mainnet on-chain flows and asset metadata

**Files:** Modify `crates/mooze-app/src/assets.rs`, `src/app/wallets.rs`; `crates/mooze-core/src/wallet/backend.rs`; desktop `src/session.rs`, `src/session/{payments,settings,security}.rs`, `src/send_review.rs`, `src/diagnostics.rs`, and command/codegen tests. Modify frontend network labels in `src/app/shell.tsx`, setup/dashboard/settings/send/history features and their tests.

**Interfaces:** Add `assets::asset_metadata(network: NetworkDto, key: &AssetKeyDto) -> AssetMetadataDto`, `approved_assets(network: NetworkDto) -> Vec<AssetMetadataDto>`, `holding_for_network(network: NetworkDto, balance: &AssetBalanceDto) -> HoldingDto`, and `include_historical_assets_for_network(network: NetworkDto, rows: Vec<HoldingDto>, keys: impl IntoIterator<Item = AssetKeyDto>) -> Vec<HoldingDto>`. Existing testnet helpers delegate to these. Add `validate_genesis(chain: ChainId, network: AppNetwork, genesis: &str) -> mooze_core::Result<()>` and `probe_node(chain: ChainId, network: AppNetwork, url: &str, config: &ElectrumConfig) -> mooze_core::Result<String>`; preserve old testnet wrappers.

- [ ] Add failing tests for canonical mainnet BTC/L-BTC/DEPIX/USDT identities and core precisions, rejection of wrong-chain/genesis/address inputs, unknown historical assets, and exact string balance `9007199254740993`. Verify a DEPIX debit and L-BTC fee remain separate units on mainnet.
- [ ] Run `cargo test --manifest-path crates/mooze-app/Cargo.toml` and focused desktop payment/review tests; confirm new assertions fail on existing testnet assumptions.
- [ ] Implement network-aware metadata/holdings and remove the facade's mainnet holdings rejection. Route every desktop credential, node, payment, fee-policy, explorer, and app configuration decision through Task 1's network definition. Pass network explicitly into review construction rather than embedding a policy asset constant.
- [ ] Regenerate desktop types through its existing codegen command. Update frontend labels and test doubles from host information, retaining testnet banners only for testnet. Gate live testnet acceptance tests behind the testnet feature; ensure no default test connects to mainnet.
- [ ] Run facade/core affected tests, both desktop build variants, `npm run frontend:typecheck`, and `npm run frontend:test`. Commit this independently usable mainnet wallet increment.

### Task 3: Backend authentication and service lifecycle

**Files:** Create desktop `src/session/backend.rs`; modify `src/session.rs`, `src/session/security.rs`, `src/commands.rs`, `src/lib.rs`, `src/dto.rs`, `src/bin/codegen.rs`, and `src/session/tests.rs`. Extend frontend `src/core/{client,tauri}.ts`, `src/testing/client.ts`, and `src/app/session-provider.tsx`; add `src/features/dashboard/backend-status.tsx` and tests.

**Interfaces:** Native `ServiceConfig { api_base_url: Option<String>, sideswap_api_key: Option<String> }` loads `MOOZE_BACKEND_API_URL` and `SIDESWAP_API_KEY` in Rust. `BackendSessionDto { state: BackendSessionState, retryable: bool }` uses states `Disabled`, `Connecting`, `Ready`, `Unavailable`. Commands `backend_status() -> Result<BackendSessionDto>` and `backend_retry() -> Result<BackendSessionDto>`; frontend methods `backendStatus()` and `backendRetry()` return generated DTOs.

- [ ] Add mocked tests showing unlock/on-chain snapshot succeeds when authentication fails; retry uses `auth_ensure_session`; serialized UI output contains neither JWT nor refresh token; lock during authentication discards its late result. Verify wallet removal clears stored auth data only in its own namespace.
- [ ] Run the new desktop backend tests and confirm failure before implementation.
- [ ] Implement session-owned authentication work, passing the backend URL through `AppConfig`. Validate configured backend URLs; scope stored tokens to their backend origin so an override never reuses production credentials. Coalesce concurrent retries. Use existing core refresh behavior rather than a second token manager.
- [ ] Capture the originating generation when registering an event sink. Reject callbacks from obsolete generations before updating cached sync/service state or forwarding events. Stop backend/service work on lock/removal/reconfiguration. Keep status queries under the frontend's existing wallet-generation query prefix.
- [ ] Add backend status/retry UI and all three locale translations. Test unavailable-to-ready retry and stale event rejection; rerun desktop lifecycle and frontend session tests, regenerate DTOs, and commit.

### Task 4: Pix deposit commands, recovery, and screens

**Files:** Create desktop `src/session/pix.rs` and frontend `src/features/pix/{pix-page,pix-form,pix-payment,pix-history}.tsx`, `pix-state.ts`, and corresponding tests. Modify desktop commands/DTO/codegen registration, frontend client/testing adapter/shell/translations, and `crates/mooze-app/src/app/pix.rs` only for missing facade recovery behavior.

**Interfaces:** `PixCreateRequestDto { amount_in_cents: String, asset_id: String, tax_id_number: String }`. `PixDepositViewDto` mirrors existing `PixDepositDto` but transports monetary integers as decimal strings and adds `expires_at_ms: Option<u64>`. Commands `pix_create(request) -> Result<PixDepositViewDto>` and `pix_history() -> Result<Vec<PixDepositViewDto>>`; frontend `pixCreate(request)` and `pixHistory()`.

- [ ] Add failing native tests for testnet denial, invalid/nonintegral/overflow BRL cents, invalid CPF, unsupported asset, and duplicate in-flight creation. Assert no arbitrary payout address is accepted. Add timeout/restart tests proving automatic retries never create a second deposit.
- [ ] Run Pix-focused native tests and verify failures on absent commands.
- [ ] Implement commands using `pix_create_deposit` with address `None`, core tax-ID/amount rules, and authenticated service state. Convert cents to core integer types only after bounds checks. Return exact amount strings; derive expiry only from an authoritative core/provider rule and otherwise expose `None`.
- [ ] Persist a creation-attempt marker before the request. A lost response remains uncertain and exposes history/retry-status guidance, not automatic recreation. Poll through facade runtime and refresh nonterminal persisted deposits after unlock/restart; keep UI status changes distinct from final asset settlement.
- [ ] Build `/pix` with exact locale-aware BRL entry, supported asset selector, required CPF/CNPJ field, QR/copy code, expiry when known, status, and history. Reuse `qrcode.react`. Test payment creation, copy payload, pending-to-settled/refund/unknown states, timeout messaging, privacy, and navigation away/back without duplicate requests.
- [ ] Run mocked facade Pix tests, native Pix tests, frontend Pix tests/typecheck, and codegen. Commit the complete Pix flow.

### Task 5: Authorized swaps and durable submission state

**Files:** Modify `crates/mooze-core/src/sideswap/swap.rs`, `crates/mooze-app/src/{glue.rs,app/swap.rs}`. Create desktop `src/session/swaps.rs`, `src/swap_review.rs`, `src/submission.rs`; modify desktop session/send command integration, DTO/codegen, and tests.

**Interfaces:** Add an explicit authorization callback to the core swap signing path, with the existing API delegating compatibly. Facade `sideswap_execute_swap_authorized(quote_id: u64, authorize: impl Fn() -> mooze_core::Result<()> + Send + Sync + 'static) -> Result<String>` checks authority after preparation/credential access and while holding the Liquid signing lock, then again before submission. Native DTOs: `SwapRequestDto { send_asset_id: String, receive_asset_id: String, amount_units: String }`; `SwapReviewDto { id: String, generation: u32, send_asset_id: String, receive_asset_id: String, send_units: String, receive_units: String, fees: Vec<AssetAmountDto>, expires_at_ms: u64 }`; `SwapStateDto { phase: SwapPhase, review: Option<SwapReviewDto>, txid: Option<String>, message: Option<String> }`, with phases `Unavailable`, `Idle`, `Quoting`, `Review`, `Submitting`, `Succeeded`, `Failed`, `Uncertain`.

Commands: `swap_start(request) -> Result<SwapStateDto>`, `swap_status() -> Result<SwapStateDto>`, `swap_stop() -> Result<()>`, `swap_confirm(review_id: String) -> Result<SwapStateDto>`. Raw provider quote IDs stay native.

- [ ] Add core/facade mock tests proving a revoked callback after PSET fetch or while waiting for the wallet lock prevents signing/submission. Add native tests for testnet/missing-key denial, quote TTL expiry, subscription mismatch, stale generation, inverse market amounts/fee denominations, and replacement quote invalidation.
- [ ] Run focused swap tests and verify failures before adding the authorized path.
- [ ] Implement the callback path compatibly through `SwapSigner` and `LiquidPort`. Keep authorization after all awaited preparation steps and immediately adjacent to synchronous signing; do not hold a synchronous mutex across network I/O.
- [ ] Implement a native review book with one current reviewed quote, generation binding, provider TTL plus a 60-second maximum measured with a monotonic clock, and single-use opaque review IDs. A new quote invalidates the prior review. Map all provider amounts/IDs to lossless native state; emit only string amounts to React.
- [ ] Share one spending exclusion and durable submission journal between sends and swaps. Preserve/interpret the existing send journal format. Persist intent before submission, retain txid when known, and restore interrupted submissions as uncertain. Timeouts/disconnects after signing cannot be treated as definite failures or automatically retried. Acknowledge UI results separately from resolving spend uncertainty.
- [ ] Test concurrent send/swap confirmation admits only one, duplicate review confirmation has no second submission, restart restores uncertainty, and stop/lock tears down subscriptions without erasing a submitted operation. Run core/facade and desktop regression suites; commit.

### Task 6: Swap UI and event handling

**Files:** Create frontend `src/features/swap/{swap-page,swap-form,swap-review,swap-result}.tsx`, `swap-state.ts`, and tests. Modify `src/core/{client,tauri}.ts`, `src/testing/client.ts`, `src/app/{shell,session-provider}.tsx`, locales, and desktop typed event forwarding.

**Interfaces:** Frontend `swapStart(request)`, `swapStatus()`, `swapStop()`, and `swapConfirm(reviewId)` mirror Task 5. Add a generation-tagged `swap` event with `SwapStateDto`; queries remain under `['wallet', generation, 'swap']`. Market/asset options come from a guarded `swap_markets() -> Result<Vec<SideswapMarketDto>>` command and network-approved asset metadata.

- [ ] Add failing UI tests: inverse market preserves selected direction, updated review disables old confirmation, expired TTL requires another quote, disconnect clears an unsubmitted review, and late events after lock cannot restore a screen or enable confirmation.
- [ ] Run `npm run frontend:test -- --run src/features/swap` and confirm missing-flow failures.
- [ ] Implement source/destination selectors, exact base-unit amount conversion, balance feedback, live quote, fee breakdown, confirmation, and result views. Use native normalized review values and availability rather than trusting raw provider events in React.
- [ ] Cancel quoting on unmount/lock; keep submitted outcomes in session state. Disable duplicate actions, show uncertain results without a retry-spend button, and link known txids using the selected network's explorer. Add `/swap`, dashboard entry points, locale strings, privacy support, and absent-key/testnet explanations.
- [ ] Run frontend swap/session/send tests, typecheck, and build. Commit the integrated swap UI.

### Task 7: Build matrix, native checks, and documentation

**Files:** Update `docs/desktop-mvp.md`, `README.md`, relevant existing CI workflow(s), and desktop native smoke/acceptance tests. Add `docs/desktop-mainnet-validation.md` with observed results and limitations.

- [ ] Run `cargo fmt --manifest-path crates/mooze-core/Cargo.toml -- --check`, repeat for facade and desktop, and resolve formatting only in touched files.
- [ ] Run `cargo test --manifest-path crates/mooze-core/Cargo.toml`, `cargo test --manifest-path crates/mooze-app/Cargo.toml`, and desktop tests using both documented network build configurations. Keep live acceptance tests explicitly opt-in and testnet-only.
- [ ] Run `npm run frontend:typecheck`, `npm run frontend:test`, and `npm run frontend:build`; verify regenerated DTOs have no unexplained drift.
- [ ] Build both native variants with their paired bundle configurations. Inspect setup, unlock, assets/send/receive, backend outage, Pix QR/history, swap quote/review/uncertainty, and lock cleanup in local preview/native tooling using mocks or isolated test profiles. Record anything the environment prevents verifying.
- [ ] Document configuration names, default endpoints inherited from core, testnet feature commands, namespace preservation, missing-key behavior, and supported Pix/swap scope. Add CI matrix coverage using the repository's existing workflow conventions, without adding service credentials.
- [ ] Review the full diff against the approved spec and test evidence. Confirm no unrelated edits or credentials are included; commit documentation and validation changes.

## Plan self-review

Network isolation and compatibility are covered by Tasks 1–2; authentication and event lifecycle by Task 3; Pix recovery by Task 4; signing authority and submission recovery by Task 5; user flows by Task 6; build/configuration documentation and native verification by Task 7. Backend capability/configuration fields stay native except for nonsecret status. Financial amounts crossing newly added command boundaries are strings. Existing mobile APIs retain compatibility wrappers. No real-money operation is required to validate this plan.

## Execution record

Implemented natively in the supplied checkout. See [validation results](../../desktop-mainnet-validation.md) and the session ledger for observed tests and review fixes. No commits were made because the environment marks `.git` read-only; unrelated mobile lockfile edits were preserved.

Implementation refinements: required payer CPF/CNPJ at the desktop JSON boundary and native validator; `PixHistoryDto` includes creation uncertainty; native authenticated Pix refresh uses host session cancellation instead of an independent facade poll loop; mobile runtime remains unchanged. Existing shadcn components and local token artwork back the stacked swap form and direction switch.
