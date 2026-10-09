import type { PostHogConfig } from "posthog-js";
let initialized = false;
import type { AnalyticsSink } from "./analytics";
import { sanitizeEvent } from "./events";

export async function loadPosthog(options: {
  token: string;
  host: string;
  environment: string;
  version: string;
  context: () => { network: string };
  allowed: () => boolean;
}): Promise<AnalyticsSink> {
  const { default: posthog } = await import("posthog-js/no-external");
  if (!options.allowed()) return { capture() {}, stop() {} };
  const config: Partial<PostHogConfig> = {
    api_host: options.host,
    persistence: "localStorage",
    opt_out_capturing_persistence_type: "localStorage",
    opt_out_capturing_by_default: true,
    person_profiles: "never",
    autocapture: false,
    capture_pageview: false,
    capture_pageleave: false,
    capture_dead_clicks: false,
    capture_heatmaps: false,
    capture_performance: false,
    capture_exceptions: false,
    disable_session_recording: true,
    disable_surveys: true,
    disable_external_dependency_loading: true,
    advanced_disable_flags: true,
    advanced_disable_feature_flags: true,
    advanced_disable_toolbar_metrics: true,
    rageclick: false,
    disable_conversations: true,
    disable_product_tours: true,
    save_campaign_params: false,
    save_referrer: false,
    request_batching: false,
    before_send(event) {
      if (!event || !options.allowed()) return null;
      const safe = sanitizeEvent(event.event, event.properties);
      if (!safe) return null;
      // Rebuild rather than blacklist: the SDK adds URLs/referrers/device metadata.
      event.properties = {
        ...safe.properties,
        token: options.token,
        distinct_id: posthog.get_distinct_id(),
        $process_person_profile: false,
        $geoip_disable: true,
        $lib: "posthog-js",
        $lib_version: posthog.version,
        platform: "desktop",
        environment: options.environment,
        app_version: options.version,
        network: options.context().network,
        event_schema_version: 1,
      };
      delete event.$set;
      delete event.$set_once;
      return event;
    },
  };
  if (initialized) posthog.set_config(config);
  else {
    posthog.init(options.token, config);
    initialized = true;
  }
  posthog.opt_in_capturing({ captureEventName: false });
  return {
    capture(event) {
      // Prefer immediate best-effort delivery. Offline events are dropped.
      // The SDK may fall back to fetch and retry a previously captured event.
      if (
        !options.allowed() ||
        !navigator.onLine ||
        typeof navigator.sendBeacon !== "function"
      )
        return;
      posthog.capture(event.name, event.properties, {
        send_instantly: true,
        transport: "sendBeacon",
      });
    },
    stop() {
      posthog.opt_out_capturing();
      posthog.reset(true);
      posthog.opt_out_capturing();
    },
  };
}
