# Polished desktop testnet wallet

Date: 2026-10-06. Status: approved for implementation planning by the user's “Go on” after the written-spec review checkpoint. Product implementation follows review of the implementation plan and selection of its execution method.

## Purpose and boundaries

Deliver a complete, polished desktop wallet for Bitcoin testnet3 and Liquid testnet before undertaking mainnet. Users can create or import a wallet, back it up, receive and send supported assets, inspect their holdings and history, configure nodes, and control locking. The product should remain understandable during synchronization, connectivity failures, and interrupted sends.

Retain React in `apps/frontend`, Tauri in `apps/desktop`, the shared `mooze-app` facade, and `mooze-core`. Preserve mobile behavior and the frozen Dart bridge. Follow functional programming approaches: pure rules and state transitions, immutable presentation models, and explicit effect boundaries. Provider-specific implementation belongs behind adapters.

This milestone excludes mainnet, PIX, swaps, pegs, merchant mode, wallet levels/verification, fiat pricing, portfolio performance charts, browser-wallet implementation, hardware wallets, and multiple installed wallets. It has no mainnet switch. Mainnet later requires its own design and validation, not merely changing a network flag.

The existing macOS app is the initial validation target. Windows/Linux support and signing, notarization, installer distribution, and automatic updates are separate release work; do not claim those platforms or distribution paths validated by this milestone.

## Existing foundation and required changes

Sources inspected include `DESIGN.md`, `docs/desktop-mvp.md`, the earlier desktop/web and MVP specifications, desktop `app.tsx`, client/transport, host commands/DTOs/session integration, mobile routes/setup/settings/wallet flows, and shared Rust mnemonic/payment-request/facade APIs.

- Desktop currently imports a wallet, displays BTC/L-BTC balances, sends native assets, shows history, and exposes minimal read-only settings.
- It already has per-chain sync health, session generations, OS credential storage, expiring single-use send reviews, fee bounds, and persisted uncertain-send handling. Preserve these invariants.
- Most desktop screens and session presentation live in `apps/frontend/src/app.tsx`. Extract feature boundaries while expanding functionality.
- Desktop send DTOs currently select a chain, not a Liquid asset. The single `total_sat` cannot describe TEST and L-BTC fee debits together.
- Desktop currently locks on focus loss. Replace this with the agreed timeout behavior.
- Shared Rust already provides mnemonic generation, asset-aware domain requests, and payment URI functionality. Audit and extend their testnet behavior instead of copying mobile logic into React. Existing payment parsing references mainnet asset constants, so TEST support requires explicit compatibility checks.
- Mobile creates 12- or 24-word English BIP39 phrases; the core supports validation and uses an empty BIP39 passphrase. Preserve existing derivation conventions, including the current Bitcoin testnet compatibility derivation.

This is a source-level design review, not a new runtime validation record. Earlier MVP test results do not prove the changes specified here.

## Supported assets

| Asset | Network | Identity | Precision | Actions |
|---|---|---|---|---|
| BTC | Bitcoin testnet3 | Native Bitcoin asset | 8 | Send and receive |
| L-BTC | Liquid testnet | Core's Liquid testnet policy asset ID | 8 | Send, receive, and pay Liquid fees |
| TEST | Liquid testnet | `38fca2d939696061a8f76d4e6b5eecd54e3b4221c846f24a6b279e79952850a5` | 8 | Send and receive |

The TEST identity and precision were supplied by the user. The value is syntactically a 64-character hexadecimal ID; that check does not verify issuance or funding availability.

Keep the approved list in versioned network-specific Rust configuration and expose safe metadata/capabilities to the UI. Approval is determined by network and asset ID, never a ticker or name. L-BTC identity must come from the selected testnet policy asset, never a mainnet constant.

All received assets remain visible. Unlisted Liquid assets show their full ID and raw integer units with an explanation that sending is unsupported in this release. Do not guess their precision or identify them using untrusted display names. The UI offers asset-specific send/payment-request actions only for the approved set; Rust independently enforces this restriction.

## Visual system and application shell

Follow `DESIGN.md`: dark surfaces, pink primary actions, Geist interface typography, JetBrains Mono for addresses/identifiers, project-owned styling, wrapped Base UI primitives, visible pointer-friendly controls, and normal keyboard accessibility. Keep the 224px sidebar, 48px header, and 1024×700 minimum desktop window. Validate at the 1440px baseline as well.

Navigation: **Início, Ativos, Histórico, Receber, Enviar, Ajustes**. Excluded features do not appear as dead navigation items. Header: page title, persistent testnet badge, privacy control. Sidebar footer: “Chaves neste computador” and a labeled lock action. Detailed chain health lives in the home status card and network settings.

