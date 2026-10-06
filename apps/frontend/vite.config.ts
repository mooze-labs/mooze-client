import { defineConfig } from "vitest/config";
import react from "@vitejs/plugin-react";
import { fileURLToPath, URL } from "node:url";
export default defineConfig({
  plugins: [react()],
  clearScreen: false,
  server: {
    host: "127.0.0.1",
    port: 1420,
    strictPort: true,
    fs: { allow: [fileURLToPath(new URL("../..", import.meta.url))] },
  },
  test: { environment: "jsdom", setupFiles: ["./src/testing/setup.ts"] },
});
