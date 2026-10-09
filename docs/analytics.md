# Product analytics

Mooze uses PostHog's US Cloud project for optional product analytics on desktop
and mobile. Collection is off until the user enables **Share usage data
(optional)** during setup or in Settings. The preference is independent of
accepting the terms. SDK initialization is deferred until consent; events before
consent are dropped, not buffered or backfilled.

## Build configuration

The supplied production project token is public ingestion configuration, not a
personal API key. Never put a personal API key in either application.

Supply desktop configuration through build-time environment variables:

```sh
npm ci
export VITE_POSTHOG_TOKEN="<public project token>"
export VITE_POSTHOG_HOST="https://us.i.posthog.com"
export VITE_ANALYTICS_ENVIRONMENT="production"
npm run desktop:build
```

Environment files are local-only and are not included in the repository. For
development, supply a separate development project's token and set
`VITE_ANALYTICS_ENVIRONMENT=development`. Without a token/HTTPS host, the adapter
is disabled and the toggle is hidden. The Tauri
production and development CSP allow only the US ingestion host in addition to
the existing destinations. A custom host also requires an explicit CSP update.

Mobile uses the FVM version pinned in the root `.fvmrc`. From `apps/mobile`:

```sh
fvm flutter pub get
fvm flutter build appbundle --dart-define-from-file=config/posthog.production.json
fvm flutter build ipa --dart-define-from-file=config/posthog.production.json
```

The existing Android CI builds include this configuration. Plain `fvm flutter run`
has no analytics configuration and sends nothing. Use a separate development JSON
file with `POSTHOG_TOKEN`, `POSTHOG_HOST`, and `ANALYTICS_ENVIRONMENT` for testing.
Mobile supports this integration on iOS and Android. Native auto-initialization
and push-notification tracking are explicitly disabled in the manifest/plist.

## Architecture and identity

Application code sends typed/categorical events to an application-owned consent
controller. Pure event sanitizers whitelist both property names and values.
Platform sinks are the only modules that know about PostHog. Rust core/facade
events and wallet DTOs are never forwarded wholesale.

- Desktop: `apps/frontend/src/analytics`, JavaScript SDK's `no-external` bundle,
  loaded only on opt-in. Scripts stay bundled under Tauri's `script-src 'self'`.
- Mobile: `apps/mobile/lib/shared/analytics`, Flutter SDK provided through Riverpod.
- Consent: local preference `mooze.analytics.consent.v1`, off by default.
- Identity: SDK-generated random anonymous installation identity, no `identify`,
  `alias`, account association, wallet-derived IDs, or cross-device linking.
  Desktop stores it in localStorage and rotates it on withdrawal. Mobile retains
  its anonymous SDK identity across withdrawal/re-enabling. Clearing app data
  clears the application's consent preference; SDK storage follows platform rules.
- Person profiles, session replay, automatic screen/page tracking, surveys,
  feature-flag preloading, automatic exception capture, and push-token collection
  are disabled. Do not add a `PosthogObserver` or replay widget.

## Event contract (version 1)

Both applications use these exact event names and values:

| Event | Properties | Meaning |
| --- | --- | --- |
| `screen_viewed` | `screen_name` | Entering a recognized non-sensitive screen |
| `onboarding_completed` | `method`: `create` / `import` | Wallet setup and PIN saved successfully |
| `send_started` | `chain`: `bitcoin` / `liquid` | User confirms a prepared on-chain send |
| `send_submission_succeeded` | `chain` | Send API reports successful broadcast; not blockchain confirmation |
| `send_failed` | `chain`, `error_code`: `rejected` / `unknown` | Submission failed or outcome is uncertain |
| `pix_request_started` | None | A real PIX receive request is submitted |
| `pix_request_created` | None | The backend returns a PIX receive request; not payment or settlement |
| `pix_request_failed` | None | Request creation fails or its outcome cannot be confirmed |
| `pix_code_copied` | None | Copying the PIX payment code to the clipboard succeeds |
| `pix_deposit_status_changed` | `status`: `pending` / `processing` / `completed` / `failed` / `expired` / `refunded` | An observed deposit moves to a different normalized backend stage |
| `swap_review_opened` | `swap_type`: `liquid` / `peg_in` / `peg_out` | User opens the swap confirmation view |
| `swap_started` | `swap_type` | A confirmed swap is submitted for execution |
| `swap_submission_succeeded` | `swap_type` | Execution reports broadcast (peg funding broadcast for pegs), not final settlement |
| `swap_failed` | `swap_type` | Submission reports failure or an uncertain result |

