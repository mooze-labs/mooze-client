# Mooze everyday wallet — Quiet Navy

Date: 2026-10-06. Status: visual direction and Home, Receive, Send entry/review, Settings, and transaction-result screens approved in conversation; consolidated written specification approved by the user’s “Proceed” after the final spec-review checkpoint. Activity, asset detail, setup, and lock treatments follow the written rules below rather than a separately approved screen mockup.

## Purpose

Make the desktop testnet wallet feel approachable and composed in everyday use. Balances, receiving, sending, and activity take priority. Network machinery remains accessible without dominating the interface. Success means fewer competing labels and panels, clearer transaction review, consistent controls, and preserved wallet behavior.

The user selected the everyday-wallet direction, selected Quiet Navy over Warm Paper, approved trimming trailing zeros in balances, and approved the refined Home, Receive, and Send-review layouts. The approved previews are design artifacts, not wallet functionality or complete interaction specifications.

The subsequent screen pass was approved with “Screens are good. Go on.” It covers Send entry with validation and fee-shortage states; Settings with General, Security, Network and About; focused PIN/recovery/removal dialogs; and broadcast, confirmed, uncertain and known-not-sent outcomes. The implementation must preserve host validation rather than reproduce the prototype's simulated actions.

Local visual reference: `.superpowers/brainstorm/92550-1791313812/content/quiet-navy-refinement.html`. Its `everyday-wallet.html` predecessor contains the A/B exploration. The preview includes illustrative values, a disposable public test address and non-functional QR artwork. Production must generate real QR codes from validated requests. Preserve these artifacts during implementation; do not copy their simulated state or event handlers into wallet code.

Approved additional screen reference: `.superpowers/brainstorm/92550-1791313812/content/send-settings-result.html`. This extends the same visual system. Its sample fees, fixed TEST selection, read-only credential fields, simulated connection checks and placeholder transaction ID are presentation fixtures, not production defaults or capability limits.

## Scope and preserved contracts

Apply this design to `apps/frontend`, shipped in the existing Tauri desktop host. Retain the typed wallet client, query layer, host session authority, storage, backend adapters, and Rust wallet implementation. Flutter mobile remains unchanged.

Keep Bitcoin testnet3, Liquid testnet, and the existing approved assets:

- BTC and L-BTC, with eight-decimal precision.
- TEST: `38fca2d939696061a8f76d4e6b5eecd54e3b4221c846f24a6b279e79952850a5`, eight-decimal precision, sendable and receivable.
- Unlisted Liquid assets remain visible by full identity and raw integer units; do not infer precision or enable unsupported sends.

Preserve host-owned lock intervals (1, 5, 15, 30, 60 minutes), exact amount arithmetic, validated payment requests, fee bounds, expiring single-use reviews, uncertain-send recovery, privacy masking, and existing security/recovery requirements.

No mainnet, fiat valuation, invented aggregate portfolio balance, price/performance charts, PIX, swaps, pegs, new wallet custody model, or mobile redesign. Warm Paper/light mode is not included. Existing acceptance gaps in `docs/testnet-polish-validation.md` are not resolved by this design pass.

## Visual system

Quiet Navy refines the existing identity. Use a mostly continuous dark canvas, grouping by spacing and alignment. Reserve enclosed surfaces for payment requests, review summaries, dialogs, and form groups that need separation.

| Role | Proposed token |
| --- | --- |
| Background | `#10121A` |
| Raised surface | `#1B1E29` |
| Primary text | `#F0EDE9` |
| Secondary text | `#979AA9` |
| Brand/action | `#EF286D` |
| Secondary pink mark | `#FF7AA7` |
| Decorative separator | white at 6% opacity |
| Connected indicator | `#73B59D`, always with text |
| Warning | `#D5A468`, always with explanatory text |

These are visual reference tokens, not contrast certifications. Validate final text combinations to WCAG AA, including primary-button text; darken the action fill if needed. Interactive boundaries and focus rings must remain perceivable; decorative separators do not establish control boundaries alone.

Retain bundled Geist 400/500/600 and JetBrains Mono for addresses/IDs. Use tabular numerals for amounts. Product text is at least 14px for normal reading and 12px for secondary information; scaled comparison-board text sizes are not production sizes. Page headings are approximately 28–30px; balances 22–28px. Use an 8px spacing rhythm with 4px half steps, 24–40px section gaps, and 8px control/12px panel radii.

