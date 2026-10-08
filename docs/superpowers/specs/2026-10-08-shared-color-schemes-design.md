# Shared mobile and desktop color schemes

## Purpose and scope

Use the mobile application's active light and dark palettes in both applications. Desktop gains System, Light, and Dark appearance preferences. The user approved mobile as the palette reference and the shared-token approach on 2026-10-08.

Preserve platform-specific layout, typography, navigation, and component geometry. Preserve mobile's existing theme selection and persistence. Theme preferences remain local to each installation; they do not sync through wallet settings or require an unlocked wallet. No backend, Rust wallet API, or third-party design-system service is needed.

## Existing behavior

- `apps/mobile/lib/themes/app_colors.dart` supplies the active `darkColorScheme` and `lightColorScheme`. `lightColorScheme2` is not selected by `AppTheme` and is not a source for this migration.
- `AppExtraColors` supplies warning, text, icon, shimmer, and custom surface roles. `AppColorsProxy` and `theme_context_x.dart` expose these to widgets.
- Mobile uses `surfaceDim` for scaffold backgrounds and `surfaceContainerLowest` for cards. Matching desktop backgrounds to the mobile `surface` property would produce the wrong mapping.
- Mobile's `themeModeProvider` persists `system`, `light`, or `dark` under `appThemeMode`, defaulting to System.
- Desktop's `tokens.css` contains a single dark palette. Additional literal colors in `main.css`, `polish.css`, and `layout.css` encode dark-only interaction and status treatments.
- Desktop's display preferences are loaded and saved through the wallet session. Appearance must be independent so it also applies to onboarding and locked screens.
- Desktop has a development-only synthetic preview with its own React entry point. It must use the same theme implementation without persisting preview preferences.

## Shared palette contract

Add `packages/design-tokens/colors.json` as the authoritative, framework-independent source. It contains a schema version and light/dark objects with identical token keys. Use semantic role names; keep Flutter property mappings in platform adapters rather than requiring consumers to understand Flutter.

Represent literal colors as `#RRGGBB` or `#RRGGBBAA`, with alpha last. The generator explicitly converts RGBA to Dart ARGB. Role aliases are permitted only as explicit references, validated for missing targets and cycles. Resolve aliases before emitting outputs.

The initial definition captures all explicitly configured roles from the two active mobile `ColorScheme` constants and both `AppExtraColors` instances. Preserve the exact current values, including alpha values such as `Colors.white60`. Leave unspecified Material roles using the same constructors and defaults; this task does not silently replace them with invented colors.

Core semantic mappings are:

| Shared role | Mobile source | Dark | Light |
| --- | --- | --- | --- |
| background | surfaceDim | #000000 | #E2E4EA |
| card | surfaceContainerLowest | #0A0A0A | #FFFFFF |
| surface | surface | #141722 | #F5F6FA |
| surfaceLow | surfaceContainerLow | #111111 | #F5F6FA |
| surfaceRaised | surfaceContainerHigh | #1C1C1C | #E2E4EA |
| surfaceHighest | surfaceContainerHighest | #26252A | #E2E4EA |
| primary | primary | #EA1E63 | #EA1E63 |
| onPrimary | onPrimary | #FFFFFF | #FFFFFF |
| textPrimary | onSurface | #FFFFFF | #1A1A2E |
| textSecondary | extra.textSecondary | #9194A6 | #5C5F72 |
| textTertiary | extra.textTertiary | #7C7C7C | #6B6B6B |
| border | outline | #2D2E2A | #B8BCC6 |
| success | tertiary | #32B153 | #16A34A |
| error | error | #D73131 | #DC2626 |
| warning | extra.warning | #FB8C00 | #E65100 |
| warningForeground | extra.onWarning | #FFB74D | #F57C00 |
| icon | extra.primaryIconColor | #9DB2CE | #5B7A9A |
| actionBackground | extra.actionButtonBackground | #2B2D33 | #D1D5DB |

Existing mobile text tiers remain distinct even where their names do not form a monotonic contrast hierarchy. Migration must not normalize them or select the unused alternative light palette.

## Generation and platform adapters

Implement a small Node script using standard-library facilities. Keep validation, alias resolution, and CSS/Dart rendering as pure functions; isolate file reads and writes in the CLI. No network, Flutter SDK, or dependency installation is required to regenerate tokens.

Commit generated CSS and Dart outputs so normal mobile builds do not require Node. Add generation and check commands at the repository root. Check mode fails on malformed colors, inconsistent keys, broken references, or stale generated outputs without modifying files. Add the check to the existing CI workflow for relevant changes.

Generated CSS contains light and dark semantic variables scoped to the root appearance attribute. `tokens.css` keeps fonts, Tailwind bindings, and compatibility aliases. Generated Dart constants are imported by the existing `AppColors` and `AppExtraColors` definitions; widgets, constructors, `copyWith`, and `lerp` retain their interfaces. Remove the unreferenced alternative light palette after verifying there are no consumers.