PIX tracking covers the real receive flow in both apps. Mobile PIX-send still
uses `MockPixSendRepository`; its simulated outcomes are deliberately not tracked.
Desktop currently offers Liquid asset swaps; mobile also covers peg-in/peg-out.
Automatic quote refreshes are not counted as user actions. No amounts, asset IDs,
order IDs, quote IDs, payer documents, payment codes, or provider errors are sent.

PIX status tracking establishes a baseline on first observation and emits only
subsequent stage changes. `paid`, `underReview` and broadcast states count as
processing; only `finished` / `completed` count as completion. The tracker keeps
at most 256 deposit IDs in memory for deduplication, clears them on opt-out, and
never persists or sends them. Desktop observes history refreshes while the PIX
page is mounted; mobile observes repository events and deposit reads. Reopening
historical entries does not backfill completion events. Status changes missed
while the app is closed or opted out are not a reliable settlement ledger.

Screens: `wallet`, `assets`, `asset`, `activity`, `send`, `send_review`, `receive`,
`swap`, `pix`, `settings`, `account`, `onboarding`. Only explicit route mappings
produce events; route parameters, query strings, unknown routes, recovery-word
and PIN screens are excluded. Each app maps the screens it actually exposes.

Every event also carries `platform` (`desktop` / `mobile`), `app_version`,
`environment`, `network`, and `event_schema_version: 1`. Desktop network comes
from the native immutable host configuration; mobile currently runs on mainnet.
Filter production reports by both `environment=production` and `network=mainnet`
to exclude desktop testnet builds.

Mobile failures use `unknown` because the legacy send boundary returns free-form
strings, which cannot reliably distinguish rejection from an uncertain broadcast.
Raw errors are never sent. These events describe product usage, not a financial
ledger; do not use them to determine balances, settlement or transaction success.

## Payload and delivery behavior

No recovery words, PINs, addresses, transaction IDs, balances, amounts, PIX
details, raw logs, or raw error text are included. The desktop `before_send`
hook rebuilds the final property map, retaining only approved properties and
required PostHog protocol fields. Flutter's hook filters Dart-supplied properties;
the native SDK subsequently adds basic app/device/OS/session metadata. Its Dart
hook cannot remove those native fields. That metadata is disclosed in the mobile
opt-in text and privacy policy.

Desktop prefers immediate beacon delivery and drops captures made while offline.
The SDK may fall back to fetch and retry previously captured events. Mobile uses
the native bounded queue (100 events), batching and offline delivery. As approved
for this integration, **opting out stops new capture, but already captured/queued
events may still be delivered**. Mobile closes the SDK after opt-out, which can
flush that existing queue. Events already received by PostHog are not deleted by
opting out. Network/SDK failures do not fail wallet operations.

`$geoip_disable` is sent on approved events. Also disable IP capture in PostHog
project settings; the ingestion service necessarily receives a network source
address. Configure retention and access controls in the Cloud project and align
store privacy disclosures with the actual payload before distributing releases.
No cloud settings are changed by this code.

## Verification

```sh
npm run frontend:typecheck
npm run test -w @mooze/frontend -- --maxWorkers=2
npm run frontend:build
cd apps/mobile
fvm flutter test --no-pub --concurrency=2
fvm flutter analyze --no-pub lib/shared/analytics
```

Tests cover default-off behavior, startup/withdrawal races, storage failures,
event/route allowlists, the real JavaScript SDK's outgoing properties, the real
Dart SDK's native-channel boundary, and the mobile opt-in confirmation UI. They
stub transport and do not send synthetic events into production.

SDK references: [JavaScript](https://posthog.com/docs/libraries/js),
[Flutter](https://posthog.com/docs/libraries/flutter),
[project settings](https://posthog.com/docs/settings/projects).
