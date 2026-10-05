# Flutter bridge for mooze-core

Date: 2026-10-05. Spec: `docs/superpowers/specs/2026-10-05-mooze-core-design.md`.

## Goal

The Flutter app calls `mooze-core` through flutter_rust_bridge 2.11.1.
The old wallet libraries (`lwk-dart`, `bdk_dart`) leave the app in a later phase.

## Findings that shape the plan

- The app runs two wallet stacks. The v2 services in `lib/app/di/v2_providers.dart` are one.
  The v1 repository in `lib/features/wallet/di/providers/wallet_repository_provider.dart` is the other.
  Balance, transaction list, drain and receive-QR screens still use v1.
- iOS links plugins as dynamic frameworks (`use_frameworks!`).
  The new library can therefore live next to `lwk-dart`, although both contain secp256k1 0.10.1.
- `lwk-dart` downloads precompiled binaries at build time. The new plugin always builds from source.

## Phase 1 (this change)

1. Create the plugin package `packages/mooze_core_bridge`.
   - `rust/`: crate `mooze_core_bridge`. It depends on `mooze-core` with the `electrum` feature.
   - `cargokit/`: copied from `lwk-dart`, with precompiled binaries off.
   - iOS podspec, Android Gradle file and macOS podspec for host tests.
2. Implement the native ports in the bridge crate.
   - `FileKv`: one file per key, atomic writes with temp file and rename.
   - System clock, tokio `spawn_blocking` for Electrum, reqwest for HTTP.
3. Expose a small API: open the core, run the one-time import, and the wallet calls that the
   Dart `BitcoinWalletService` and `LiquidWalletService` interfaces need.
4. Generate the Dart bindings.
5. Write Dart services that implement both interfaces over the bridge.
   Select them with the compile-time flag `MOOZE_CORE` (default off).
6. With the flag on, run the one-time data import at boot.
7. Verify: Rust tests, Dart tests that load the native library on macOS, Android and iOS builds.

## Phase 2 (later)

1. Test the flag on real devices, then turn it on by default.
2. Move the v1 repository to the bridge.
3. Remove `lwk-dart`, `bdk_dart` and their Dart code.
4. Bridge PIX, SideSwap and auth. Add the WebSocket and secure-storage ports.

## Status of phase 1

Done:
- Plugin `packages/mooze_core_bridge` with the bridge crate, cargokit, iOS, macOS and Android files.
- Dart services `CoreBitcoinWalletService` and `CoreLiquidWalletService`, plus `ServiceBackedWalletRepository` for the v1 screens.
  All are selected with `--dart-define=MOOZE_CORE=true`. The default build is unchanged.
- One-time data import at the first connect with the flag on.
- Verified: host Dart test calls the native library, the Rust library compiles for iOS (simulator and device)
  and builds and links for Android arm64 with NDK 27.

- Full iOS simulator build with the flag on (Xcode 27, iOS 27 simulator). The app launches and runs.
  The bundle contains `mooze_core_bridge.framework` next to `lwk.framework` and `bdk_dart_ffi.framework`.

- Full Android debug build with the flag on. The APK contains `libmooze_core_bridge.so` next to
  `liblwk.so` and `libbdk_dart_ffi.so`.

Open:
- Gradle 8.10.2 cannot run on the Java 25 bundled with Android Studio. Each machine needs
  `flutter config --jdk-dir <Java 23 home>`, or the project needs Gradle 9.1+ (with AGP 8.13+).
- Exercise the bridge in the Android and iOS apps: the core opens at the first wallet connect, so create or import a test wallet.
- The address explorer still needs raw lwk/bdk handles. With the flag on, it shows an error.
- `libc` is pinned to 0.2.189 in the bridge crate. 0.2.190 breaks `backtrace` on iOS.

## Build on the external disk

The worktree `/Volumes/Kingston/mooze-client-build` holds a copy of the current changes.
Builds there keep `build/` and `.dart_tool` on the external disk.

1. Refresh the copy of the changes:
   ```
   cd /Users/havismat/mooze-client
   git status --porcelain --untracked-files=all | awk '{print $NF}' | grep -v -E '/target/|/build/|\.dart_tool/|\.vscode/' > /tmp/sync.txt
   rsync -a --files-from=/tmp/sync.txt ./ /Volumes/Kingston/mooze-client-build/
   ```