Approved testnet exception to the earlier home design: replace the portfolio chart placeholder with useful holdings/activity. No combined BTC/TEST balance, fiat value, allocation across unlike units, market sparkline, or invented performance. Preserve the broader mainnet visual direction for later work. This spec governs that testnet exception without rewriting the earlier documents.

Privacy mode persists as a preference and conceals amounts consistently in holdings, pending values, review/results, and transaction details. Do not expose concealed values through accessible labels/tooltips while claiming them hidden. Privacy presentation does not substitute for session locking.

## Screens and flows

### Welcome, create/import, and unlock

Welcome provides Create wallet and Import wallet with clear testnet context and an explanation that recovery depends on the recovery phrase.

Creation uses the existing Rust mnemonic generator with 12 words by default and a 24-word option. Show numbered words on a dedicated screen, verify selected words, then require six-digit PIN entry and confirmation before completing setup. Keep the candidate mnemonic in a bounded host-owned setup session; expose it only to the dedicated backup UI. Abandoning setup discards the candidate. Setup completion must not leave an unusable partially installed wallet if persistence fails.

Import accepts valid English BIP39 phrases through core validation, including valid standard word counts (12/15/18/21/24), checks words and checksum, and normalizes whitespace. No additional BIP39 passphrase is introduced. Explain validation errors and clear the form after completion. Preserve compatibility with existing wallet derivation.

Do not put phrases/PINs into URLs, logs, query caches, analytics, or persistent frontend storage. Clear transient secret UI state on completion, cancellation, and locking. Host storage continues to use OS credentials with no plaintext fallback. Do not promise guaranteed erasure of JavaScript memory.

After setup/unlock, open Home immediately with independent chain progress. A chain that has not synchronized has unavailable balances, not zero balances. Unlock provides incorrect-PIN and remaining-lockout feedback; retain persisted retry throttling and no automatic wallet erasure.

### Home

Use a wide holdings card with Receive and Send actions, a narrower network-status card, and a full-width recent-activity section below. Holdings show asset, network, balance, and pending amount where actually available. BTC and L-BTC remain visible at zero. TEST and unlisted assets appear when held or referenced by activity; TEST is always selectable in Receive.

Do not duplicate confirmed/pending amounts or imply a pending amount is spendable. Expose explicit available/pending semantics from Rust; absent pending data is “unavailable,” not zero. Each holding opens its asset detail page.

Network status displays Bitcoin and Liquid separately with phase, last successful sync, and refresh/retry. Retain last-known balances during refresh and label them stale after failure. Recent activity links to History. New wallets show an actionable Receive empty state. Uncertain sends have a persistent prominent link to their saved result.

### Assets and asset detail

Assets lists individual holdings with search and a network filter. Asset identity includes network; Liquid assets additionally use the full ID. Detail displays balance, available pending information, network, full ID for Liquid, filtered activity, and supported contextual actions. An unknown asset detail explains raw units and disabled sending. No market charts are included.

### History and transaction detail

Show date/time when available, direction, asset movements, network, amount, and status. Filters cover asset, network, direction, date, and status. Distinguish “no activity,” “no filter matches,” and “history not yet available.”

Selecting an entry opens a keyboard-accessible details panel with status, confirmations, timestamps, full transaction ID, available addresses, and network fee with its denomination. Multi-asset Liquid transactions must preserve all relevant wallet asset movements rather than silently reducing them to one asset. Group movements by chain and transaction ID, and count the network fee once. DTO changes may be needed; preserve the frozen mobile API through additive interfaces/mapping.

Use stable routes/identifiers so a saved send result can open its history detail. Unknown timestamps/addresses remain explicitly unavailable. Submitted and confirmed are distinct states.

### Receive

Choose BTC, L-BTC, or TEST; show the corresponding testnet network automatically. Provide an optional amount and description, QR, full address, Copy address, and Copy payment request controls. Label whether the QR contains an address or a payment request. Changing inputs recomputes the request deterministically without unnecessarily generating a new address on every render.

Use an asset-specific Liquid payment request for TEST, preserving its exact ID and eight-digit precision. Explain that an ordinary Liquid address can receive multiple assets and does not restrict what a sender transfers. Payment request parsing/generation must round-trip the asset and amount through the shared Rust contract. Avoid implying a requested amount guarantees payment or expires an address.

### Send, review, and result

Select the asset, paste an address/payment request, enter amount or Max, and choose a fee estimate or custom fee rate. Show balance, network, and field-specific validation. A recognized approved payment request can prefill asset/amount; never silently substitute an unsupported asset or accept the wrong network. A bare Liquid address does not identify an asset: require an explicit selection, including an intentional selection carried from an asset detail page.

