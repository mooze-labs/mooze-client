import { readFile, writeFile, mkdir } from "node:fs/promises";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { parseArgs } from "node:util";
import { resolvePalette, renderCss, renderDart } from "./palette.mjs";
const root = fileURLToPath(new URL("../../", import.meta.url));
const { values } = parseArgs({
  options: {
    check: { type: "boolean" },
    input: { type: "string" },
    css: { type: "string" },
    dart: { type: "string" },
  },
});
try {
  const palette = resolvePalette(
    JSON.parse(
      await readFile(
        values.input ?? resolve(root, "packages/design-tokens/colors.json"),
        "utf8",
      ),
    ),
  );
  for (const [path, content] of [
    [
      values.css ??
        resolve(root, "apps/frontend/src/styles/colors.generated.css"),
      renderCss(palette),
    ],
    [
      values.dart ??
        resolve(root, "apps/mobile/lib/themes/generated/app_palette.dart"),
      renderDart(palette),
    ],
  ]) {
    let current;
    try {
      current = await readFile(path, "utf8");
    } catch (error) {
      if (error.code !== "ENOENT") throw error;
    }
    if (current === content) continue;
    if (values.check) {
      console.error(`Stale generated tokens: ${path}`);
      process.exitCode = 1;
    } else {
      await mkdir(dirname(path), { recursive: true });
      await writeFile(path, content);
    }
  }
} catch (error) {
  console.error(error.message);
  process.exitCode = 1;
}
