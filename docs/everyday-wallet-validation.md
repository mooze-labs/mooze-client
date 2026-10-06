# Everyday wallet design implementation — 2026-10-06

The approved Quiet Navy interface is implemented in the existing desktop frontend.
This is a frontend implementation and review milestone, not mainnet or release
acceptance. Existing Rust, generated interfaces, and mobile behavior were retained.

## What changed

- Owned shadcn Base UI button source, MIT notice, semantic navy/pink tokens and
  Tailwind utilities without preflight. Existing Base UI dialog behavior remains.
- Wallet / Activity / Settings navigation; compact balance rows and asset marks;
  a compact network-status popover; receive/send actions beside the balances.
- Exact integer-string formatting with compact balances/activity and full precision
  in details/reviews/receipts. Locale and native sat preferences are respected;
  TEST retains its own denomination. Privacy removes sensitive accessible text.
- Asset-aware receive composition, expandable identity, full wrapping address,
  real QR payload, separate address/request copying, and request-specific feedback.
- Separate send form, host-authorized review and durable result presentation.
  Confirmation matches transaction ID plus chain. Uncertain sends retain explicit
  reconciliation and never automatically resubmit. Approved fee bounds remain
  distinct from actual activity fees. A fee-funding detour retains ordinary draft
  fields within the unlocked generation, never Max or authorization.
- Four settings sections, focused recovery/PIN dialogs, independent chain drafts,
  shared fallback preference and discard/cancel guards for route/history exits.
- Compact activity rows, optional filters with count/reset, exact transaction
  details, and an explicit waiting state for IDs not yet in the activity feed.

## Automated evidence from this pass

| Check | Result |
| --- | --- |
| `npm test -w @mooze/frontend` | 47 tests / 21 files passed |
| `npm run typecheck -w @mooze/frontend` | Passed |
| `npm run build -w @mooze/frontend` | Passed |
| `git diff --check` | Passed |
| Native Tauri debug bundle, 1440×900 default | Built successfully |
| Native Tauri debug bundle, temporary 1024×700 override | Built successfully |

Coverage includes large/one-unit/negative amounts, compact versus exact formatting,
unknown precision, privacy, stale balances, deferred receive results, ninth-decimal
rejection, separate clipboard payloads, one-use confirmation, uncertain outcome
reconciliation, expired reviews, generation teardown, TEST/L-BTC debits, restored
fee bounds, chain-and-ID confirmation matching, retained custom fee rate, network
draft reconciliation, guarded section/history exits, dialog focus, and setup/PIN
validation. The baseline had 28 frontend tests.

No Rust or codegen inputs changed during this redesign. Prior funded Nigiri/OrbStack,
host/core/mobile and native transport results are documented separately in
[testnet-polish-validation.md](testnet-polish-validation.md); they were **not rerun**
or counted as new evidence here. No public testnet transaction was broadcast for
layout verification.

## Native observations from this pass

The disposable validation profile was used throughout. Its window title was
checked for **Mooze Testnet — isolated validation** before entering its test PIN.
No personal wallet was opened.

| Size / locale | Observed state |
| --- | --- |
| 1440×900 / pt-BR | Lock/unlock, wallet loading, three-item navigation and layout |
| 1440×900 / pt-BR | BTC then approved TEST receive; one-unit TEST request and QR; full Liquid address wraps; copy-address reports success |
| 1024×700 / pt-BR | Restart begins locked; unlock; compact holdings, unavailable initial BTC balance and privacy-masked Liquid balance |
| 1024×700 / pt-BR | General settings, section navigation, Security dialog opens and Escape closes it |
| 1024×700 / pt-BR | About diagnostic save dialog opens; Cancel returns localized cancellation feedback |
| 1024×700 / pt-BR | Send form, explicit Max, custom-fee disclosure and Review action appear in the accessibility tree; vertical scrolling is needed |

Keyboard Tab/Return was used successfully for native settings and screen navigation.
Native automation intermittently returned stale element IDs, lost-window errors,
and external-change notices; it was reconnected rather than bypassing the native
UI. These failures limited the remaining native matrix.

## Independent review

One baseline-aware, read-only gpt-6-astra review found no Critical issues and three
Important gaps. All three were reproduced with failing regression tests and fixed
in one pass, followed by the green full suite:

1. Review/receipt formatting now uses locale and sat preferences with exact amounts.
2. Returning from fee funding no longer resets the saved custom fee rate when the
   approved asset catalog loads.
3. Restored v2 receipts derive the approved bound from persisted request/debits,
   retaining unavailable for incomplete journals and preferring actual activity fees.

Deferred minor: the network-status popover does not include a direct Network
settings shortcut. Settings → Network remains available.

## Dependencies and visual checks

New exact versions: `class-variance-authority` 0.7.1, `clsx` 2.1.1,
`tailwind-merge` 3.7.0, `tailwindcss` and `@tailwindcss/vite` 4.3.3.
Base UI 1.8.0 was already installed. Component source and license live in `src/ui`;
there is no hosted design-system dependency. Fonts remain bundled locally.

Computed white-on-primary contrast is 5.36:1, hover 4.86:1; muted text on the
background 7.62:1 and primary text on the surface 14.23:1. Existing reduced-motion
CSS is retained; OS-level reduced-motion behavior was not newly exercised.

Build warnings remain for the frontend chunk above 500 kB and the upstream
`proc-macro-error2` Rust future-compatibility notice. The dependency audit also
reports pre-existing development-tool findings in Vitest/mocker/tinypool; a major
test-toolchain upgrade was not folded into this visual migration.

## Remaining acceptance gaps

- Fresh English/Spanish native screenshots across the full screen/size matrix;
  formatting and message catalogs are covered in code/tests, not a full native pass.
- Independent real-device QR scanning and readback of the native clipboard payload;
  native copy feedback was seen and the exact payloads are covered by component tests.
- Native funded review/result visuals and the approved public TEST asset funded
  round trip. Earlier local regtest assets are not evidence for that exact public ID.
- Fresh native successful diagnostic-save and node-save/failure/rollback exercises.
  Cancellation was verified here; earlier backend/native evidence remains separate.
- Full lock-while-secret-request-is-pending integration and OS reduced-motion matrix.
  Session teardown was reviewed; a complete native matrix was not claimed.

## Execution decisions and attribution

- Used the existing feature checkout and captured a baseline because it contains
  the preceding uncommitted wallet implementation. Cost: less physical isolation.
- Kept overlapping implementation changes uncommitted instead of misattributing
  prior work to new commits. Cost: review must include working files and baseline.
- Added primitives when consumed instead of creating unused wrappers. Cost: the
  design-system foundation remains incremental.
- Batched native inspection after screen changes. Cost: visual defects are found later.
- Preserved existing receive query-key isolation after the new race/invalid-input
  tests already passed. No artificial failing test or redundant state was added.
- Kept SendForm fields individually controlled, allowing an explicitly unselected
  asset rather than inventing an AssetKeyDto. Cost: a larger presentation prop list.
- Native evidence is reported separately from static review; incomplete platform
  checks remain explicit. Existing Rust/mobile and payment-URI controller behavior
  were outside this redesign review. Cost: their prior limitations remain separate.
- Kept the execution baseline/ledger while changes remain uncommitted; deleting
  them would discard attribution evidence. No push, merge or publication occurred.
