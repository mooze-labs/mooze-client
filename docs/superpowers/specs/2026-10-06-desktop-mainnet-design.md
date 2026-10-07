# Desktop mainnet, Pix, and swaps

## Outcome and scope

Extend the existing React/Tauri desktop wallet with mainnet support, Mooze backend authentication, Pix deposits, and Liquid asset swaps using `mooze-app` and `mooze-core`.

Mainnet is the default desktop build. A Cargo feature named `testnet` selects a testnet-only desktop build. There is no runtime network switch and no multi-wallet management in this release. Network selection is immutable for a running process.

Pix means the deposit functionality already exposed by the facade: create a BRL payment request, display its QR code and copyable payment code, track settlement, and show deposit history. Swaps mean SideSwap Liquid asset swaps with quote, review, execution, and result screens. Bitcoin/Liquid pegs are a separate workflow and are outside this initial scope.

## Network and storage

Introduce one desktop build-network definition consumed by session creation, credential loading, node validation, payment parsing, asset metadata, explorer links, and host information. The frontend obtains network and feature availability from Rust rather than maintaining a second network setting.

Default app branding and bundle identity become mainnet-specific. A testnet Tauri configuration overlay retains the existing testnet identity and branding. Document and script the paired Cargo-feature/configuration build commands, and reject mismatched packaged network identities during the build.

Mainnet uses a separate application data location and OS credential service. Testnet preserves the existing data directory and `app.mooze.desktop.testnet` credential service. No existing testnet mnemonic, PIN, tokens, node settings, or transaction data are copied to mainnet. Existing debug validation profiles remain testnet-only.

Generalize the facade's desktop asset metadata and holdings helpers to accept network explicitly. Preserve existing testnet helpers where needed for compatibility. Mainnet metadata comes from the core's canonical asset IDs and precision; unknown assets remain visible without being implicitly approved for spending. Validate custom node genesis against the selected network.

## Architecture

React screens call a typed desktop client. Tauri exposes narrow commands guarded by `WalletSession`. Those commands call the host-neutral `App` facade, which uses core services through platform ports. No frontend backend HTTP client, token handling, or transaction signing is introduced.

Keep amount conversion, capability decisions, and view-state transitions as pure functions. Keep storage, network calls, and event delivery at explicit boundaries. Add focused desktop session modules for backend status, Pix, and swaps rather than expanding the central session file with every flow.

## Authentication

After wallet unlock, establish the Mooze session using `auth_ensure_session`; let the core sign challenges and refresh tokens. Tokens remain in the selected build's OS credential namespace. Expose only authentication/service status to React.

Backend unavailability must not prevent on-chain wallet use. The UI offers retry for backend-dependent actions and reports errors without displaying credentials or tokens. Lock, wallet removal, and session replacement invalidate in-memory operation authority and stop background service work; wallet removal also clears the selected wallet's stored backend credentials.

## Pix UI and lifecycle

Add a Pix navigation destination with a deposit form and history. Use exact BRL cent conversion, the facade's supported asset identities, and required payer CPF/CNPJ validated by the core. Create the deposit for the connected wallet's address; do not accept arbitrary payout addresses from this UI.

Display the returned payment code, QR, amount, expiry, and status. Disable duplicate submissions while creation is pending. Handle uncertain creation outcomes without automatically creating another deposit. Refresh nonterminal history through session-guarded facade calls while the Pix screen is open and when returning after unlock or restart. Desktop starts chain synchronization without the facade’s independent Pix loop so every backend continuation remains subject to desktop session cancellation; mobile keeps its existing runtime behavior. Present payment receipt and asset settlement according to actual core statuses, without treating a generated payment code as a successful deposit.

Production Pix is unavailable in testnet builds unless an explicit supported test environment is added later. The frontend receives this capability from Rust, and commands enforce it as well.

## Swap UI and lifecycle

Connect SideSwap through the Rust facade using the public application key embedded in mobile by default, with native build/runtime overrides. An explicitly empty override disables swaps without disabling the wallet. The frontend never receives the key.

Present supported Liquid markets, source/destination assets, exact input amount, live quote, fees supplied by the provider, and the resulting receive amount. Quote updates arrive through core events. Bind review authority to the active session and current quote. A changed or expired quote requires a fresh review.

On explicit confirmation, Rust validates the reviewed quote and session before signing and submission. Extend the facade/core authorization boundary if required to prevent a lock occurring during preparation from allowing subsequent signing. Permit only one spending submission at a time across sends and swaps. Persist enough operation state to show pending or uncertain outcomes after restart, and never automatically resubmit an uncertain swap.

Stop quote subscriptions when leaving the flow or locking. Retain transaction/result information needed for recovery. Testnet builds must not connect to the production SideSwap service; swaps remain unavailable there unless a supported test configuration is explicitly provided.

## UI integration

Reuse the existing shell, shadcn/Base UI inputs, selects and buttons, amount formatting, privacy mode, notices, and translations. Use a traditional stacked send/receive swap form with local asset icons and a direction switch; reversal clears the old amount and quote. Replace hardcoded testnet labels with host-provided network identity. Add Pix and swap entry points, backend connection status, loading/error/empty states, review screens, and results. Preserve the existing receive/send/asset/history flows on both compiled networks.

## Verification

- Rust tests for both default and `testnet` builds: network selection, storage namespace separation, correct asset catalogs and precision, payment/network validation, and preservation of existing testnet behavior.
- Mock-backed integration tests for authentication failure/retry, Pix creation and status recovery, quote replacement, lock during preparation, duplicate confirmation, and uncertain submission handling.
- Frontend tests for exact amount handling, network/capability rendering, Pix payment/status views, swap review invalidation, and session cleanup.
- Run frontend typecheck, tests, and production build; run applicable facade/core/desktop tests and formatting checks.
- Inspect the new screens in the available local preview/native environment. Do not create real Pix orders or broadcast mainnet transactions as part of automated verification.

## Configuration to document

Document mainnet and testnet development/build commands, storage identities, the Mooze API URL configuration, and SideSwap API-key configuration. Use existing core endpoint defaults where available; do not invent provider endpoints or embed credentials. A missing external service configuration must be visible as an unavailable capability.