Keep a 184–208px sidebar, adjusting to the 1024×700 minimum desktop window. Use a bounded content region rather than stretching forms across every available pixel. At wide sizes Receive and Send review use two columns; at constrained content widths they stack without horizontal scrolling. Keep full addresses and asset IDs wrapping; never truncate a reviewed destination.

Use restrained BTC, Liquid, and TEST marks for recognition. Asset identity still comes from the catalog and network; marks and tickers are not verification. Keep Lucide icons consistent. No decorative market charts or promotional slogans. Transitions are short (100–180ms), functional, and respect reduced motion.

## Navigation and screens

Primary navigation: **Wallet, Activity, Settings**. Send and Receive are prominent labeled actions next to balances and within asset details. Keep existing `/send`, `/receive`, `/assets`, and `/assets/:chain/:assetKey` routes working; removing a sidebar entry does not remove a capability. `/assets` remains a full asset list route reachable through “View all assets” when the wallet overview is shortened. No new command palette.

One persistent Testnet badge appears in the shell. A compact connection control opens per-chain health, last successful sync, refresh, and a link to Network settings. Known outages are visible inline on affected screens. A fee shortage must not appear as a network outage. Offline state does not imply cached balances are zero or prevent receiving when the host can derive an address locally.

### Wallet and asset details

One page heading, balances with clear units, Send/Receive, and recent activity. Remove duplicated overview labels, introductory marketing copy, routine network-status cards, and redundant testnet badges.

Asset rows show a mark, asset name, secondary network, and exact but compact balance. Pending amounts appear only when present or when needed to explain availability. Preserve available/pending distinctions exposed by the existing client; do not invent spendable values. All held assets remain discoverable. Unknown assets use a clearly distinct treatment and raw units.

Selecting a row opens asset details with balance, Send/Receive capabilities, related activity, and expandable identity information. Keep the full asset catalog accessible. Asset details and transaction details offer exact precision.

Privacy control sits beside balances, persists through existing preferences, and masks both visual and accessible amount text. It also applies to pending values, activity, and review/debit summaries under the existing privacy contract. The user can explicitly reveal amounts before reviewing; avoid making an irreversible confirmation visually ambiguous.

Empty wallet: one short explanation and a Receive action. Loading: neutral placeholders, never zero balances. With cached data, preserve it and label freshness during refresh/failure. On first-sync failure, show unavailable values and a recovery action. Recent activity becomes visible when data exists rather than showing redundant large empty panels.

### Receive

Asset/network selector and optional request fields on the left; a focused QR/address/copy panel on the right. Supported assets include BTC, L-BTC, and TEST. Switching asset updates every dependent label, metadata, request and QR together. Preserve supported payment-request input and validation behavior.

Amount is optional and expands on request. Asset identity information expands separately, with the full approved ID and precision. The destination stays visible in full and wraps. Generate QR codes from the actual validated payload, with a proper quiet zone and sufficient display size for dense confidential Liquid addresses. Distinguish **Copy address** from **Copy request** when an amount or asset-specific request is used; a plain address alone does not encode the requested TEST asset or amount.

Loading or invalid inputs suppress stale QR/request output. An address-generation error explains the failure and offers retry. Network disconnection alone must not fabricate an address-generation error. Copy success is a short, accessible inline message. Preserve pending form values across recoverable UI errors.

### Send and review

Entry is a focused form: asset/network, destination or supported payment URI, amount, available Max, and fee choices. Keep fee source/age visible in secondary text when supplied; label fallback estimates honestly. Advanced fee controls remain accessible without crowding the primary task.

On wide windows, place asset/network context and the fee-paying-asset explanation beside the form. On compact windows move essential information into the form; do not hide required network or fee information. Max is next to the amount, and available balance is secondary text only when authoritative availability is supplied. Wrong-network errors sit beside the destination. Preparing a review disables duplicate preparation and preserves input. Fee choices reflect returned capabilities: do not invent three meaningful speed tiers when the chain/provider only supplies one configured rate.

