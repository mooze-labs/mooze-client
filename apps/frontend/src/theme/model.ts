export type ThemePreference = "system" | "light" | "dark";
export type ResolvedTheme = "light" | "dark";
export function parseThemePreference(value: unknown): ThemePreference {
  return value === "light" || value === "dark" ? value : "system";
}
export function resolveTheme(
  preference: ThemePreference,
  system: ResolvedTheme,
): ResolvedTheme {
  return preference === "system" ? system : preference;
}
