import { sanitizeEvent, type AnalyticsEvent } from "./events";

export interface AnalyticsSink {
  capture(event: AnalyticsEvent): void;
  stop(): void | Promise<void>;
}
export interface AnalyticsState {
  enabled: boolean;
  available: boolean;
  busy: boolean;
  error: boolean;
}

/** No SDK dependency. Captures are best effort; consent writes fail closed. */
export function createAnalytics(options: {
  configured: boolean;
  storage: { read(): boolean; write(value: boolean): void };
  load(allowed: () => boolean): Promise<AnalyticsSink>;
}) {
  let enabled = false;
  try {
    enabled = options.storage.read() && options.configured;
  } catch {
    /* default off */
  }
  let state: AnalyticsState = {
    enabled,
    available: options.configured,
    busy: false,
    error: false,
  };
  let sink: AnalyticsSink | undefined;
  let revision = 0;
  let transition = Promise.resolve();
  let started = false;
  const listeners = new Set<() => void>();
  const notify = (patch: Partial<AnalyticsState>) => {
    state = { ...state, ...patch };
    listeners.forEach((listener) => listener());
  };
  const reconcile = () => {
    const current = ++revision;
    notify({ busy: true });
    transition = transition
      .then(async () => {
        if (current !== revision) return;
        if (sink) {
          await sink.stop();
          sink = undefined;
        }
        if (!state.enabled) return;
        const loaded = await options.load(
          () => state.enabled && current === revision,
        );
        if (state.enabled && current === revision) sink = loaded;
        else await loaded.stop();
      })
      .catch(() => {
        if (current === revision) notify({ error: true });
      })
      .finally(() => {
        if (current === revision) notify({ busy: false });
      });
    return transition;
  };
  return {
    getSnapshot: () => state,
    subscribe(listener: () => void) {
      listeners.add(listener);
      return () => {
        listeners.delete(listener);
      };
    },
    start() {
      if (!started) {
        started = true;
        if (state.enabled) return reconcile();
      }
      return transition;
    },
    async setEnabled(value: boolean) {
      if (value && !options.configured) return false;
      // Close the application gate synchronously, before any asynchronous SDK work.
      if (!value) notify({ enabled: false });
      try {
        options.storage.write(value);
      } catch {
        notify({ enabled: false, error: true });
        await reconcile();
        return false;
      }
      notify({ enabled: value, error: false });
      await reconcile();
      return !state.error;
    },
    track(event: AnalyticsEvent) {
      if (!state.enabled || !sink) return;
      const safe = sanitizeEvent(event.name, event.properties);
      if (safe) {
        try {
          sink.capture(safe);
        } catch {
          /* analytics cannot break the wallet */
        }
      }
    },
  };
}
export type Analytics = ReturnType<typeof createAnalytics>;