Review shows the exact amount and asset, network, full destination, and a debit summary. For TEST, show TEST sent and L-BTC network fee separately; never add quantities with different units into one total. BTC/L-BTC review also shows the total debit in the fee-paying asset. Identify fee estimates/bounds according to the host's actual semantics. Expandable asset-ID detail supplements the visible asset/network identity.

Confirmation consumes the existing host review; this redesign must not introduce frontend signing or bypass host review expiry. Editing reviewed data creates a fresh review. Loading, validation failure, expiry, or fee shortage prevents confirmation and exposes a useful next action. TEST fee shortage explains that L-BTC is required and links to Receive with L-BTC selected while preserving recoverable send input.

Success links to transaction details. An uncertain result stays distinct from failure, displays persisted reconciliation details, and prevents casual resubmission. Navigation, relaunch, or retry must never automatically send a transaction. The prototype's clickable confirmation is only a visual simulation.

### Transaction result

Use a focused result heading and a receipt panel containing exact amount/unit, network, full destination, and fee information with its known provenance. The result screen uses the same privacy contract as review and activity. The full transaction ID is expandable when known; never fabricate one or show an explorer link without a valid ID. Unknown fee data is unavailable rather than zero, and a stored review estimate must not become “fee paid” solely because the transaction confirmed.

| Host-backed outcome | Presentation | Actions |
| --- | --- | --- |
| Broadcast accepted, not yet confirmed | “Transaction sent”; explicitly awaiting network confirmation | View transaction; return to wallet |
| Confirmed by synchronization | “Transaction confirmed”; show actual chain status | View transaction; return to wallet |
| Outcome uncertain | Explain that transmission may have occurred; retain amount, destination and known debit details | Check result without retransmitting; return to wallet with unresolved-send notice preserved |
| Definitely not transmitted | Explain that no send occurred, using only a host outcome that establishes this | Return to editable send; return to wallet |

Do not classify a timeout, lost response, or generic transport error as definitely not sent. An uncertain result never offers a primary “send again” action. Confirmation is determined by chain data, not a timer or the user visiting the screen. Navigation to details must work both immediately after submission and after restoring a persisted submission. The receipt is recoverable data, not component-local state alone.

### Activity

Readable transaction rows with direction, asset, exact compact amount, time and status. Keep filters for asset, network, status, direction and date, but group secondary controls under Filters with a count of active filters and Clear action. Preserve existing deep links to transaction details. Show unknown timestamps as unknown, not epoch dates.

Transaction details display full destination/transaction identity, network, exact amounts, fee where known, and explorer link with existing host validation. Pending, confirmed, failed and uncertain status must use text as well as color. Filtered-empty and wallet-empty states have different explanations and actions.

### Settings, setup and lock

Settings has local navigation for **General**, **Security**, **Network**, and **About**. General includes language, Bitcoin unit and privacy. Security includes timeout, lock now, and entry points to PIN change and recovery; open their authenticated forms only when requested. Network retains both chain settings, connection testing, explicit fallback preference and rollback semantics. About contains version and redacted diagnostics. Local wallet removal remains separated and requires the existing acknowledgment and fresh authentication.

Use a horizontal section tab bar and aligned setting rows, with description on the left and control on the right; stack controls when needed at compact widths. General preferences and timeout use the existing persistence behavior, show saving status, prevent overlapping mutations, and restore the previous saved value on failure. Network changes require explicit test/save controls and retain the prior connection on validation failure. Per-chain tabs bind fields and health to the selected chain; switching tabs must not silently discard an unsaved edit. Preserve drafts per chain until explicit save/reset or route exit, and warn before discarding dirty network configuration on exit.

PIN change opens a focused dialog with current/new/confirmation fields. Recovery opens a private-view warning and fresh-PIN authentication, followed by the phrase only after host authorization. Removal opens the recovery warning, acknowledgment and PIN confirmation; submission remains disabled until required fields are complete, and the host remains authoritative. Dialogs support Escape, focus containment/return, and clear secret fields when closed or locked. Do not adopt the prototype's read-only placeholder inputs or enabled simulation buttons as real security behavior. Report partial removal through the existing resumable removal state.

About provides version, testnet identity and diagnostic export with explicit success, cancellation and failure feedback. It does not gain telemetry or remote support uploads. Network/provider details belong in Network or diagnostic controls rather than the main wallet view.

