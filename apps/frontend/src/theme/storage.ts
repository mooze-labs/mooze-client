import { parseThemePreference, type ThemePreference } from "./model";
export const THEME_STORAGE_KEY = "mooze.theme";
export type ThemeStorage = {
  read(): unknown;
  write(value: ThemePreference): void;
  subscribe(listener: (value: unknown) => void): () => void;
};
export function readThemePreference(storage: ThemeStorage): ThemePreference {
  try {
    return parseThemePreference(storage.read());
  } catch {
    return "system";
  }
}
export function createBrowserThemeStorage(): ThemeStorage {
  return {
    read: () => window.localStorage.getItem(THEME_STORAGE_KEY),
    write: (value) => window.localStorage.setItem(THEME_STORAGE_KEY, value),
    subscribe(listener) {
      const onStorage = (event: StorageEvent) => {
        if (event.key !== THEME_STORAGE_KEY && event.key !== null) return;
        try {
          if (event.storageArea === window.localStorage)
            listener(event.newValue);
        } catch {
          /* Storage can be denied independently of rendering. */
        }
      };
      window.addEventListener("storage", onStorage);
      return () => window.removeEventListener("storage", onStorage);
    },
  };
}
export function createMemoryThemeStorage(
  initial: ThemePreference = "system",
): ThemeStorage {
  let value = initial;
  return {
    read: () => value,
    write: (next) => {
      value = next;
    },
    subscribe: () => () => {},
  };
}