2. iOS simulator. Keep Xcode's DerivedData on the external disk with `-derivedDataPath`.
   Copy the git-ignored `lib/**/*.g.dart` files into the worktree first, or the Dart build fails.
   Target one simulator device, not `generic/platform=iOS Simulator`: with both architectures,
   Flutter 3.41 misreads the `lipo` output of Xcode 27 and stops in `debug_unpack_ios`.
   If `xcode-select` points to another Xcode, prefix the commands with
   `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer`.
   ```
   cd /Volumes/Kingston/mooze-client-build
   F=/Users/havismat/fvm/versions/3.41.9/bin/flutter
   $F pub get
   $F build ios --simulator --debug --config-only --dart-define=MOOZE_CORE=true
   xcodebuild -workspace ios/Runner.xcworkspace -scheme Runner -configuration Debug \
     -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 18 Pro' \
     -derivedDataPath /Volumes/Kingston/DerivedData build
   ```
3. Android. Keep the Gradle caches on the external disk with `GRADLE_USER_HOME`.
   Debug builds also compile the x86 and x86-64 emulator libraries (cargokit adds them), so the
   first build takes about 40 minutes. Release builds compile only the requested architecture.
   If `ANDROID_NDK_HOME` points to an NDK that is not installed, set it to the NDK in
   `android/app/build.gradle.kts` (27.0.12077973) for the build command.
   ```
   cd /Volumes/Kingston/mooze-client-build
   GRADLE_USER_HOME=/Volumes/Kingston/gradle $F build apk --debug --target-platform android-arm64 --dart-define=MOOZE_CORE=true
   ```

## Phase 2

1. Validate on a device build. Done: `integration_test/core_bridge_test.dart` runs inside the iOS app on the
   simulator. It connects the test mnemonic over Electrum and syncs 273 Bitcoin and 380 Liquid transactions,
   the same counts as the host test.
2. Move the address explorer and the dev raw-transaction screen to the core.
3. Remove `lwk-dart`, `bdk_dart`, the old services, the legacy datasources and the `MOOZE_CORE` flag.
4. Bridge auth, PIX and SideSwap, in this order, one bridge change at a time:
   - Ports: secure storage through Dart callbacks to `flutter_secure_storage`, WebSocket with
     `tokio-tungstenite` 0.30.0 (identity checked: snapview repositories, same maintainers since years).
   - rustls has both the ring and the aws-lc backends compiled in. Install ring as the process default
     when the core opens, before any TLS connection, or rustls panics.
   - Session tokens keep the `flutter_secure_storage` key names (`jwt`, `refresh_token`).

### Status of phase 2

Done:
- Step 1: the device integration test passes on the iOS simulator.
- Step 2: the address explorer and the dev raw-transaction screen use the core.
- Step 3: `lwk-dart` (submodule), `bdk_dart`, the old services, the legacy datasources, the v1 lwk/bdk repository and
  the `MOOZE_CORE` flag are removed. The core is the only wallet path.
- Step 4: auth, PIX, favorite payers, SideSwap swaps and pegs run on the core.
  - Bridge ports: secure storage through Dart callbacks, WebSocket through `tokio-tungstenite`.
  - Dart: `CoreSessionManagerService`, `MoozeApiClient` (backend calls through `apiRequest`), `CorePixRepository`,
    `CoreFavoritePayersRepository`, `CoreSwapRepository`, `CorePegOrchestrator`, `CorePegTracker`.
- The 83 old test failures are fixed (stale tests, no app code changed).

Behavior changes to know:
- Boot waits for the login session, with a 3 s limit. An offline start can take up to 3 s longer.
- Device metrics are collected once per launch, not per request. GET requests no longer carry them.
- The peg audit row is written after funding, not at order creation.
- Unused drift tables stay in the schema for the one-time import: Deposits, Pegs, FavoritePayerEntries.

Open gaps:
- PIX send/withdraw: the core has no API. The Dart mock stays.
- `PixClient` does not refresh and retry on 401, unlike `apiRequest`.
- Without an open SideSwap event stream, an idle socket can make the next call fail once before it reconnects.
- The private `_extractBip21Amount` helper has no caller after a deliberate change. Remove it in a cleanup.
