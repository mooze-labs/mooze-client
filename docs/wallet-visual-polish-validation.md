# Wallet visual polish — 2026-10-06

The approved everyday-wallet direction now includes shared shadcn controls and restrained visual polish in Quiet Navy.

## Changes

- Six-slot, immediately masked Input OTP for all nine PIN fields: unlock, import/create, recovery authentication, PIN changes, and local removal. One labeled password input supplies keyboard and accessibility semantics; decorative slots expose no digit text. Submission remains explicit.
- Owned shadcn Base UI Select, Input, Textarea, Checkbox, and Switch components. All feature forms use these shared controls. SelectField keeps labels, options, and controlled value changes consistent across asset selection, activity filters, setup, and settings.
- Asset vector marks, loading skeletons, subtle hover treatments, setup progress, a framed QR, independent clipboard acknowledgements, clearer send/review spacing, and result emblems. Motion respects reduced-motion preferences.
- Component source is kept under `apps/frontend/src/ui`, with MIT attribution in `SHADCN-LICENSE.md`. Only the OTP required a new runtime dependency (`input-otp@1.5.0`); the other controls reuse Base UI.

Official source references: [Select](https://ui.shadcn.com/docs/components/base/select), [Input](https://ui.shadcn.com/docs/components/base/input), and the corresponding base-nova registry components.

## Validation

- Frontend: **54 tests passed across 25 files**, including masking/paste, explicit PIN submission, clipboard success/failure, Select labels and selection, privacy persistence, receive-asset switching, filter behavior, and preservation of network drafts.
- TypeScript and frontend production bundle passed through the native build.
- Native macOS debug application bundled successfully. Local Superpowers artifacts were removed before publication.
- `git diff --check` passed.

Native checks used an isolated disposable profile, never the personal wallet:

- At 1024 × 700, verified PIN masking during typing, Backspace, and paste. Six digits did not submit automatically; explicit unlock succeeded. macOS accessibility exposed a secure text field containing bullets.
- At 1440 × 900, inspected wallet, Receive, Settings, and Send. Confirmed styled dropdown positioning and selected-item checkmark. Down/Down/Enter selected TEST and refreshed the receive request. Address copy displayed “Copiado.”
- Checked the new Send checkbox: selecting Maximum disabled the amount input, and deselecting restored it. Left the disposable wallet locked.
- Final small CSS adjustment adds spacing between checkboxes and their labels.

This pass did not repeat funded broadcasts or visually exercise every result state and every locale. Result/review behavior remains covered by existing component tests; reduced-motion CSS was reviewed without changing the operating-system preference. The build still reports the existing large frontend chunk and Rust `proc-macro-error2` future-compatibility warnings.

Existing uncommitted implementation work was preserved. This pass is not a mainnet readiness assessment.
