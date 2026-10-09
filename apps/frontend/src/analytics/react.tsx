import { useEffect, useRef, useSyncExternalStore } from "react";
import { useLocation } from "react-router-dom";
import { analytics } from "./runtime";
import { screenForPath, type Screen } from "./events";

export const useAnalyticsState = () =>
  useSyncExternalStore(analytics.subscribe, analytics.getSnapshot);
export function AnalyticsNavigation() {
  const location = useLocation();
  return <AnalyticsScreen screen={screenForPath(location.pathname)} />;
}

export function AnalyticsScreen({ screen }: { screen: Screen | null }) {
  const state = useAnalyticsState();
  const last = useRef<string | null>(null);
  useEffect(() => {
    if (!state.enabled || state.busy) {
      last.current = null;
      return;
    }
    if (last.current === screen) return;
    last.current = screen;
    if (screen)
      analytics.track({
        name: "screen_viewed",
        properties: { screen_name: screen },
      });
  }, [screen, state.enabled, state.busy]);
  return null;
}
