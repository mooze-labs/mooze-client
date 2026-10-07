import { afterEach, expect, it } from "vitest";
import { cleanup, render, screen } from "@testing-library/react";
import { FlowStep } from "./flow-step";
afterEach(cleanup);
it("moves focus to the new step heading without stealing initial page focus", () => {
  const view = render(
    <FlowStep step="edit">
      <h2>Edit</h2>
      <input aria-label="Amount" />
    </FlowStep>,
  );
  expect(screen.getByRole("heading")).not.toHaveFocus();
  screen.getByLabelText("Amount").focus();
  view.rerender(
    <FlowStep step="review">
      <h2>Review</h2>
      <button>Confirm</button>
    </FlowStep>,
  );
  expect(screen.getByRole("heading", { name: "Review" })).toHaveFocus();
  view.rerender(
    <FlowStep step="edit">
      <h2>Edit</h2>
      <input aria-label="Amount" />
    </FlowStep>,
  );
  expect(screen.getByRole("heading", { name: "Edit" })).toHaveFocus();
});
