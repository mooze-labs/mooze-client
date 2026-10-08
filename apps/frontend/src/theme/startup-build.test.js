// @vitest-environment node
import { afterAll, beforeAll, expect, it } from "vitest";
import { build } from "vite";
import {
  mkdtemp,
  readFile,
  realpath,
  rm,
  writeFile,
  mkdir,
} from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { JSDOM, ResourceLoader, VirtualConsole } from "jsdom";
import { themeBootstrap } from "../../build/theme-bootstrap";
let root;
beforeAll(async () => {
  root = await realpath(await mkdtemp(join(tmpdir(), "mooze-bootstrap-")));
  await mkdir(join(root, "public"));
  await writeFile(
    join(root, "public/observe.js"),
    "window.themeAtBody = document.documentElement.dataset.theme;",
  );
  await writeFile(
    join(root, "index.html"),
    '<!doctype html><html><head></head><body><div id="root"></div><script src="/observe.js"></script><script type="module" src="/entry.js"></script></body></html>',
  );
  await writeFile(
    join(root, "entry.js"),
    'document.getElementById("root").textContent="Ready";',
  );
  await build({
    configFile: false,
    root,
    logLevel: "silent",
    plugins: [themeBootstrap()],
    build: { outDir: "dist" },
  });
});
afterAll(async () => {
  await rm(root, { recursive: true, force: true });
});
it.each([
  ["dark", false, "dark"],
  ["light", true, "light"],
  ["system", true, "dark"],
])(
  "establishes %s before body parsing despite delayed bootstrap",
  async (saved, osDark, expected) => {
    const html = await readFile(join(root, "dist/index.html"), "utf8");
    const loader = new (class extends ResourceLoader {
      fetch(url) {
        return new Promise((resolveFile, reject) =>
          setTimeout(
            () =>
              readFile(join(root, "dist", new URL(url).pathname)).then(
                resolveFile,
                reject,
              ),
            30,
          ),
        );
      }
    })();
    const dom = new JSDOM(html, {
      url: "https://mooze.test/",
      runScripts: "dangerously",
      resources: loader,
      virtualConsole: new VirtualConsole(),
      beforeParse(window) {
        window.localStorage.setItem("mooze.theme", saved);
        window.matchMedia = () => ({ matches: osDark });
      },
    });
    await new Promise((resolveLoaded) =>
      dom.window.addEventListener("load", resolveLoaded),
    );
    expect(dom.window.themeAtBody).toBe(expected);
    expect(dom.window.document.documentElement.style.colorScheme).toBe(
      expected,
    );
    dom.window.close();
  },
);
