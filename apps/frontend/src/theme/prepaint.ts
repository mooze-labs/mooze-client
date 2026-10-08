import { applyTheme, systemTheme } from "./dom";
import { resolveTheme } from "./model";
import { createBrowserThemeStorage, readThemePreference } from "./storage";
applyTheme(
  document.documentElement,
  resolveTheme(readThemePreference(createBrowserThemeStorage()), systemTheme()),
);
