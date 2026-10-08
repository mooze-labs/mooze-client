# Shared Color Schemes Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [x]`) syntax for tracking.

**Goal:** Match desktop to mobile's active palettes and support persistent System, Light, and Dark appearance across the desktop lifecycle.

**Architecture:** A repository-owned JSON palette generates committed CSS and Dart constants. Existing mobile theme adapters preserve widget interfaces; a separate desktop appearance provider resolves preferences through pure functions and delegates storage, DOM, and native effects to adapters.

**Tech Stack:** Node standard library, React 19, TypeScript, Vite 6, Tailwind 4, Vitest, Flutter 3.41.9, Dart, existing Tauri 2 APIs.

**Spec:** `docs/superpowers/specs/2026-10-08-shared-color-schemes-design.md`

## Global Constraints

- Preserve platform-specific layout, typography, navigation, and component geometry.
- Preserve mobile's existing theme selection and persistence.
- Theme preferences remain local to each installation; they do not sync through wallet settings or require an unlocked wallet.
- No backend, Rust wallet API, or third-party design-system service is needed.
- No network, Flutter SDK, or dependency installation is required to regenerate tokens.
- Preserve the exact current values, including alpha values such as `Colors.white60`.
- Use a dedicated local storage key, `mooze.theme`, independent of `mooze.display`.
- Do not add inline script allowances.
- Preserve black-on-white QR rendering, token artwork, and intentional brand colors.
- If a shared role requires a color adjustment, report the measured issue and obtain a design decision before changing that role in either application.

## Review Focus

- Storage getter/read/write throws: app remains usable, selection updates in memory, failed saves are reported (Task 3).
- React StrictMode and repeated mounting: listeners do not multiply or outlive providers (Task 3).
- Saved preference opposes OS appearance: onboarding, portals, and the initial rendered frame agree (Tasks 3 and 6).
- Native calls complete out of order or fail: the latest requested preference wins without blocking wallet views (Task 3).
- Eight-digit colors and alias chains: both outputs preserve alpha and resolve identically; cycles fail clearly (Task 1).

## File structure and boundaries

| Files | Responsibility |
| --- | --- |
| `packages/design-tokens/colors.json` | Authoritative versioned palettes and aliases |
| `tools/design-tokens/palette.mjs`, `generate.mjs`, `palette.test.mjs` | Pure validation/rendering, CLI IO, generator tests |
| `apps/frontend/src/styles/colors.generated.css` | Generated mode-specific CSS variables |
| `apps/mobile/lib/themes/generated/app_palette.dart` | Generated const Dart colors |
| `apps/mobile/lib/themes/app_colors.dart`, `app_extra_colors.dart` | Existing mobile adapters |
| `apps/frontend/src/theme/model.ts` | Pure preference parsing and resolution |
| `apps/frontend/src/theme/storage.ts`, `dom.ts`, `native.ts` | Browser storage, root appearance, native effects |
| `apps/frontend/src/theme/theme-provider.tsx` | React lifecycle and consumer API |
| `apps/frontend/src/theme/startup.ts` | Production pre-mount initialization |
| `apps/frontend/src/features/settings/appearance-setting.tsx` | Localized selector and persistence feedback |
| Existing desktop styles, root entries, settings, preview, workflows | Integration |

Do not reorganize unrelated preferences or wallet code. Generated artifacts have headers directing edits to `colors.json`.

### Task 1: Shared token generation and drift detection

**Files:** Create the palette and three generator files above; create both generated outputs; modify `package.json` and `.github/workflows/desktop.yml`.

**Interfaces:** `validatePalette(input: unknown) -> Palette`, `resolvePalette(palette: Palette) -> ResolvedPalette`, `renderCss(palette: ResolvedPalette) -> string`, `renderDart(palette: ResolvedPalette) -> string` exported from `palette.mjs` (JSDoc types). Palette shape: `{version: 1, light: Record<string, string | {ref: string}>, dark: same}`. Names are lower camel case; CSS emits kebab-case `--app-*` variables; Dart emits `abstract final class AppPaletteLight` and `AppPaletteDark` with `static const Color` fields. Aliases resolve within their mode.

