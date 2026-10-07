# Desktop wallet

The desktop client uses Tauri 2, React, and the host-neutral `mooze-app` facade over `mooze-core`. Mainnet is the default build. Cargo feature `testnet` selects a separate testnet-only application; there is no runtime network switch.

## Run and build

Install the Rust toolchain, Node 22+, npm, and Xcode command-line tools on macOS, then run from the repository root:

```sh
npm ci
npm run desktop:dev
npm run desktop:build
```

For browser-only visual work, use the [synthetic desktop preview](../apps/frontend/src/testing/PREVIEW.md). It runs the real screen components with in-memory fixtures and no native wallet access. See the [composition report](superpowers/plans/2026-10-07-desktop-wallet-redesign.md) and [account/chart implementation notes](superpowers/plans/2026-10-07-desktop-account-and-charts.md) for the current UI changes and validation boundaries.

Testnet keeps the previous bundle identity and wallet storage:

```sh
npm run desktop:dev:testnet
npm run desktop:build:testnet
```

The testnet scripts pair Cargo's `testnet` feature with `apps/desktop/src-tauri/tauri.testnet.conf.json`. Direct Cargo test/codegen builds automatically select that overlay when no `TAURI_CONFIG` is supplied. An explicitly mismatched identifier is rejected by the build script. Do not use `--all-features` to build a production application: it selects testnet too.

Bundles appear under `apps/desktop/src-tauri/target/{release,debug}/bundle/macos/`. For faster local bundle checks, use `npm exec -w @mooze/desktop -- tauri build --debug --bundles app` (add the testnet feature and overlay for testnet). Distribution signing, notarization, updater delivery, Windows, and Linux remain separate verification work.

## Network and storage isolation

| Build | Tauri identifier / OS credential service | Data suffix |
| --- | --- | --- |
| Mainnet (default) | `app.mooze.desktop` | `mainnet/wallet.json` |
| Testnet | `app.mooze.desktop.testnet` | `testnet/wallet.json` |

Data paths are relative to each identifier's Tauri app-data directory. Testnet paths and the existing `wallet-secrets` credential item are preserved. Mainnet does not import or copy existing testnet credentials. Each build imports or creates its own wallet and uses a six-digit PIN. Mnemonics, PIN hashes, backend tokens, nodes, and activity stay in their own namespaces. `MOOZE_TESTNET_PROFILE` is restricted to debug testnet builds.

The core supplies chain endpoints, address validation, Liquid policy identity, and asset precision. Mainnet supports BTC, L-BTC, DEPIX, and USDT; testnet retains BTC, L-BTC, and the existing TEST asset. Unknown assets stay visible with their identity and raw units. Custom Electrum nodes must report the selected chain's genesis hash.

## Backend, Pix, and swaps

React calls only typed Tauri commands. Authentication and financial operations go through Rust. Backend sign-in uses the wallet's challenge signature via `auth_ensure_session`; JWT/refresh tokens stay in OS credential storage. A backend outage does not prevent on-chain wallet use. The backend status offers a retry.

- `MOOZE_BACKEND_API_URL`: optional HTTPS backend override, read by the native process. Omission uses the core default. Changing the configured backend invalidates stored backend tokens before authentication.
- SideSwap defaults to the same public application API key embedded in mobile. `SIDESWAP_API_KEY` optionally overrides it at native runtime or build time (runtime takes precedence). An explicitly empty override disables swaps. The key stays in native configuration and is not returned to React.
- Pix and SideSwap production operations are disabled in testnet builds. No test payment-service endpoint is invented.

Pix accepts exact BRL cents and a **required, valid payer CPF/CNPJ**. Rust validates the taxpayer ID before creating a deposit to the connected Liquid wallet. The UI displays the returned QR/copy code, expiry from the core's polling rule, payment/settlement status, and local deposit history. While the Pix screen is open, history refreshes nonterminal deposits through session-guarded core calls; returning to the screen refreshes stored deposits again. Desktop starts chain synchronization without the facade's independent Pix loop, so backend authentication stays within native session cancellation. A payment received status does not imply asset settlement.

A failed creation response is retained as uncertain, since the backend may have accepted the request. Automatic retry cannot create another deposit. The user can explicitly acknowledge having checked the previous request before creating another. The existing facade has no backend-wide deposit discovery/idempotency API: a lost creation response without a stored deposit ID cannot be recovered from local history alone.

