import React from "react";
import ReactDOM from "react-dom/client";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { createBrowserRouter, RouterProvider } from "react-router-dom";
import { IntlProvider } from "react-intl";
import "@fontsource/geist/latin-400.css";
import "@fontsource/geist/latin-500.css";
import "@fontsource/geist/latin-600.css";
import "@fontsource/jetbrains-mono/latin-400.css";
import { App } from "./app";
import { ThemeProvider } from "./theme/theme-provider";
import { themeStorage, initialPreference } from "./theme/startup";
import { setNativeTheme } from "./theme/native";
const queryClient = new QueryClient({
  defaultOptions: {
    queries: { retry: 1, refetchOnWindowFocus: false },
    mutations: { retry: false },
  },
});
const router = createBrowserRouter([{ path: "*", element: <App /> }]);
ReactDOM.createRoot(document.getElementById("root")!).render(
  <React.StrictMode>
    <ThemeProvider
      storage={themeStorage}
      initialPreference={initialPreference}
      applyNative={setNativeTheme}
    >
      <IntlProvider locale="pt-BR">
        <QueryClientProvider client={queryClient}>
          <RouterProvider router={router} />
        </QueryClientProvider>
      </IntlProvider>
    </ThemeProvider>
  </React.StrictMode>,
);