- [x] Write `palette.test.mjs` with Node's test runner. Assert `#11223344` emits Dart `0x44112233`, `#FFFFFF99` preserves white60, a two-hop alias resolves to the same color, cycles/missing aliases fail, malformed literals and asymmetric mode keys fail, and output ordering is stable independent of JSON key order.
- [x] Run `node --test tools/design-tokens/palette.test.mjs`; confirm failure because implementation is missing.
- [x] Implement the pure interfaces, then the CLI. Extract every explicitly assigned active mobile scheme/extra role; use spec semantic names and aliases for shared values. Include all remaining configured roles without dropping container, inverse, shadow, or extended text values. Do not include `lightColorScheme2`.
- [x] Emit explicit light/dark root attribute selectors plus system-aware defaults when the attribute is absent. Add `tokens:generate`, `tokens:check`, and `tokens:test` scripts. CLI `--check` compares expected bytes without writing; normal mode writes only changed files.
- [x] Add a CLI test with temporary output destinations: generate, alter one output, check nonzero exit, and confirm check left the altered file untouched. Run generator tests and both commands; expect all passing and no changes from a second generation.
- [x] Extend both desktop workflow path filters for `packages/design-tokens/**`, `tools/design-tokens/**`, and `apps/mobile/lib/themes/**`. Add an Ubuntu token-check job using Node 22, running tests and drift check without Flutter or dependency installation.
- [x] Commit only Task 1 files: `feat(theme): generate shared mobile and desktop palette tokens`.

### Task 2: Preserve mobile palettes through generated adapters

**Files:** Modify `apps/mobile/lib/themes/app_colors.dart` and `app_extra_colors.dart`; create `apps/mobile/test/themes/app_palette_test.dart` and `theme_mode_provider_test.dart`. Existing `app_theme.dart`, `app_colors_proxy.dart`, `theme_context_x.dart`, and selector screen are reference consumers, not redesign targets.

**Interfaces:** Consume `AppPaletteLight`/`AppPaletteDark` from Task 1. Preserve `AppColors.darkColorScheme`, `AppColors.lightColorScheme`, `AppExtraColors.dark`, `AppExtraColors.light`, and all existing widget-facing accessors.

- [x] Capture independent expected ARGB maps for every explicitly configured scheme and extra role from the original mobile definitions. Add tests asserting these maps against the live adapters in both modes, including dark `onSecondary == 0x99FFFFFF`. These characterization tests must pass before migration.
- [x] Add provider tests using `SharedPreferences.setMockInitialValues` and a `sharedPreferencesProvider` override: absent/invalid values select System; saved light/dark restore; each selection persists under `appThemeMode`. Verify `AppTheme` produces expected scaffold and card colors through a widget context. Run these tests before migration to establish the baseline.
- [x] Replace mobile literals with generated constants while retaining constructors and unspecified Material defaults. Preserve `copyWith`/`lerp`. Search the entire repository for `lightColorScheme2`; remove it only if no consumers exist.
- [x] From `apps/mobile`, run `fvm flutter test test/themes test/shared/widgets/buttons/primary_button_test.dart` and `fvm flutter analyze`; use the installed pinned SDK directly if FVM is unavailable. Record pre-existing failures separately. Run `npm run tokens:check` at root. Expect palette and preference behavior unchanged.
- [x] Commit Task 2 files: `refactor(theme): consume shared palette in mobile adapters`.

### Task 3: Independent desktop appearance lifecycle

**Files:** Create `apps/frontend/src/theme/{model,storage,dom,native,startup}.ts`, `theme-provider.tsx`, `model.test.ts`, `theme-provider.test.tsx`, `native.test.ts`; modify `apps/frontend/index.html`, `apps/frontend/src/main.tsx`, and `apps/desktop/src-tauri/capabilities/main.json`.

**Interfaces:** Export `ThemePreference = 'system' | 'light' | 'dark'`, `ResolvedTheme = 'light' | 'dark'`, `parseThemePreference(value: unknown): ThemePreference`, and `resolveTheme(preference: ThemePreference, system: ResolvedTheme): ResolvedTheme` from `model.ts`. Export `ThemeStorage = {read(): unknown; write(value: ThemePreference): void; subscribe(listener: (value: unknown) => void): () => void}` and browser/memory factories from `storage.ts`. `applyTheme(root: HTMLElement, theme: ResolvedTheme): void` sets `data-theme` and `style.colorScheme`. `ThemeProvider` takes storage, initial preference, optional async native application callback, and children. `useTheme()` exposes `{preference, resolvedTheme, setPreference, persistenceError}`; error is a boolean for presentation to localize. `setNativeTheme(preference: ThemePreference): Promise<void>` is an isolated platform adapter.

