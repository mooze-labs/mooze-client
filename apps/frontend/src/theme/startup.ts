import { applyTheme, systemTheme } from "./dom";
import { resolveTheme } from "./model";
import { createBrowserThemeStorage, readThemePreference } from "./storage";
export const themeStorage = createBrowserThemeStorage();
export const initialPreference = readThemePreference(themeStorage);
applyTheme(
  document.documentElement,
  resolveTheme(initialPreference, systemTheme()),
);
void import("../main");
