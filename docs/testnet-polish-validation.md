# Desktop testnet polish — validation and review

Recorded 2026-10-06 on macOS. This is testnet development acceptance, not a mainnet,
distribution-signing, or cross-platform release approval. User-directed funded
checks use Nigiri regtest on OrbStack. Public testnet configuration still approves
BTC, L-BTC, and TEST `38fca2d939696061a8f76d4e6b5eecd54e3b4221c846f24a6b279e79952850a5`
at eight decimal places.

## Independent review

A fresh reviewer inspected the actual tracked and untracked desktop implementation
and shared wallet dependencies. No critical findings; four important findings were
accepted and fixed:

| Finding | Correction and verification |
| --- | --- |
| Cancelled filesystem jobs could outlive the storage gate | Move an owned mutex guard into the blocking job. Post-fix cancellation/lifetime and ordinary concurrent-store tests pass. |
| Failed node replacement and failed rollback retained a disconnected app | Clear the old instance, revoke the unlocked session on restore failure, reconnect on the next unlock. Failure/recovery test observed failing, then passing. |
| Recovered uncertain sends lacked reconciliation details | Display persisted destination, asset, exact recipient amount, fee and debits with privacy masking. Explicit unavailable message for legacy records; known tx links directly to detail. UI regression observed failing, then passing. |
| Issued-asset fee shortages were generic errors | Preserve structured insufficient-L-BTC information through core, facade, host and translations. Unit check and funded local asset/zero-L-BTC check pass. |

Fixes were validated with tests; no second independent review was performed.
Deferred minor: live fee choices do not yet show their supplied source and observed
time alongside the rates.

## Verification commands and results

| Command | Result |
| --- | --- |
| `npm test -w @mooze/frontend` | 28 passed |
| `npm run build -w @mooze/frontend` | Typecheck and production build passed |
| `cargo test --locked --manifest-path apps/desktop/src-tauri/Cargo.toml --features codegen` | 37 host tests passed; native opt-in tests excluded from ordinary run |
| `cargo test --locked --manifest-path crates/mooze-core/Cargo.toml --features electrum` | 326 passed, one pre-existing ignored; frozen Flutter snapshot passed |
| `cargo test --locked --manifest-path crates/mooze-app/Cargo.toml` | 38 passed |
| `cargo test --locked --manifest-path crates/mooze-app/Cargo.toml --features codegen --test generated_up_to_date` | Generated files current |
| `cargo check --locked --manifest-path packages/mooze_core_bridge/rust/Cargo.toml` | Passed |
| FVM 3.41.9 `flutter test --no-pub` in `apps/mobile` | 679 passed earlier in this implementation session |
| `cargo test --locked --manifest-path apps/desktop/src-tauri/Cargo.toml --test native_smoke -- --ignored --nocapture` | Real isolated Keychain import, restart lock, unlock, receive and both public testnet syncs passed (5.67 seconds) |
| `cargo run --locked --manifest-path tools/wallet-regtest/Cargo.toml -- --funded-local-regtest` | Funded receipt/send/Max/reopen/fee-shortage checks passed |
| `npm exec -w @mooze/desktop -- tauri build --debug --bundles app` | Native debug `.app` built, approximately 111 MiB |

Host loopback fixtures and dependency downloads require execution outside the
restricted network sandbox. Initial sandbox-only WebSocket failures were rerun
with loopback access and passed. Build warnings remain for the JS chunk above
500 kB and an upstream `proc-macro-error2` future-compatibility warning.

## Native UI observations

Used an explicitly isolated disposable profile, never the user's personal wallet.
Native screenshots and accessibility trees were inspected during the session.

- Unlock, startup loading and synchronized dashboard observed. Header and holdings
  now share the holdings status source, avoiding contradictory initial sync labels.
- Assets and asset details mask numeric values, including accessible text. Keyboard
  Tab/Return navigates into asset details.
- Receive supports the approved TEST selector and displays its exact asset ID.
  Nine-decimal input is rejected and the invalid QR is not offered.
- At the normal 1440-wide window, receive form and QR use two columns; address and
  copy controls fit together. Long identifiers wrap rather than truncate.
- At 1024 × 700, the dashboard stacks balances and network status without splitting
  L-BTC. Receive stacks form and QR, accepts eight-decimal TEST requests, wraps the
  full asset ID, and confirms request copying. History filters fit in two rows.
  The compact build used a temporary configuration override; the repository keeps
  its normal 1440-wide default.
- Send rejects nine-decimal amounts before review. Broadcast was not performed
  through the public-testnet native GUI; transaction mechanics were tested locally.
- Settings were inspected in Portuguese, English and Spanish. Corrected route
  headings, network-label spacing, lock-duration labels, fee-rate label, loading
  text and checkbox sizing. Catalog scan found and filled missing literal keys.
- Removal confirmation remains disabled until acknowledgment/PIN conditions; Escape
  dismisses the dialog. No personal wallet was removed.
- Native diagnostic save dialog opens. Cancel returns an explicit localized
  cancellation result. Successful export also returned a localized success result.
  The saved 406-byte JSON was inspected: only app version, architecture, chain sync
  metadata, network, platform and schema version. Diagnostic field allowlisting
  is also covered by host tests.
- Restart re-locks the wallet. Display/privacy preferences restore after unlock.

## Funded regtest evidence

See [reproducible harness](../tools/wallet-regtest/README.md). Final reviewed run:

| Transfer | Local transaction ID |
| --- | --- |
| BTC exact | `43cdb56a3d45c924764c93269647bbbb96ad4a72d65ef3f65759de1c986bffa6` |
| L-BTC exact | `dbc654ed92d9bf347296ae8dc97e4bd58a93a4d438bf7921b7e285fb51a8e398` |
| Local issued asset exact | `d9484bc9730851d57b6e9138fa26f1b2ca596f0e10c13e892204449b0a045598` |

Each exact transfer sent 10,000 base units. BTC Max sent 189,749 with a 110-sat
fee bound; L-BTC Max sent 189,158 with a 191-sat fee bound. Reopened wallets
resynchronized to zero native balances and 90,000 local asset units. An attempted
unsigned issued-asset build with zero L-BTC returned the structured fee shortage.

The local asset is a test fixture, not public TEST. These IDs are only meaningful
on this local Nigiri chain. No public faucet submission occurred.

## Acceptance limits

The complete every-screen × every-language × every-window-size matrix is not
claimed. Live OS suspend, GUI offline/reconnect, injected uncertain-send restart
in the GUI, diagnostic write failure, and full native
create/import/recovery flows still need a dedicated acceptance pass. Their covered
host/component invariants are distinct from native end-to-end observations.

Windows/Linux, mainnet, distribution signing and unrelated earlier mobile/monorepo
work were outside the independent review. User-existing design/MVP document edits
were preserved. No merge, push or release was performed.
