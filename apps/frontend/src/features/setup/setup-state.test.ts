import { expect, it } from "vitest";
import { setupReducer, type SetupState } from "./setup-state";
it("does not skip backup confirmation or reveal", () => {
  const state: SetupState = {
    step: "backup",
    revealed: false,
    draft: {
      kind: "create",
      setup: {
        setup_id: "s",
        words: ["same", "same", "last"],
        challenge_indices: [0, 1, 2],
        expires_at_ms: 600000,
      },
      answers: ["", "", ""],
    },
  };
  expect(setupReducer(state, { type: "continue" }).step).toBe("backup");
  const verification: SetupState = { step: "verify", draft: state.draft };
  expect(setupReducer(verification, { type: "continue" }).step).toBe("verify");
  expect(
    setupReducer(
      {
        ...verification,
        draft: { ...state.draft, answers: ["same", " SAME ", "last"] },
      },
      { type: "continue" },
    ),
  ).toMatchObject({
    step: "pin",
    draft: { answers: ["same", "same", "last"] },
  });
});
it("clears all recovery data on expiry and cancellation", () => {
  const state: SetupState = {
    step: "pin",
    draft: { kind: "import", words: ["secret"] },
  };
  expect(setupReducer(state, { type: "expire" })).toEqual({ step: "expired" });
  expect(setupReducer(state, { type: "cancel" })).toEqual({ step: "welcome" });
});
