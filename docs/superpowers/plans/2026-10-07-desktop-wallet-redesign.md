# Desktop wallet redesign

Approved direction: retain Quiet Navy, Geist and the pink primary action; improve hierarchy and space before decorative effects. Use synthetic data for the visual walkthrough. Preserve native wallet contracts, privacy and transaction safeguards.

## Implementation

- [x] Shared page/header widths, compact overview actions, assets and activity columns; consistent typography, surfaces, focus and restrained motion.
- [x] Swap editing and explicit review in one focused area, retaining expiry and stale-quote guards.
- [x] Pix form/payment replacement, receive optional request fields and QR-matched copy action, aligned send flow.
- [x] Asset balance hierarchy, transaction details, settings alignment, separate recovery confirmation and PIN creation.
- [x] Local synthetic preview, frontend tests/typecheck/build, visual walkthrough, final code review.

## Verification

Behavior tests cover explicit Swap review and expiry, Pix creation/payment navigation, receive copy behavior, and setup progression. Run the full frontend suite, TypeScript and production build. Inspect representative screens in the synthetic preview including compact windows, privacy and reduced motion. Native integration behavior is unchanged; browser preview is not a native Tauri integration test.

## Constraints

No new UI vendor dependency or backend contract changes. No real funds, keys or external payments. Preserve the unrelated mobile Podfile.lock edit. Glass is progressive enhancement for navigation only, with opaque fallback and reduced-transparency support.

## Results

- Behavior changes were exercised with failing tests before implementation. Final suite: 73 tests across 34 files passed. The setup test also verifies successful native-client handoff with the checked words and PIN; receive verifies both copy modes.
- TypeScript and production Vite build passed. Vite reports a chunk-size advisory (836 kB main JS before gzip); no new dependency was introduced. No synthetic-preview markers were found in production output.
- Safari visual walkthrough covered overview, privacy masking, Swap editing/review, Receive, Pix form/payment, Send, asset details, activity details and settings. Responsive inspection included the desktop minimum 1024 × 700. Longer forms remain scrollable at that height.
- Independent final code review identified focus loss during step replacement. Fixed with shared `FlowStep` and verified with component and integration tests. No other important findings were reported.
- Reduced motion/transparency rules were checked in source; OS preference emulation and native Tauri smoke testing were not performed. No changes were committed or published.