Swaps use the core's supported Liquid markets, quote stream, and PSET signing. Rust normalizes direction and fee denomination, stores a single-use review ID, and checks session authority and quote lifetime again before signing and submission. Review authority expires at the provider TTL or 60 seconds, whichever is sooner. Changing inputs invalidates UI confirmation immediately. Sends and swaps share spending exclusion and check each other's durable submission records.

An interrupted or lost swap submission response stays uncertain across restart. The application does not automatically repeat it or allow an unresolved swap journal to be dismissed as success. Check wallet activity before resolving an uncertain financial operation; no automated reconciliation is claimed for a swap whose txid was never returned.

## Session lifecycle

PIN retry delays remain persisted. Locking revokes authorization immediately and clears wallet UI caches, then stops the application runtime and SideSwap connection. Idle expiry performs the same cleanup from the native tick. Unlock reconnects with a fresh event subscription bound to the new generation. Obsolete events cannot update new session state. Wallet removal serializes against Pix, swaps, and backend authentication before clearing that wallet's namespace.

## Verification

```sh
npm run frontend:test
npm run frontend:typecheck
npm run frontend:build
cargo test --locked --manifest-path crates/mooze-core/Cargo.toml
cargo test --locked --manifest-path crates/mooze-app/Cargo.toml
cargo test --locked --manifest-path apps/desktop/src-tauri/Cargo.toml --features codegen
cargo test --locked --manifest-path apps/desktop/src-tauri/Cargo.toml --features codegen,testnet
cargo check --locked --manifest-path packages/mooze_core_bridge/rust/Cargo.toml
```

Regenerate desktop DTOs with `npm run codegen -w @mooze/desktop`. Facade types remain compatible with the Flutter bridge. The desktop CI matrix tests both network builds on macOS. WebSocket unit tests require permission to bind localhost test sockets.

Public testnet smoke tests are feature-gated and explicitly opt-in; they do not submit transactions:

```sh
cargo test --manifest-path apps/desktop/src-tauri/Cargo.toml --features testnet --test native_smoke -- --ignored --nocapture
```

See [mainnet integration validation](desktop-mainnet-validation.md) for this change's checks and limitations. Earlier validation records below describe previous testnet increments, not evidence of current mainnet transactions.

## Validation record — 2026-10-06

Environment: macOS arm64, Rust 1.98.0, Node 22.12.0; Tauri 2.12.1, React 19.3.0 (exact dependencies and lockfiles committed with the source).

- Shared core native-feature suite: 321 passed, 1 pre-existing ignored test, plus the golden migration fixture; existing mainnet/address fixtures remain unchanged.
- Facade: 30 unit tests, golden migration, and generated binding freshness passed.
- Frozen Flutter bridge compiled; all 679 mobile tests passed.
- Desktop host: 18 tests passed, including storage failure recovery, lock races, independent chain health, one-use reviews, safe integers, and persisted unresolved sends.
- Frontend: 15 tests passed; TypeScript and production bundle passed. Frontend JS is approximately 426 kB (132 kB gzip), plus bundled fonts/CSS.
- A real debug macOS `.app` was built (106.82 MiB) and its locked window inspected. This is an unoptimized debug artifact, not a release-size measurement.
- The isolated native smoke test passed using the actual Keychain and configured public testnet servers: import/persistence about 0.80 seconds; receive addresses for both chains; locked restart and PIN unlock; both chains successfully synced by 8.44 seconds. These are one local debug run, not a performance benchmark or a cold webview-launch measurement.

![Actual macOS wallet lock screen](images/desktop-native-lock.png)

The normal app profile already contained a locked wallet, so its credentials and balances were not used for verification. The native smoke test used a separate random wallet and disposable credential item. A complete interactive walkthrough of the unlocked screens, minimum-window visual QA, offline/reconnect GUI behavior, and funded network broadcasts/confirmations remain unverified. No transaction ID or confirmed-send claim is recorded. The offline funded Liquid fixture verifies confidential transaction construction/signing, testnet policy identity, exact/exceeded fee limits, revoked authorization, and uncertain broadcast classification. Unit tests and local signing fixtures are not substitutes for funded public-chain checks.

## Polished testnet validation

The expanded wallet UI and final review findings are recorded in
[testnet-polish-validation.md](testnet-polish-validation.md). Funded checks now use
an opt-in [Nigiri regtest harness](../tools/wallet-regtest/README.md) on OrbStack.
This exercises shared wallet mechanics without changing the approved public
TEST asset or claiming mainnet/distribution readiness.

## Everyday wallet UI validation

See [the Quiet Navy implementation and validation report](everyday-wallet-validation.md) for current frontend changes, native observations, independent review fixes, and remaining acceptance gaps.
