import { expect, it } from "vitest";
import { parseThemePreference, resolveTheme } from "./model";
it.each([
  ["system", "light", "light"],
  ["system", "dark", "dark"],
  ["light", "light", "light"],
  ["light", "dark", "light"],
  ["dark", "light", "dark"],
  ["dark", "dark", "dark"],
] as const)("resolves %s with %s to %s", (preference, system, expected) =>
  expect(resolveTheme(preference, system)).toBe(expected),
);
it.each([undefined, null, "invalid", "LIGHT", {}, 42])(
  "defaults invalid persisted value %j to system",
  (value) => expect(parseThemePreference(value)).toBe("system"),
);