Apply tokens and shared controls to setup, backup, recovery and lock screens without changing the sequence or security model. One clear action per step, labeled fields, readable errors, and existing secret clearing on lock/exit. Preserve keyboard navigation and focus restoration for dialogs. No native title-bar customization is required in this pass.

## Amount presentation

Use pure formatters over integer strings/BigInt. Do not convert amounts to floating point, round meaningful digits, or change underlying precision.

| Context | Presentation |
| --- | --- |
| Wallet, asset lists, activity rows | Trim trailing fractional zeros and the unused decimal separator |
| Send review, transaction details, exact asset detail | All eight fractional digits for approved assets when denominated in BTC/L-BTC/TEST |
| Bitcoin unit preference: sat | Exact integer sats for BTC/L-BTC; TEST remains in TEST |
| Unknown assets | Exact raw integer units, no inferred decimal scale |
| Zero | `0` in compact contexts; fixed precision in exact contexts |

Examples in English: `0.02485000` → `0.02485 BTC`, `125.00000000` → `125 TEST`, `0.00000001` remains `0.00000001`. Locale formatting follows pt-BR/en/es. Input continues accepting supported comma/dot decimals with no grouping ambiguity. Preserve user input while editing; trim on display rather than silently rewriting an active field. Accessible amount labels include the asset/unit. Privacy placeholders replace the whole sensitive value, not just a blurred visual layer.

## Component and implementation boundaries

Proposed foundation: selectively adopt **shadcn components backed by Base UI**, retaining the already installed Base UI primitives. Own component source, tokens and variants in the repository. Add Tailwind as the styling tooling needed for the selected shadcn components; integrate with existing Vite and prevent preflight/global styles from unexpectedly changing unmigrated screens. Pin chosen dependencies and review added component source. No vendor-hosted runtime, fonts, analytics, or registry fetches at application runtime.

Keep three boundaries:

1. UI primitives: Button, Field, Select, Checkbox/Switch, Dialog, AlertDialog, Tabs, Popover, Tooltip, Skeleton, Separator. No wallet client or Tauri imports.
2. Wallet presentation: Amount, AssetMark/AssetRow, NetworkStatus, TransactionRow, RequestPanel, DebitSummary and inline feedback. Typed immutable props and callbacks; pure formatting/view-model functions.
3. Feature containers: queries, navigation, host commands, validation state and preferences. Preserve existing state machines and typed client effects.

Do not create a second store for wallet/session state. Keep effects in existing feature containers/adapters and do not rewrite proven transaction logic as part of visual migration. Migrate coherent screens rather than leaving duplicate control systems indefinitely. Update `DESIGN.md` during implementation with approved replacements, preserving unrelated user edits and recording which earlier dashboard/chart decisions this testnet scope supersedes.

## Verification and completion criteria

- Meaningful formatter tests cover zero, one base unit, trailing/interior zeros, negative activity amounts, maximum supported integers, locales, sat preference, and compact versus exact contexts.
- Component/flow checks cover privacy accessibility, asset-aware receive payloads, stale QR suppression, review debit labels, insufficient L-BTC, expiry and uncertain results. Preserve existing host/core regressions; broaden Rust testing only if shared behavior changes.
- Check real Tauri/WebView presentation at 1440×900 and 1024×700, including full Liquid addresses and eight-decimal review values. Validate pt-BR, English and Spanish, keyboard/focus behavior, reduced motion and contrast.
- Exercise ready, empty, initial loading, refreshing cached data, offline, validation error, submitted and uncertain states as appropriate. Do not rely on screenshots alone to verify financial or security behavior.
- Verify Send → Review → Result navigation, host-backed broadcast/confirmed distinctions, restored result details, and the absence of retransmission from uncertain-result checks. Verify settings-save rollback, per-chain network drafts, dialog focus, fresh authentication and secret clearing.
- Build/typecheck and frontend tests pass; no navigation capability or security invariant is lost. Test prototypes separately from real wallet flows. Preserve the existing funded Nigiri evidence and use disposable local wallets if transaction behavior changes.

The next artifact is an implementation plan after written-spec review. No application code or dependencies have been changed by this design pass.