Use exact integer base units for amounts and exact decimal parsing. TEST supports at most eight decimal digits. DTOs must preserve integers across IPC: retain existing bounded safe-number paths where proven safe; serialize new unrestricted raw asset quantities as decimal strings. Reject overflow and never round a transfer amount to fit a transport.

Fee estimates identify freshness/source and remain distinct from final fees. If estimation is unavailable, explain it and offer the custom-rate path with actual transaction-fee review. Do not label a default rate as a live estimate.

For BTC/L-BTC, Max accounts for the fee using the transaction builder's available funds. For TEST, Max uses available TEST while separately requiring enough L-BTC for fees. An insufficient L-BTC error explains the fee requirement even when TEST funds are sufficient.

Review displays full destination, network, asset, amount, fee, and debits by asset. TEST review shows TEST sent plus L-BTC fees separately. Preserve expiring, session-bound, single-use review IDs and actual signed-transaction fee bounds. Bind approval to asset, network, destination, amounts, fee bounds, and session. Changing any reviewed input requires a fresh review.

Model editing, preparing, reviewing, submitting, submitted, failed, and uncertain as explicit states. Confirmation submits an opaque review ID, not a replacement client-side transaction. Navigation, locking, or restart must not cause automatic resubmission. Persist enough non-secret submission information to recover the result and reconcile history after unlock/restart. Extend current submission records with asset/debit identity where needed.

A transport failure after submission can be uncertain. Preserve the MVP's protection against casually repeating unresolved sends. Locking revokes unconsumed reviews and signing authorization before signing starts; it cannot cancel an already signed/submitted transaction. After unlock, require a fresh review for an unsubmitted send.

### Settings

| Section | Contents |
|---|---|
| Security and recovery | Change PIN, timeout selection, lock now, view phrase after fresh authentication |
| Network | Separate Bitcoin/Liquid node settings, health, test connection, restore defaults, explicit public-node fallback preference |
| Display | Language, BTC/L-BTC units, privacy; TEST remains denominated in TEST with eight-digit precision |
| Diagnostics and about | Version, chain sync times, useful connection errors, redacted diagnostic export |
| Remove local wallet | Fresh authentication, recovery warning, explicit confirmation and local-data removal |

Use pt-BR as reference copy and support en/es through the existing localization direction. Map stable errors to localized UI messages. Raw provider errors must not expose sensitive content in normal notices or diagnostic exports.

Node configuration remains testnet-only and uses the native backend boundary. Validate endpoints, test before committing changes, and retain the previous working configuration on failed validation. A custom node does not silently fall back to public infrastructure: fallback is an explicit preference. Do not introduce a frontend dependency on a specific public node vendor.

Viewing the recovery phrase and changing PIN require fresh host-verified authentication scoped to the operation. Clear the recovery view on lock/exit. Wallet removal stops the runtime, revokes authorizations, and removes wallet-associated local secrets/state without affecting unrelated OS credentials. Explain that removal cannot cancel transactions and loses local tracking, especially for pending/uncertain sends. Report partial cleanup failures truthfully and allow safe retry.

## Locking contract

Allowed intervals: **1, 5, 15, 30, 60 minutes**. Default: **1 minute**. One preference governs foreground inactivity and time in the background. Manual locking is immediate; every process restart starts locked. Background synchronization continues, but locked UI caches are cleared and sensitive events remain suppressed.

Keyboard and pointer interactions inside the focused wallet count as activity; sync, incoming transactions, timers, and programmatic UI updates do not. The host timestamps activity and validates the current deadline before accepting an activity reset or privileged operation. A late event cannot revive an expired session.

Technical proposal for precise boundary behavior: foreground inactivity expires from the last accepted interaction. On backgrounding, use the earlier of the existing idle deadline and background-entry time plus the interval, so changing focus cannot extend an already idle session. Returning before expiry does not itself reset inactivity; the next real interaction does. Returning after expiry requires unlock. Selecting a shorter interval applies it immediately against elapsed inactivity.

Rust owns deadline decisions; frontend timers only present state/report eligible activity. Use time handling that accounts for system suspend and cannot extend authorization because the wall clock moved backward. Recheck expiry on foreground/resume and before privileged commands even if a scheduled timer ran late. Bind events to session generation. Locking clears secret forms, cancels sensitive queries, revokes reviews, and prevents stale async results from repopulating an unlocked-looking UI.

## Architecture and implementation boundaries

```text
React feature screens + pure selectors/reducers
                 |
       injected typed wallet client
                 |
Tauri command allowlist + session authorization + native adapters
                 |
mooze-app: shared workflows, snapshots, events, operation lifecycle
                 |
mooze-core: assets, exact amounts, wallet rules, provider ports
```

