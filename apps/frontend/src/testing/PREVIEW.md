# Synthetic desktop preview

Run `npm run dev -w @mooze/frontend` from the repository root and open:

- `http://127.0.0.1:1420/preview.html` — unlocked wallet
- `http://127.0.0.1:1420/preview.html?session=empty` — creation/import
- `http://127.0.0.1:1420/preview.html?session=locked` — unlock screen

Routes use hashes, for example `preview.html#/swap`. The preview renders the production screen components with a typed in-memory `DesktopClient`. It imports no native client, makes no external requests, and does not persist preferences or wallet data. Reloading resets fixtures. Payment codes and recovery words are deliberately invalid examples. Sending, confirming a swap, recovery disclosure, removal and credential changes are unsupported.

The separate entry is development-only and is not included in the default production build. It verifies presentation and interaction; it is not a Tauri/native integration test.
