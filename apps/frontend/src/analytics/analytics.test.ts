import { describe, expect, it, vi } from "vitest";
import { createAnalytics, type AnalyticsSink } from "./analytics";
import { sanitizeEvent, screenForPath } from "./events";

it("allows PIX and swap actions without forwarding financial or provider data", () => {
  for (const name of [
    "pix_request_started",
    "pix_request_created",
    "pix_request_failed",
    "pix_code_copied",
  ]) {
    expect(
      sanitizeEvent(name, { tax_id: "secret", pix_key: "secret", amount: 123 }),
    ).toEqual({ name, properties: {} });
  }
  expect(
    sanitizeEvent("pix_deposit_status_changed", {
      status: "completed",
      deposit_id: "secret",
    }),
  ).toEqual({
    name: "pix_deposit_status_changed",
    properties: { status: "completed" },
  });
  expect(
    sanitizeEvent("pix_deposit_status_changed", {
      status: "raw provider error",
    }),
  ).toBeNull();
  for (const name of [
    "swap_review_opened",
    "swap_started",
    "swap_submission_succeeded",
    "swap_failed",
  ]) {
    expect(
      sanitizeEvent(name, {
        swap_type: "peg_in",
        txid: "secret",
        amount: 123,
        error: "secret",
      }),
    ).toEqual({ name, properties: { swap_type: "peg_in" } });
    expect(sanitizeEvent(name, { swap_type: "arbitrary-asset-id" })).toBeNull();
  }
});

it("rejects coercible objects at the categorical event boundary", () => {
  expect(
    sanitizeEvent("onboarding_completed", { method: ["create"] }),
  ).toBeNull();
});

function fixture(consent = false) {
  const sent: unknown[] = [];
  const sink: AnalyticsSink = {
    capture: (event) => {
      sent.push(event);
    },
    stop: vi.fn(),
  };
  const load = vi.fn(async () => sink);
  const storage = {
    read: () => consent,
    write: vi.fn((v: boolean) => {
      consent = v;
    }),
  };
  const analytics = createAnalytics({ configured: true, storage, load });
  return { analytics, load, sink, storage, sent };
}

describe("analytics consent boundary", () => {
  it("does not load the SDK or buffer events before opt-in", async () => {
    const f = fixture();
    await f.analytics.start();
    f.analytics.track({
      name: "screen_viewed",
      properties: { screen_name: "wallet" },
    });
    expect(f.load).not.toHaveBeenCalled();
    await f.analytics.setEnabled(true);
    expect(f.sent).toEqual([]);
    f.analytics.track({
      name: "screen_viewed",
      properties: { screen_name: "settings" },
    });
    expect(f.sent).toEqual([
      { name: "screen_viewed", properties: { screen_name: "settings" } },
    ]);
    await f.analytics.setEnabled(false);
    f.analytics.track({
      name: "screen_viewed",
      properties: { screen_name: "wallet" },
    });
    expect(f.sent).toHaveLength(1);
    expect(f.sink.stop).toHaveBeenCalledOnce();
  });

  it("honors revocation while the SDK is loading", async () => {
    const f = fixture();
    let resolve!: (sink: AnalyticsSink) => void;
    f.load.mockImplementation(
      () =>
        new Promise((r) => {
          resolve = r;
        }),
    );
    const enable = f.analytics.setEnabled(true);
    await Promise.resolve();
    const disable = f.analytics.setEnabled(false);
    resolve(f.sink);
    await Promise.all([enable, disable]);
    f.analytics.track({
      name: "screen_viewed",
      properties: { screen_name: "wallet" },
    });
    expect(f.sent).toEqual([]);
    expect(f.sink.stop).toHaveBeenCalled();
    expect(f.analytics.getSnapshot().enabled).toBe(false);
  });

  it("restores consent once and isolates transport failures", async () => {
    const f = fixture(true);
    await Promise.all([f.analytics.start(), f.analytics.start()]);
    expect(f.load).toHaveBeenCalledOnce();
    f.sink.capture = () => {
      throw new Error("offline");
    };
    expect(() =>
      f.analytics.track({
        name: "send_started",
        properties: { chain: "bitcoin" },
      }),
    ).not.toThrow();
  });

  it("fails closed when consent cannot be persisted", async () => {
    const f = fixture();
    f.storage.write.mockImplementation(() => {
      throw new Error("storage denied");
    });
    expect(await f.analytics.setEnabled(true)).toBe(false);
    expect(f.load).not.toHaveBeenCalled();
    expect(f.analytics.getSnapshot().enabled).toBe(false);
  });
});

describe("analytics event allowlist", () => {
  it("discards unknown events, invalid values and sensitive extra properties", () => {
    expect(
      sanitizeEvent("$identify", { email: "user@example.com" }),
    ).toBeNull();
    expect(
      sanitizeEvent("send_started", { chain: "secret-address" }),
    ).toBeNull();
    expect(
      sanitizeEvent("send_started", {
        chain: "bitcoin",
        mnemonic: "secret",
        amount: 123,
      }),
    ).toEqual({ name: "send_started", properties: { chain: "bitcoin" } });
    expect(
      sanitizeEvent("send_failed", {
        chain: "liquid",
        error_code: "secret raw error",
      }),
    ).toBeNull();
  });

  it("never emits URLs, query strings or arbitrary route segments", () => {
    expect(screenForPath("/assets/Bitcoin/secret?address=secret")).toBe(
      "asset",
    );
    expect(screenForPath("/send?address=secret")).toBe("send");
    expect(screenForPath("/unknown/secret")).toBeNull();
    expect(screenForPath("/settings/view-mnemonic")).toBeNull();
  });
});
