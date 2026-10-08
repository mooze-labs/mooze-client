# Shared color palettes

`colors.json` is the source for the active mobile and desktop light/dark colors. Edit it, then run these commands from the repository root:

```sh
npm run tokens:generate
npm run tokens:test
npm run tokens:check
```

Generation uses Node's standard library and requires no Flutter installation or network access. Commit both outputs with the palette change:

- `apps/frontend/src/styles/colors.generated.css`
- `apps/mobile/lib/themes/generated/app_palette.dart`

Do not edit generated outputs directly. CI rejects stale outputs. Flutter consumes committed Dart constants, so its normal build does not need Node.

Each mode has the same semantic keys. Literals use `#RRGGBB` or `#RRGGBBAA` (alpha last); Dart generation converts them to ARGB. `{ "ref": "primary" }` refers to another token in the same mode. Missing references and cycles are errors.

Mobile's existing `AppColors` and `AppExtraColors` APIs remain adapters. The page background maps to `surfaceDim`, cards to `surfaceContainerLowest`, navigation to `surfaceContainerLow`, and secondary actions to `actionButtonBackground`. All explicitly configured mobile colors are preserved; unspecified Material defaults stay in Flutter's constructors.

Desktop maps these roles in `tokens.css`, which also owns hover, pressed, tint, focus, shadow, and separator recipes. Color-named variables there are compatibility aliases. Asset identity colors and QR black/white remain intentional exceptions. Any proposed shared-palette adjustment should be reviewed in both apps, including its contrast against actual surfaces.

Desktop preferences are local under `mooze.theme`, independent of wallet settings. System follows the OS; Light and Dark override it. The synthetic preview uses memory only: see `apps/frontend/src/testing/PREVIEW.md` for reproducible URLs.
