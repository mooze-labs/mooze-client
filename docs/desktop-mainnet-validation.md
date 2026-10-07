# Desktop mainnet implementation validation

Validated locally on macOS arm64, 2026-10-06. These checks use mocks and local fixtures; they do not establish real provider acceptance or mainnet settlement.

## Implemented scope

- Mainnet is the default native build. The `testnet` Cargo feature selects separate bundle, data, and OS credential namespaces while preserving existing testnet storage.
- On-chain metadata, payment parsing, addresses, node probes, balances, and reviews use the selected network.
- Backend challenge authentication and token storage remain in Rust. Session transitions invalidate callbacks and cancel authenticated command continuations; queued OS credential writes remain serialized after cancellation.
- Pix distinguishes completed refunds from refunds in progress, requires a checksum-valid CPF/CNPJ and exact BRL cents. It pays the connected wallet, stores returned deposits, displays QR/copy code and history, and preserves ambiguous creation without automatic recreation. Concurrent create calls are rejected.
- Swaps use native market discovery, quote normalization, exact units, fee denomination, expiring one-use reviews, signing authorization, and durable submission results. Unresolved sends and swaps block conflicting spending.
- Pix and swap screens use the existing shadcn/Base UI components. Swaps show stacked send/receive panels, local token artwork, balance, asset selection, and reversal. Reversal clears the previous amount and quote.

## Automated checks

- Core: 326 unit tests and one integration fixture passed.
- Frontend: 59 tests across 29 files passed; TypeScript and production Vite build passed.
- Mobile Rust bridge: `cargo check --locked` passed with existing bridge methods unchanged.
- Facade: 40 unit tests, the codegen binary test, and generated-binding freshness passed with `codegen,electrum,http-reqwest`, including the chain-only runtime entry used by desktop.
- Mainnet desktop: 53 tests passed with the final runtime configuration.
- Testnet desktop: 52 tests passed with the final runtime configuration; two live integration checks remain explicitly ignored.
- Both debug macOS bundles built successfully. `Info.plist` confirms `app.mooze.desktop` for `Mooze.app` and `app.mooze.desktop.testnet` for `Mooze Testnet.app`. They are build artifacts, not signed/notarized release validation.
- Rust formatting, `git diff --check`, and desktop generated DTO freshness passed.

Regression coverage includes required payer data at the JSON boundary and in Rust, exact amounts, ambiguous Pix creation across restart, concurrent Pix rejection, obsolete callbacks, authentication continuation after lock, cancellation without a transport wake, cancellation-safe keyring serialization, inverse swap quotes, expiry/replacement/generation rejection, and retained uncertain submissions.

## Visual inspection

Used a temporary local mock preview in Safari, with no provider calls or wallet credentials. Inspected Pix form, required payer entry, fake QR/payment code, amount and pending status; inspected swap panels, local token icons, shadcn asset menu, and reversal clearing the amount. The mock preview and its server were removed after inspection. This was frontend inspection, not a funded native walkthrough.

## Limits

No live Pix order, SideSwap order, mainnet signing/broadcast, confirmation, or refund was performed. Desktop now embeds the same public SideSwap application key as mobile, with optional `SIDESWAP_API_KEY` overrides; release signing/notarization and Windows/Linux builds were not tested here. No live testnet acceptance test was enabled.

The core cannot discover a lost Pix creation response without a stored deposit ID through a backend-wide list or idempotency lookup. An unknown swap without a returned txid has no automatic reconciliation path and remains blocked against resubmission. These recovery limitations are exposed rather than reported as success.

The production frontend emits Vite's existing large-chunk warning. Rust emits a future-compatibility warning for the pinned `proc-macro-error2` dependency.

## Public SideSwap key follow-up — 2026-10-07

Desktop now embeds the same default application key as mobile, while preserving runtime/build override precedence and explicit-empty disabling. Both targeted native configuration tests pass; the default-key test was observed failing before adding the fallback. Rust formatting and diff whitespace checks pass. Packaged bundles were not rebuilt for this configuration-only follow-up.

## UI polish and PR validation — 2026-10-07

The UI follow-up adds dashboard quick actions, consistent receipt layouts, Pix payer/BRL formatting, QR expiry handling, swap quote countdowns and indicative rates, copy feedback, and reduced-motion-aware transitions. USDT is omitted from the Pix selector. New text is available in Portuguese, English, and Spanish.

Fresh PR checks: 66 frontend tests and the production build pass; core has 327 passing unit tests and one passing integration fixture (one live test ignored); facade has 40 passing unit tests plus codegen and binding-freshness tests; the mobile Rust bridge check and Rust formatting pass. Mainnet desktop has 55 passing tests; testnet desktop has 54 passing tests, with two live integration checks ignored. Local WebSocket fixtures require permission to bind localhost sockets.

Visual checks used a temporary Safari preview with synthetic data for the dashboard, Pix form/payment card, compact swap review and keyboard access, and onboarding. Preview files and server were removed. No provider transaction was submitted. Native bundles were not rebuilt after this UI pass.
