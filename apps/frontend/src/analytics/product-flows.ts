import type { AnalyticsEvent, PixStatus } from "./events";

export async function trackOperation<T>(
  track: (event: AnalyticsEvent) => void,
  options: {
    run: () => Promise<T>;
    started: AnalyticsEvent;
    outcome: (value: T) => AnalyticsEvent;
    failed: AnalyticsEvent;
  },
): Promise<T> {
  track(options.started);
  let value: T;
  try {
    value = await options.run();
  } catch (error) {
    track(options.failed);
    throw error;
  }
  track(options.outcome(value));
  return value;
}

export function createPixStatusTracker(
  allowed: () => boolean,
  track: (event: AnalyticsEvent) => void,
) {
  // IDs stay in bounded, volatile memory for deduplication; never in a payload.
  const previous = new Map<string, PixStatus>();
  return {
    clear: () => previous.clear(),
    observe(id: string, rawStatus: string) {
      if (!allowed()) {
        previous.clear();
        return;
      }
      const status = pixStatus(rawStatus);
      if (!status) return;
      const old = previous.get(id);
      previous.delete(id);
      previous.set(id, status);
      if (previous.size > 256) previous.delete(previous.keys().next().value!);
      if (old && old !== status)
        track({ name: "pix_deposit_status_changed", properties: { status } });
    },
  };
}

function pixStatus(raw: string): PixStatus | null {
  const value = raw.toLowerCase().replaceAll("_", "");
  if (value === "pending") return "pending";
  if (
    [
      "underreview",
      "processing",
      "fundsprepared",
      "depixsent",
      "paid",
      "broadcasted",
      "med",
      "processingrefund",
      "broadcastedrefund",
    ].includes(value)
  )
    return "processing";
  if (value === "finished" || value === "completed") return "completed";
  if (value === "failed") return "failed";
  if (value === "expired" || value === "timeout") return "expired";
  if (value === "refunded" || value === "finishedrefund") return "refunded";
  return null;
}
