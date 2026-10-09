import { afterEach, expect, it, vi } from "vitest";
import { loadPosthog } from "./posthog";

afterEach(() => vi.unstubAllGlobals());

it("sends only approved properties through the real SDK and supports re-enabling", async () => {
  Object.defineProperty(navigator, "userAgent", {
    configurable: true,
    value: "Mozilla/5.0 AppleWebKit/537.36 Chrome/120.0.0.0 Safari/537.36",
  });
  const beacon = vi.fn(() => true);
  Object.defineProperty(navigator, "sendBeacon", {
    configurable: true,
    value: beacon,
  });
  const fetch = vi.fn();
  vi.stubGlobal("fetch", fetch);
  let allowed = true;
  const options = {
    token: "phc_test_project",
    host: "https://us.i.posthog.com",
    environment: "test",
    version: "1.0",
    context: () => ({ network: "mainnet" }),
    allowed: () => allowed,
  };
  const sink = await loadPosthog(options);
  const { default: sdk } = await import("posthog-js/no-external");
  const id = sdk.get_distinct_id();
  const event = sdk.capture(
    "send_started",
    { chain: "bitcoin", address: "secret", $current_url: "https://secret" },
    { transport: "sendBeacon", send_instantly: true },
  );
  expect(event?.properties).toEqual({
    chain: "bitcoin",
    token: "phc_test_project",
    distinct_id: id,
    $process_person_profile: false,
    $geoip_disable: true,
    $lib: "posthog-js",
    $lib_version: sdk.version,
    platform: "desktop",
    environment: "test",
    app_version: "1.0",
    network: "mainnet",
    event_schema_version: 1,
  });
  expect(beacon).toHaveBeenCalledOnce();
  expect(fetch).not.toHaveBeenCalled();
  allowed = false;
  await sink.stop();
  sink.capture({ name: "send_started", properties: { chain: "bitcoin" } });
  expect(beacon).toHaveBeenCalledOnce();
  allowed = true;
  const resumed = await loadPosthog({ ...options, allowed: () => allowed });
  resumed.capture({ name: "send_started", properties: { chain: "liquid" } });
  expect(beacon).toHaveBeenCalledTimes(2);
  expect(sdk.get_distinct_id()).not.toBe(id);
  allowed = false;
  await resumed.stop();
});
