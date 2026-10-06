# Funded local wallet checks

Uses the same BDK/LWK wallet engines and bounded signing methods as the desktop,
with `nigiri-rs` as a development-only faucet/mining client. This separate crate
does not add Nigiri dependencies or regtest configuration to the shipped desktop.

Start an existing Nigiri installation with Bitcoin and Liquid:

```sh
DOCKER_CONTEXT=orbstack nigiri start --liquid
cargo run --locked --manifest-path tools/wallet-regtest/Cargo.toml -- --funded-local-regtest
```

Omit `DOCKER_CONTEXT` if the current Docker context already points to your engine.
The harness uses Nigiri's loopback defaults: RPC ports 18443/18884 and Esplora
ports 30000/30001. It never starts, stops, resets, or removes services.
It mines fresh Bitcoin blocks before waiting for Electrs so a saved chain with
an old tip can leave initial sync. Both chains use an explicit 1 sat/vB test fee
rate, matching this Nigiri installation's Liquid relay minimum.

Each invocation creates a random disposable mnemonic, kept only in memory. It
mines blocks, spends local faucet funds, and issues a fresh local asset. Run it
serially, away from tests that assume fixed block heights. A failed invocation
may already have issued an asset or broadcast a transaction; inspect the output
and local chain before retrying. Do not use these disposable wallets for funds
you intend to keep.

Checks cover native and confidential asset receipts, exact balances, signing
revocation, amount/fee binding, exact sends, BTC/L-BTC Max, confirmation, and
cache reopening followed by synchronization. Public transaction IDs are printed;
mnemonics and private descriptors are not.

The issued `MZT` asset has Nigiri mint's precision zero. It is **not** the approved
public Liquid testnet `TEST` asset, which retains its configured ID and precision
eight. These checks exercise wallet mechanics; they do not claim public TEST
funding, native GUI interaction, or the complete desktop acceptance suite.
Minting stays in the node wallet; `faucet_asset(Amount::from_sat(...))` then funds
the disposable wallet. Elements RPC mint quantities use a 100-million base-unit
scale independently of asset metadata precision.

The core's regtest mapping now uses Elements local consensus parameters and
`el1` addresses. Old disposable regtest caches made when regtest incorrectly
mapped to Liquid testnet must not be reused. Mainnet and testnet mappings retain
their existing derivation behavior.

## Verified on 2026-10-06

Nigiri 0.5.16 on OrbStack, `nigiri-rs` 0.6.0; the command above exited zero.

| Check | Result |
| --- | --- |
| Receive BTC and confidential L-BTC | 200,000 base units each |
| Receive local issued asset | 100,000 base units |
| BTC exact send and authorization revocation | Passed; send confirmed |
| L-BTC and issued-asset exact sends | 10,000 base units each; confirmed |
| L-BTC Max | 189,158 received; fee bounded at 191 sats |
| BTC Max | 189,749 received; fee bounded at 110 sats |
| Reopen cached wallets and resync | Native balances zero; issued asset 90,000 |

The corresponding regression run passed 325 core tests and the frozen Flutter
snapshot, 34 desktop host tests, 27 frontend tests and typechecking. One existing
core test remains ignored. The mobile suite passed 679 tests with FVM 3.41.9.