- [x] Write model tests for all six preference/system combinations and invalid saved values. Add provider tests for storage getter/read/write failures, OS changes, selecting System after an override, cross-window removal, ignored unrelated storage events, and StrictMode listener cleanup. Assert a failed write still changes the root and exposes `persistenceError`, while a later successful save clears it.
- [x] Run `npm run frontend:test -- src/theme`; verify new tests fail for missing implementations.
- [x] Implement pure model functions and storage/DOM adapters. Storage factories defer localStorage access so a throwing getter is catchable. Memory storage never reads or writes browser persistence. Provider owns effects and listens to `(prefers-color-scheme: dark)` with cleanup; storage events do not echo writes.
- [x] Implement startup initialization as the external entry referenced by production HTML. Resolve and apply theme before dynamically importing `main.tsx`; use the same model/storage functions as the provider, with provider initialization reading the established preference. Wrap the entire production app above wallet providers. Keep the CSP unchanged. Do not claim first-paint correctness from jsdom; verify the built entry in Task 6.
- [x] Implement native adapter using installed `@tauri-apps/api` declarations: explicit mode passes `light`/`dark` to `getCurrentWindow().setTheme`, System passes `null`. Guard browser execution with `isTauri`. Add only `core:window:allow-set-theme` to the main capability. Serialize native applications so the most recent preference is ultimately applied. Observe rejected calls without failing web rendering; refresh the OS media-query result after native reset to System, since a native override may influence webview appearance.
- [x] Add adapter tests for light/dark/null mapping, browser no-op, rejection, and rapid dark→light→system changes with delayed promises. Assert the final native call resets System and web appearance remains usable on failure. Run theme tests and `npm run frontend:typecheck`; expect pass.
- [x] Commit Task 3 files: `feat(theme): add independent desktop appearance lifecycle`.

### Task 4: Apply semantic palettes throughout desktop styling

**Files:** Modify `apps/frontend/src/styles/{tokens,main,polish,layout}.css`; inspect `apps/frontend/src/ui/button.tsx` and QR/asset components for intentional fixed colors. No component geometry changes.

**Interfaces:** Consume generated `--app-*` variables and root `[data-theme]`. Keep current CSS aliases as compatibility adapters, but distinguish card, navigation, raised control, and action-button roles at their use sites.

- [x] Record representative current desktop screenshots using the synthetic preview and inventory color literals with `rg -n '#[0-9a-fA-F]{3,8}\b|rgba?\(|\bwhite\b|\bblack\b' apps/frontend/src`. Classify actual UI colors versus QR/artwork exceptions; use this inventory for review rather than a brittle test banning all literals.
- [x] Import generated colors from `tokens.css`, replace root literals with semantic aliases, and define dark variants against the resolved root attribute including descendants. Map body background/text and native `color-scheme` consistently.
- [x] Audit all three application stylesheets. Assign cards to card, navigation to surfaceLow, raised controls to surfaceRaised, and secondary action buttons to actionBackground. Replace legacy pink/blue/gold/green usage by role, preserving asset identities and QR backgrounds.
- [x] Centralize spec recipes: primary hover 8% black; neutral hover/pressed 4%/8% textPrimary; status/selection tint 10% semantic foreground; separator 8% textPrimary; focus halo 20% primary. Use palette shimmer endpoints and scrim/shadow roles. Preserve existing interaction timing and geometry.
- [x] Run `npm run frontend:build`. Inspect computed colors for body, card, primary button, input, status, and portal in both modes; compare to spec mappings. Review focused/hover/disabled states and QR output. Defer full visual matrix to Task 6; record any shared-palette contrast concern for a user decision rather than silently changing values.
- [x] Commit Task 4 files: `style(theme): match desktop surfaces and states to mobile palettes`.

### Task 5: Settings and reproducible preview integration

**Files:** Create `apps/frontend/src/features/settings/appearance-setting.tsx` and `appearance-setting.test.tsx`; modify `display-page.tsx`, its existing test, `src/i18n/{pt-BR,en,es}.json`, `src/testing/preview.tsx`, and `src/testing/PREVIEW.md`.

**Interfaces:** Consume `useTheme()` and the in-memory storage factory from Task 3. AppearanceSetting is independent of wallet preference saves. Preview accepts `?theme=system|light|dark` in addition to its existing session query and hash route.

- [x] Write selector tests with a real ThemeProvider and fake storage. Assert selection changes appearance immediately, saves the complete preference string, does not call wallet `saveDisplay`, remains enabled during unrelated saves, and exposes localized save-failure feedback. Exercise all three locales and choices.
- [x] Run `npm run frontend:test -- src/features/settings/appearance-setting.test.tsx`; confirm failure before implementation.
- [x] Implement using the existing `SelectField`. Add keys/copy for `Aparência`, `Sistema`, `Claro`, `Escuro`, and `Não foi possível salvar a aparência. A alteração vale apenas para esta sessão.` with English and Spanish translations. Render a nonblocking status message on persistence failure. Insert into Display settings without extending wallet Preferences or DTOs.
- [x] Wrap preview in ThemeProvider with memory storage initialized from the validated query value; invalid values use System. Apply preview root appearance before mounting and remove its hardcoded banner colors. Keep preview free from native adapter imports and persistent writes. Update PREVIEW.md with light/dark/locked example URLs.
- [x] Update the existing display-page test wrapper to provide theme state. Run settings tests and frontend typecheck; expect pass. In preview, switch modes, reload, and verify only the URL/default determines the next preview mode and `mooze.theme` is untouched.
- [x] Commit Task 5 files: `feat(settings): expose appearance modes and themed previews`.

