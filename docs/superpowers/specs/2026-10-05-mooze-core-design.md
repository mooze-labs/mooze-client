# mooze-core design

Date: 2026-10-05. Status: implemented. All modules ported; host and wasm32 builds pass.

## Goal

Move the application logic of the Flutter app into one Rust crate, `mooze-core`.
The crate compiles for `wasm32-unknown-unknown` and for native targets.
The Flutter UI and a future web UI call the same crate.

## Scope

The crate contains these modules. Each module ports one area of `lib/`.

| Module | Dart source |
|---|---|
| `domain` | `lib/domain/**`, `lib/shared/entities/asset.dart` |
| `ports` | new: platform traits |
| `store` | `lib/infra/storage/**`, `lib/infra/db/**` |
| `wallet::bitcoin` | `lib/infra/bdk/**`, wallet repository bitcoin part |
| `wallet::liquid` | `lib/infra/lwk/**`, wallet repository liquid part |
| `payment_uri` | send-funds QR, network and amount detection |
| `format` | asset formatters, input formatters |
| `prices` | `lib/shared/prices/**` |
| `auth` | `lib/shared/authentication/**` (signature and session parts) |
| `api` | Mooze API HTTP client |
| `pix` | `lib/features/pix/**` (data and domain layers) |
| `sideswap` | `lib/features/swap/data/**` |
| `peg` | `lib/features/swap/domain/**` |
| `user` | `lib/shared/user/**`, wallet levels, referral, phone verification |
| `merchant` | `lib/features/merchant/**` (data and domain layers) |
| `sync` | sync orchestrator, transaction notifier logic |

Out of scope: UI, l10n strings, biometrics, notifications display, screen security, FFI bindings.

## Architecture

The core never does I/O directly. It calls ports.

- `HttpClient`: send one request, get one response.
- `WsConnector` and `WsConnection`: open a WebSocket, send and receive text frames.
- `KvStore`: get, put, delete and list bytes by string key.
- `SecureStore`: same as `KvStore`, for secrets. The platform encrypts it.
- `Clock`: current time in milliseconds. `std::time::SystemTime` panics on wasm.

Port methods return futures bounded by `MaybeSend`.
`MaybeSend` means `Send` on native targets and no bound on wasm.

Wallets use the esplora HTTP API through `bdk_esplora` and `lwk_wollet` by default.
Native builds can enable the `electrum` feature. Electrum needs raw TCP, so wasm builds never enable it.
Do not build wasm with `--all-features`: LWK then pulls in aws-lc, which cannot build for wasm.

The Electrum clients block. Each call runs through the `BlockingSpawner` port.
The platform implements it with a blocking-task pool, for example `tokio::task::spawn_blocking`.
The default server lists and client settings match the Dart app.
A custom node URL replaces the list for its chain, as in Dart.

## Data

Stores serialize records as JSON into `KvStore` under prefixed keys.
This replaces drift. The web platform maps `KvStore` to IndexedDB.
Mobile maps it to SQLite or files.

### One-time copy from the Flutter app

1. The Dart class `FlutterDataExporter` reads the drift database, `mooze_v2.db` and SharedPreferences.
2. It writes one JSON snapshot.
3. The core function `migration::import_flutter_data` writes the snapshot into the core stores.
4. The core sets a marker. Later calls return at once.

Invalid rows are skipped and listed in the report. A storage failure leaves the marker unset, so the copy runs again.
The golden file `mooze-core/tests/fixtures/flutter_snapshot_v1.json` pins the format. A Dart test and a Rust test both check it.

The copy leaves out secrets, app logs, the legacy drift `Transactions` table, wallet caches and cached prices.
The mobile `SecureStore` must use the `flutter_secure_storage` entries, because the core uses the same key names.

## Errors

One `Error` enum with `thiserror`. Variants match the Dart `Failure` classes.

## Build

- Pin every dependency with `=x.y.z`.
- No git dependencies. SideSwap protocol types live in the core.
- `.cargo/config.toml` sets `AR_wasm32_unknown_unknown` to `llvm-ar`.
  The macOS system `ar` writes empty archives for wasm objects.
- CI builds the crate for the host and for `wasm32-unknown-unknown`.

## Testing

- Unit tests for pure logic run on the host.
- Port traits have in-memory fakes in `testing`.
- Wallet tests use fixed mnemonics and compare addresses with the Dart app.

## Success criteria

1. `cargo build --target wasm32-unknown-unknown` passes.
2. `cargo test` passes on the host.
3. `cargo deny check advisories bans sources` reports no vulnerabilities.

## Integration

`adapters` implements the traits that modules define for each other:

- `SessionTokens`: the auth session gives PIX its bearer token.
- `LiquidService`: the Liquid wallet acts as chain syncer, SideSwap signer and PIX address source.
- `BitcoinService`: the Bitcoin wallet acts as chain syncer.
- `WalletPeg`: both wallets fund peg-ins and peg-outs.

## Open items

1. Compare the first Liquid address with the output of the Dart app for the same mnemonic.
2. Write an FFI layer (flutter_rust_bridge for mobile, wasm-bindgen for web).
3. Write platform port implementations: IndexedDB `KvStore`, browser `WsConnector`, mobile secure storage.
4. Call `FlutterDataExporter` and `import_flutter_data` at first launch of the bridged app.
5. Move `sqlite3` from `dev_dependencies` to `dependencies` in `pubspec.yaml`. `lib/` code imports it.
6. Resolve two unmaintained transitive crates that cargo-deny reports (`fxhash`, `proc-macro-error2`, both through `lwk_wollet`).
