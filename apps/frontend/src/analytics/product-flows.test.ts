import { expect, it } from "vitest";
import { createPixStatusTracker, trackOperation } from "./product-flows";
import type { AnalyticsEvent } from "./events";

it("reports actual operations once while preserving wallet results and errors", async () => {
  const events: AnalyticsEvent[] = [];
  const started: AnalyticsEvent = {
    name: "pix_request_started",
    properties: {},
  };
  const succeeded: AnalyticsEvent = {
    name: "pix_request_created",
    properties: {},
  };
  const failed: AnalyticsEvent = { name: "pix_request_failed", properties: {} };
  const value = { deposit_id: "private" };
  expect(
    await trackOperation((event) => events.push(event), {
      started,
      failed,
      outcome: () => succeeded,
      run: async () => value,
    }),
  ).toBe(value);
  const error = new Error("private error");
  await expect(
    trackOperation((event) => events.push(event), {
      started,
      failed,
      outcome: () => succeeded,
      run: async () => {
        throw error;
      },
    }),
  ).rejects.toBe(error);
  expect(events).toEqual([started, succeeded, started, failed]);
});

it("only emits observed PIX transitions, without replaying history or retaining state across opt-out", () => {
  const events: AnalyticsEvent[] = [];
  let enabled = false;
  const tracker = createPixStatusTracker(
    () => enabled,
    (event) => events.push(event),
  );
  tracker.observe("private-id", "Pending");
  enabled = true;
  tracker.observe("private-id", "Completed"); // First observation is a baseline.
  tracker.observe("new-id", "Pending");
  tracker.observe("new-id", "UnderReview");
  tracker.observe("new-id", "Paid"); // Same stage, not settlement.
  tracker.observe("new-id", "Finished");
  tracker.observe("new-id", "Completed");
  expect(events).toEqual([
    {
      name: "pix_deposit_status_changed",
      properties: { status: "processing" },
    },
    { name: "pix_deposit_status_changed", properties: { status: "completed" } },
  ]);
  tracker.clear();
  tracker.observe("new-id", "Refunded");
  expect(events).toHaveLength(2);
});
