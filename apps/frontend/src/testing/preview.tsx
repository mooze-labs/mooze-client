import { ThemeProvider } from "../theme/theme-provider";
import { createMemoryThemeStorage } from "../theme/storage";
import { parseThemePreference, resolveTheme } from "../theme/model";
import { applyTheme, systemTheme } from "../theme/dom";
import React, { useState } from "react";
import ReactDOM from "react-dom/client";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { createHashRouter, RouterProvider } from "react-router-dom";
import { IntlProvider } from "react-intl";
import { WalletClientProvider } from "../app/client-context";
import { SessionProvider } from "../app/session-provider";
import { PreferencesContext, type Preferences } from "../i18n/preferences";
import { WalletShell } from "../app/shell";
import { createPreviewClient } from "./preview-client";
import "@fontsource/geist/latin-400.css";
import "@fontsource/geist/latin-500.css";
import "@fontsource/geist/latin-600.css";
import "@fontsource/jetbrains-mono/latin-400.css";
import "../styles/main.css";
import "../styles/polish.css";
import "../styles/layout.css";

if (!import.meta.env.DEV)
  throw new Error("Synthetic preview is development-only.");
const themePreference = parseThemePreference(
  new URLSearchParams(location.search).get("theme"),
);
const themeStorage = createMemoryThemeStorage(themePreference);
applyTheme(
  document.documentElement,
  resolveTheme(themePreference, systemTheme()),
);
const mode = new URLSearchParams(location.search).get("session") ?? "unlocked";
const client = createPreviewClient(mode);
const queryClient = new QueryClient({
  defaultOptions: { queries: { retry: false, refetchOnWindowFocus: false } },
});
function Preview() {
  const [preferences, setPreferences] = useState<Preferences>({
    locale: "pt-BR",
    bitcoinUnit: "BTC",
    privacy: false,
  });
  return (
    <WalletClientProvider client={client}>
      <SessionProvider>
        <PreferencesContext.Provider
          value={{ preferences, save: async (next) => setPreferences(next) }}
        >
          <IntlProvider locale={preferences.locale}>
            <div
              style={{
                padding: "6px 16px",
                background: "var(--app-surface-low)",
                color: "var(--app-text-secondary)",
                fontSize: 12,
              }}
            >
              Synthetic preview · no funds or real payment codes
            </div>
            <WalletShell />
          </IntlProvider>
        </PreferencesContext.Provider>
      </SessionProvider>
    </WalletClientProvider>
  );
}
const router = createHashRouter([{ path: "*", element: <Preview /> }]);
ReactDOM.createRoot(document.getElementById("root")!).render(
  <React.StrictMode>
    <ThemeProvider storage={themeStorage} initialPreference={themePreference}>
      <QueryClientProvider client={queryClient}>
        <RouterProvider router={router} />
      </QueryClientProvider>
    </ThemeProvider>
  </React.StrictMode>,
);
