import { test } from "node:test";
import assert from "node:assert/strict";
import { mkdtemp, readFile, writeFile, rm } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { spawnSync } from "node:child_process";
import {
  validatePalette,
  resolvePalette,
  renderCss,
  renderDart,
} from "./palette.mjs";
const palette = (values) => ({ version: 1, light: values, dark: values });
test("RGBA conversion preserves channels and white60 opacity", () => {
  const resolved = resolvePalette(
    palette({ alpha: "#11223344", white: "#FFFFFF99" }),
  );
  assert.match(renderDart(resolved), /Color\(0x44112233\)/);
  assert.match(renderDart(resolved), /Color\(0x99FFFFFF\)/);
  assert.match(renderCss(resolved), /--app-alpha: #11223344/);
});
test("multi-hop aliases resolve and bad references fail", () => {
  assert.equal(
    resolvePalette(palette({ a: "#abcdef", b: { ref: "a" }, c: { ref: "b" } }))
      .light.c,
    "#ABCDEF",
  );
  assert.throws(
    () => resolvePalette(palette({ a: { ref: "missing" } })),
    /missing/i,
  );
  assert.throws(
    () => resolvePalette(palette({ a: { ref: "b" }, b: { ref: "a" } })),
    /cycle/i,
  );
});
test("rejects malformed colors, shapes, keys and unequal mode contracts", () => {
  for (const input of [
    null,
    { version: 2 },
    palette({ bad: "#12345" }),
    palette({ "bad-name": "#123456" }),
    { version: 1, light: { a: "#123456" }, dark: { b: "#123456" } },
    palette({ a: { ref: "b", other: true } }),
  ]) {
    assert.throws(() => validatePalette(input));
  }
});
test("rendering is deterministic regardless of source order", () => {
  const a = resolvePalette(palette({ a: "#FFFFFF", b: "#000000" }));
  const b = resolvePalette(palette({ b: "#000000", a: "#FFFFFF" }));
  assert.equal(renderCss(a), renderCss(b));
  assert.equal(renderDart(a), renderDart(b));
});
test("CLI checks stale outputs without overwriting them", async () => {
  const dir = await mkdtemp(join(tmpdir(), "mooze-tokens-"));
  try {
    const input = join(dir, "colors.json"),
      css = join(dir, "colors.css"),
      dart = join(dir, "colors.dart");
    await writeFile(input, JSON.stringify(palette({ primary: "#EA1E63" })));
    const args = [
      "tools/design-tokens/generate.mjs",
      "--input",
      input,
      "--css",
      css,
      "--dart",
      dart,
    ];
    assert.equal(spawnSync(process.execPath, args).status, 0);
    assert.equal(spawnSync(process.execPath, [...args, "--check"]).status, 0);
    await writeFile(css, "stale");
    assert.equal(spawnSync(process.execPath, [...args, "--check"]).status, 1);
    assert.equal(await readFile(css, "utf8"), "stale");
  } finally {
    await rm(dir, { recursive: true, force: true });
  }
});
