import {
  createContext,
  useContext,
  useEffect,
  useLayoutEffect,
  useRef,
  useState,
  type ReactNode,
} from "react";
import {
  parseThemePreference,
  resolveTheme,
  type ThemePreference,
  type ResolvedTheme,
} from "./model";
import { type ThemeStorage } from "./storage";
import { applyTheme, systemTheme, SYSTEM_THEME_QUERY } from "./dom";
type ThemeState = {
  preference: ThemePreference;
  resolvedTheme: ResolvedTheme;
  setPreference(preference: ThemePreference): void;
  persistenceError: boolean;
};
const ThemeContext = createContext<ThemeState | null>(null);
export function useTheme(): ThemeState {
  const state = useContext(ThemeContext);
  if (!state) throw new Error("useTheme requires ThemeProvider");
  return state;
}
export function ThemeProvider({
  storage,
  initialPreference,
  applyNative,
  children,
}: {
  storage: ThemeStorage;
  initialPreference?: ThemePreference;
  applyNative?: (preference: ThemePreference) => Promise<void>;
  children: ReactNode;
}) {
  const [preference, updatePreference] = useState(() => {
    try {
      return parseThemePreference(storage.read());
    } catch {
      return initialPreference ?? "system";
    }
  });
  const [system, updateSystem] = useState(systemTheme);
  const [persistenceError, setPersistenceError] = useState(false);
  const nativeQueue = useRef(Promise.resolve());
  const resolvedTheme = resolveTheme(preference, system);
  useLayoutEffect(() => {
    applyTheme(document.documentElement, resolvedTheme);
  }, [resolvedTheme]);
  useEffect(() => {
    const media = window.matchMedia?.(SYSTEM_THEME_QUERY);
    const update = () => updateSystem(systemTheme());
    update();
    media?.addEventListener("change", update);
    return () => media?.removeEventListener("change", update);
  }, []);
  useLayoutEffect(() => {
    const unsubscribe = storage.subscribe((value) => {
      updatePreference(parseThemePreference(value));
      setPersistenceError(false);
    });
    // Close the gap between bootstrap, render, and listener registration.
    // A denied read must not erase an existing in-memory choice.
    try {
      updatePreference(parseThemePreference(storage.read()));
    } catch {
      /* Keep current selection. */
    }
    return unsubscribe;
  }, [storage]);
  useEffect(() => {
    if (!applyNative) return;
    let active = true;
    nativeQueue.current = nativeQueue.current.then(async () => {
      if (!active) return;
      try {
        await applyNative(preference);
      } catch (error) {
        console.warn("Native appearance could not be updated", error);
      }
      if (active) updateSystem(systemTheme());
    });
    return () => {
      active = false;
    };
  }, [preference, applyNative]);
  function setPreference(next: ThemePreference) {
    updateSystem(systemTheme());
    updatePreference(next);
    try {
      storage.write(next);
      setPersistenceError(false);
    } catch {
      setPersistenceError(true);
    }
  }
  return (
    <ThemeContext.Provider
      value={{ preference, resolvedTheme, setPreference, persistenceError }}
    >
      {children}
    </ThemeContext.Provider>
  );
}
