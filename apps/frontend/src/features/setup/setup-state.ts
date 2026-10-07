import type { SetupDto } from "../../core/desktop.generated";
export type WalletDraft =
  | { kind: "create"; setup: SetupDto; answers: string[] }
  | { kind: "import"; words: string[] };
export type SetupState =
  | { step: "welcome" | "configure" | "expired" }
  | { step: "import"; words: string[] }
  | {
      step: "backup";
      draft: Extract<WalletDraft, { kind: "create" }>;
      revealed: boolean;
    }
  | { step: "verify"; draft: Extract<WalletDraft, { kind: "create" }> }
  | { step: "pin" | "preparing" | "recover"; draft: WalletDraft };
export type SetupAction =
  | {
      type:
        | "create"
        | "import"
        | "reveal"
        | "back"
        | "cancel"
        | "expire"
        | "prepare"
        | "retry"
        | "recover";
    }
  | { type: "generated"; setup: SetupDto }
  | { type: "words"; words: string[] }
  | { type: "answer"; index: number; value: string }
  | { type: "continue" };
export function normalizeWords(phrase: string): string[] {
  return phrase.trim().toLowerCase().split(/\s+/).filter(Boolean);
}
export function validWordCount(count: number): boolean {
  return [12, 15, 18, 21, 24].includes(count);
}
export function backupMatches(
  draft: Extract<WalletDraft, { kind: "create" }>,
): boolean {
  return draft.setup.challenge_indices.every(
    (index, i) =>
      draft.answers[i]?.trim().toLowerCase() === draft.setup.words[index],
  );
}
export function setupReducer(
  state: SetupState,
  action: SetupAction,
): SetupState {
  switch (action.type) {
    case "cancel":
      return { step: "welcome" };
    case "expire":
      return { step: "expired" };
    case "create":
      return state.step === "welcome" || state.step === "expired"
        ? { step: "configure" }
        : state;
    case "import":
      return state.step === "welcome" ? { step: "import", words: [] } : state;
    case "generated":
      return state.step === "configure"
        ? {
            step: "backup",
            revealed: false,
            draft: {
              kind: "create",
              setup: action.setup,
              answers: action.setup.challenge_indices.map(() => ""),
            },
          }
        : state;
    case "reveal":
      return state.step === "backup" ? { ...state, revealed: true } : state;
    case "words":
      return state.step === "import"
        ? { ...state, words: action.words }
        : state;
    case "answer":
      return state.step === "verify"
        ? {
            ...state,
            draft: {
              ...state.draft,
              answers: state.draft.answers.map((word, index) =>
                index === action.index ? action.value : word,
              ),
            },
          }
        : state;
    case "continue":
      if (state.step === "backup" && state.revealed)
        return { step: "verify", draft: state.draft };
      if (state.step === "verify" && backupMatches(state.draft))
        return {
          step: "pin",
          draft: {
            ...state.draft,
            answers: state.draft.answers.map((word) =>
              word.trim().toLowerCase(),
            ),
          },
        };
      // Import invokes this only after authoritative backend validation.
      if (state.step === "import" && validWordCount(state.words.length))
        return { step: "pin", draft: { kind: "import", words: state.words } };
      return state;
    case "back":
      if (state.step === "verify")
        return { step: "backup", draft: state.draft, revealed: false };
      if (state.step === "pin")
        return state.draft.kind === "create"
          ? { step: "verify", draft: state.draft }
          : { step: "import", words: state.draft.words };
      if (state.step === "configure" || state.step === "import")
        return { step: "welcome" };
      return state;
    case "prepare":
      return state.step === "pin"
        ? { step: "preparing", draft: state.draft }
        : state;
    case "recover":
      return state.step === "preparing"
        ? { step: "recover", draft: state.draft }
        : state;
    case "retry":
      return state.step === "preparing" || state.step === "recover"
        ? { step: "pin", draft: state.draft }
        : state;
  }
}
