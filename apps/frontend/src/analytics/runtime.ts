import { createAnalytics } from "./analytics";
import { loadPosthog } from "./posthog";
import { createPixStatusTracker } from "./product-flows";

const token = import.meta.env.VITE_POSTHOG_TOKEN ?? "";
const host = import.meta.env.VITE_POSTHOG_HOST ?? "";
const environment = import.meta.env.VITE_ANALYTICS_ENVIRONMENT ?? "development";
const consentKey = "mooze.analytics.consent.v1";
let network = "unknown";
export function setAnalyticsNetwork(value: string) {
  network =
    (
      { Mainnet: "mainnet", Testnet: "testnet", Regtest: "regtest" } as Record<
        string,
        string
      >
    )[value] ?? "unknown";
}
export const analytics = createAnalytics({
  configured: token.startsWith("phc_") && /^https:\/\/[^/?#]+\/?$/.test(host),
  storage: {
    read: () => localStorage.getItem(consentKey) === "true",
    write: (value) => localStorage.setItem(consentKey, String(value)),
  },
  load: (allowed) =>
    loadPosthog({
      token,
      host,
      environment,
      version: __APP_VERSION__,
      context: () => ({ network }),
      allowed,
    }),
});

export const pixAnalytics = createPixStatusTracker(
  () => analytics.getSnapshot().enabled && !analytics.getSnapshot().busy,
  analytics.track,
);
analytics.subscribe(() => {
  if (!analytics.getSnapshot().enabled) pixAnalytics.clear();
});