### Task 6: Integration verification and final review

**Files:** Update `packages/design-tokens/README.md` with regeneration/mapping instructions; fix only defects found within this feature. Keep validation evidence in the completion report.

**Interfaces:** All prior task outputs; no new product interface.

- [x] Run `npm run tokens:test`, `npm run tokens:check`, `npm run frontend:test`, `npm run frontend:typecheck`, and `npm run frontend:build` from repository root. Expect exit 0; record actual failures without attributing unrun checks as passing.
- [x] Run mobile theme/provider/button tests and Flutter analysis with the pinned SDK. Verify generated Dart is usable without Node during Flutter builds. If SDK/dependency/environment blocks occur, report the exact blocker and retain unaffected validation.
- [x] Review both modes across onboarding, unlock, dashboard, send, receive, swap, history, settings, menus, and dialogs using the synthetic preview. Inspect focus, disabled controls, errors, loading, status labels, token artwork, and QR contrast. Measure problematic text/background pairs and escalate only actual shared-palette changes needed.
- [x] Inspect the built HTML and startup asset under production CSP. Test a stored Light preference with dark OS and the inverse, including a cold load with slowed asset loading. Confirm no opposite-theme app frame; if module scheduling permits an incorrect first paint, correct the external startup ordering without weakening CSP and rerun these cases.
- [ ] Manual follow-up: Run the desktop app to verify native chrome, locked and empty-session rendering, explicit overrides, OS changes while in System, and returning from override to System. On this macOS environment, verify available native behavior and clearly report Windows/Linux cases requiring other hosts.
- [x] Write token maintenance instructions with commands and the rule that generated files are not edited directly. Run `git diff --check`, inspect the final diff for unrelated changes, and commit documentation plus any validated fixes with scoped messages.
- [x] Request the final independent review through the execution workflow selected by the user. Address findings, rerun checks affected by fixes, and report implementation, validation evidence, and remaining platform limitations.

## Execution handoff

Tasks are sequential: generator → mobile adapter → desktop lifecycle → styling → settings/preview → integration validation. Each task ends with its stated validation before committing. No task requires parallel agents.

Recommended execution is Native: one implementer in this session preserves context across the tightly coupled token mappings, startup behavior, and CSS audit, followed by one independent final review. Subagent-driven execution remains an alternative with a fresh implementer and reviewer for each task.


## Execution evidence

Implemented on `feat/shared-color-schemes` in `/private/tmp/mooze-shared-theme`. Final frontend suite: 151 tests passing; token generator: 5 tests passing and drift check clean; mobile palette/provider/button tests: 11 passing. Frontend typecheck/build and native macOS compilation passed. Flutter analysis reports 43 warnings/informational findings outside the changed theme files, with no errors.

Independent review identified three important issues, all addressed: a render-blocking same-origin appearance bootstrap and stylesheet links now precede app content; provider subscription reconciles storage changes made during startup; ordinary secondary buttons resolve to the shared action background. Startup artifact tests exercise delayed bootstrap and opposing saved/system modes. Native rejection recovery has a dedicated test. Pressed styling was corrected with the secondary-button rule change.

Browser inspection covered light/dark onboarding, unlock, dashboard, send, receive, swap, history, settings, and the appearance popup. Production-CSP reload produced no console errors. Theme switching in preview does not write local storage. macOS native UI verification could not be completed because computer-use tooling cannot address the unbundled development binary; Windows/Linux chrome remains unverified. The native build compiled and launched successfully.

The approved palette remains exact. Measured contrast on white is 4.32 for primary pink, 3.30 for success green, and 3.79 for warning orange; those inherited light-mode combinations need a separate shared-palette design decision if stronger text contrast is wanted.

Execution decisions: frontend tests began while independent Flutter generation ran; no shared implementation dependency changed. Native serialization remains scoped to the single root provider, matching the one-window app lifecycle; a future overlapping-root architecture would require adapter-level serialization. Runtime native rejection behavior already recovered correctly, so its review finding required test coverage only. No unresolved reviewer minor findings remain.
