import { build, type Plugin } from "vite";
import { fileURLToPath } from "node:url";
const entry = fileURLToPath(
  new URL("../src/theme/prepaint.ts", import.meta.url),
);
/** Bundle the same pure theme code as a classic head script, before body parsing. */
export function themeBootstrap(): Plugin {
  async function compile(): Promise<string> {
    const result = await build({
      configFile: false,
      publicDir: false,
      logLevel: "silent",
      build: {
        write: false,
        emptyOutDir: false,
        lib: { entry, name: "MoozeAppearance", formats: ["iife"] },
        minify: true,
      },
    });
    const bundle = Array.isArray(result) ? result[0] : result;
    if (!("output" in bundle))
      throw new Error("Appearance bootstrap did not produce output");
    const chunk = bundle.output.find((item) => item.type === "chunk");
    if (!chunk || chunk.type !== "chunk")
      throw new Error("Appearance bootstrap is missing");
    return chunk.code;
  }
  return {
    name: "mooze-appearance-bootstrap",
    configureServer(server) {
      server.middlewares.use(
        "/theme-init.js",
        async (_request, response, next) => {
          try {
            response.setHeader("Content-Type", "text/javascript");
            response.setHeader("Cache-Control", "no-store");
            response.end(await compile());
          } catch (error) {
            next(error);
          }
        },
      );
    },
    async generateBundle() {
      this.emitFile({
        type: "asset",
        fileName: "theme-init.js",
        source: await compile(),
      });
    },
    transformIndexHtml: {
      order: "post",
      handler(_html, context) {
        // Synthetic preview owns an in-memory theme, never production storage.
        if (context.filename.endsWith("preview.html")) return;
        return [
          {
            tag: "script",
            attrs: { src: "/theme-init.js" },
            injectTo: "head-prepend",
          },
        ];
      },
    },
  };
}