Map desktop background to `background`, actual cards to `card`, navigation to `surfaceLow`, raised controls to `surfaceRaised`, and secondary action buttons to `actionBackground`. Audit usages individually: the current `--surface` variable serves multiple component roles and cannot universally map to one mobile surface. Existing color-named variables can remain temporary aliases while consumers migrate to semantic names.

Desktop uses primary for primary actions, text links, selection indicators, and focus rings. Positive and negative statuses use success and error. Existing blue information/icon treatments use the shared icon role; asset identity colors remain unchanged.

## Desktop appearance state

Define `ThemePreference = "system" | "light" | "dark"` and `ResolvedTheme = "light" | "dark"`. A pure `resolveTheme(preference, systemTheme)` function defines resolution. Parse unknown or missing saved values as System.

Use a dedicated local storage key, `mooze.theme`, independent of `mooze.display`. A small root provider owns the selected preference and applies the resolved appearance. It observes system appearance changes, applies them only when System is selected, and cleans up listeners. Switching back to System uses the current OS appearance immediately. Cross-window storage updates use the same parser and resolver.

Apply the root appearance attribute and CSS `color-scheme` before mounting React. Use a same-origin external startup entry compatible with the existing CSP; do not add inline script allowances. Share parsing and resolution with the provider. CSS provides system-aware defaults before initialization. Verify the production build does not briefly paint the opposite theme, including with a saved override.

Place the provider above wallet/session-dependent views and the non-desktop fallback. Make Tailwind dark variants depend on the resolved root attribute, not independently on OS appearance, including portal content attached to the document body.

Storage access failures do not prevent rendering or changing the current in-memory selection. Show a nonblocking localized message when a user-initiated persistence operation fails, since the preference may not survive restart. No wallet mutation or authentication is triggered by changing appearance.

Add an Appearance selector to desktop Display settings with System, Light, and Dark choices in Portuguese, English, and Spanish. A selection takes effect immediately. It is not disabled by unrelated wallet display-preference saves.

The synthetic preview uses the same provider with an in-memory persistence adapter and an optional validated `theme` query parameter for reproducible checks. Production continues to use local storage. Preview does not overwrite the user's theme preference.

## Interaction and special color treatments

Replace dark-only literals in all three desktop stylesheets and preview chrome. Express hover, pressed, selected, focus, status tint, skeleton, shadow, and overlay colors through tokens or explicit derived treatments.

For desktop-specific interaction treatments, use documented formulas: primary hover mixes primary with 8% black; neutral hover mixes the component surface with 4% textPrimary; pressed neutral surfaces use 8%; selection/status tints use 10% of their semantic foreground; subtle separators use textPrimary at 8%; focus halos use primary at 20%. Keep these recipes centralized in CSS. These are desktop interaction recipes, not changes to mobile's base palette.

Preserve black-on-white QR rendering, token artwork, and intentional brand colors. Scrims and shadows may retain black through semantic roles; fixed black or white is not automatically a theme defect. Review each occurrence rather than applying a global replacement.

Check actual foreground/background pairings for text, status labels, controls, and focus indicators. Exact reuse of the existing mobile palette is not a claim that all current combinations meet accessibility targets. If a shared role requires a color adjustment, report the measured issue and obtain a design decision before changing that role in either application. Do not silently diverge desktop colors to hide a contrast issue.

## Validation and acceptance

1. Generator checks cover RGBA-to-ARGB conversion, invalid input, alias errors, equal mode keys, deterministic output, and stale-file detection.
2. Desktop state tests cover default System mode, stored overrides, invalid values, OS changes, switching back to System, storage events, failed storage, and listener cleanup.
3. Settings tests verify immediate selection changes, persistence, translations, and independence from wallet display saves.
4. Mobile checks confirm both active schemes and extras preserve their pre-migration values and that its existing System/Light/Dark flow still works. Run Flutter analysis and relevant theme/widget tests.
5. Run frontend tests, typecheck, production build, and generated-token check. Inspect the built startup path under the existing CSP.
6. Visually check onboarding, unlock, dashboard, send, receive, swap, history, settings, menus, and dialogs in light and dark. Include keyboard focus, disabled inputs, validation errors, skeletons, and status notices. Confirm startup with a saved preference opposite to OS appearance.
7. Verify desktop native window chrome follows the resolved mode where a supported native adapter is required. Keep any native synchronization at the platform boundary; the palette and resolver remain browser-independent. Native title-bar behavior requires a Tauri run and cannot be proven by the synthetic preview alone.

Success means both applications derive shared color values from one checked-in definition, desktop supports all three preferences throughout the app lifecycle, mobile preserves its active palettes and theme behavior, and there are no unexplained dark-only color treatments in desktop UI.

## Alternatives and tradeoffs

Copying values directly into desktop CSS is smaller initially but permits silent divergence. Reading Dart source at runtime or importing Flutter into the desktop toolchain couples the applications unnecessarily. Generated platform adapters provide one editable source while retaining native build independence. The cost is a small generator and a drift check, both owned in this repository.
