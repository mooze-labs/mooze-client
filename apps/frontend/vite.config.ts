import { readFileSync } from "node:fs";
import { themeBootstrap } from "./build/theme-bootstrap";
import { defineConfig } from "vitest/config";
import tailwindcss from "@tailwindcss/vite";
import react from "@vitejs/plugin-react";
import { fileURLToPath, URL } from "node:url";
export default defineConfig({
  define: {
    __APP_VERSION__: JSON.stringify(
      JSON.parse(
        readFileSync(
          new URL("../desktop/src-tauri/tauri.conf.json", import.meta.url),
          "utf8",
        ),
      ).version,
    ),
  },
  plugins: [themeBootstrap(), react(), tailwindcss()],
  resolve: { alias: { "@": fileURLToPath(new URL("./src", import.meta.url)) } },
  clearScreen: false,
  server: {
    host: "127.0.0.1",
    port: 1420,
    strictPort: true,
    fs: { allow: [fileURLToPath(new URL("../..", import.meta.url))] },
  },
  test: { environment: "jsdom", setupFiles: ["./src/testing/setup.ts"] },
});
