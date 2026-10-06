import { expect, it } from "vitest";
import { reduceSend } from "./send-state";
import type { Review } from "../../core/client";
it("edits invalidate review and uncertain sends cannot confirm again", () => {
  const reviewed = reduceSend(
    { phase: "editing" },
    { type: "reviewed", review: { id: "review" } as Review },
  );
  expect(reduceSend(reviewed, { type: "edit" })).toEqual({ phase: "editing" });
  const uncertain = reduceSend(
    { phase: "submitting", review: { id: "r" } as Review },
    { type: "uncertain", message: "unknown" },
  );
  expect(reduceSend(uncertain, { type: "confirm" })).toEqual(uncertain);
});