Frontend modules: shell/session, setup, dashboard, assets, history, receive, send, settings, shared UI, and client integration. Query data is scoped by wallet/session generation; ephemeral forms use explicit local state. Derived models calculate filtering, formatting, and freshness without I/O. One event mapping invalidates appropriate queries. Screens do not independently start sync loops.

Inject the typed client at the application boundary rather than importing Tauri in feature components. Keep Base UI dependencies behind Mooze UI components and chart-free design tokens in CSS. Controlled preview/test fixtures use the same client contract; they must not silently replace real runtime data.

Rust owns approved-asset policy, authoritative validation, fee/debit calculation, send authorization, lifecycle expiry, configuration persistence, and credential access. Reuse the existing pure session rules and core capabilities; put reusable application orchestration in `mooze-app` and OS clocks/storage/window integration in the native host. Do not duplicate provider or monetary rules in React.

Extend the narrow host API per use case: setup, approved asset metadata, payment requests, fee review, detailed activity, security preferences, and node settings. Do not expose the facade's generic secret-store access, arbitrary API requests, or unrestricted signing as webview commands. Maintain generated DTO freshness checks.

Persist versioned wallet settings and operation records with backward-compatible defaults for the existing MVP profile. Existing profiles default to the one-minute timeout. Keep the testnet application/storage namespace isolated. Persisted policy configuration must not let frontend changes bypass the approved asset list.

## Delivery slices

Each slice gets a concrete implementation plan after this spec is approved. This document fixes product behavior and boundaries, not a task-by-task coding plan.

1. **Shell, holdings, and assets:** extract modules, injected client, approved metadata, accurate home/asset states, all Liquid holdings visible.
2. **Wallet lifecycle and security:** create/import/backup, PIN changes/recovery access, foreground/background timeout, safe removal.
3. **Transactions and history:** asset-aware receive/send, TEST fee debits, exact payment requests, estimates/Max, detailed multi-asset history, durable send recovery.
4. **Settings and release validation:** nodes, localization, diagnostics, accessibility, offline/reconnect and funded testnet walkthroughs. Localization/accessibility foundations start with the shell, not after screens are built.

## Acceptance and verification

- Create 12- and 24-word wallets; validate import, backup checks, restart/unlock, storage failures, and mobile-compatible derivation fixtures. Never use a user's existing wallet for automated checks.
- BTC, L-BTC, and the exact TEST ID support receive/send. All other Liquid assets remain visible and are rejected for sending by Rust even if a frontend request is altered.
- TEST send review and history separate TEST movements from L-BTC fees; insufficient fee funds block sending. Decimal, overflow, Max, request/network mismatch, unknown-asset, and multi-asset transaction fixtures cover the relevant rules.
- Payment request generation/parsing round-trips asset, amount, network, and optional description; unsupported requests fail explicitly. No guessed precision or float rounding enters authorization.
- Test every timeout with a controllable clock, foreground/background transitions, deadline races, suspend/resume, restart, and stale activity events. Background sync never resets inactivity. Fresh-auth operations cannot reuse expired authorization.
- Verify lock during preparation, review expiry, duplicate confirmation, navigation/restart during submission, uncertain broadcast reconciliation, and stale query/event suppression. No automatic resubmission occurs.
- Test settings persistence, migration from MVP defaults, custom-node failure/fallback behavior, and partial wallet-removal failure with isolated storage.
- Run relevant frontend unit/integration tests, typecheck/build, host/shared Rust suites, generated-type checks, and frozen Flutter bridge/mobile regression checks for shared API changes. Focus tests on behavior and boundaries rather than component implementation details.
- Inspect actual rendered screens at 1024×700 and 1440px: no clipped primary actions, full usable addresses, accessible labels, keyboard focus/order, dialogs/panels, privacy behavior, reduced motion, and all three locales.
- Exercise first sync, empty wallet, one chain failing, offline/reconnect, stale history, and unknown holdings through controlled fixtures and real native runs.
- Record funded public-testnet receive/send transaction IDs and confirmation evidence for BTC, L-BTC, and TEST using dedicated disposable test wallets when funds are available. A local signing fixture does not substitute for this evidence. If TEST funding is unavailable, report that external validation dependency rather than claiming the milestone fully verified.
- Document actual supported platform/build results. No production/mainnet-readiness claim follows from testnet completion.

## Review checkpoint

The user has approved the testnet milestone, screen direction, supported assets, transaction flow, and timeout choices including foreground inactivity. Review this consolidated document, particularly the precise timeout boundary behavior, setup/settings details, and delivery boundaries, before implementation planning. The next step after approval is a written implementation plan.
