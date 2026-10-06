# mooze-client

Monorepo: `apps/mobile` (Flutter), `crates/mooze-core` and `crates/mooze-app` (Rust), `packages/mooze_core_bridge` (flutter_rust_bridge), `apps/frontend` and `apps/desktop` (React, Tauri; in progress).

## Design System
Always read DESIGN.md before making any visual or UI decision in `apps/frontend` or `apps/desktop`.
All font choices, colors, spacing, and aesthetic direction are defined there.
Do not deviate without explicit user approval.
In QA mode, flag any code that doesn't match DESIGN.md.
The Flutter app in `apps/mobile` keeps its own theme under `lib/themes`; DESIGN.md does not govern it.
