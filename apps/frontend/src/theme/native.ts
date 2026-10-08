import { isTauri } from "@tauri-apps/api/core";
import type { ThemePreference } from "./model";
export async function setNativeTheme(
  preference: ThemePreference,
): Promise<void> {
  if (!isTauri()) return;
  const { getCurrentWindow } = await import("@tauri-apps/api/window");
  await getCurrentWindow().setTheme(
    preference === "system" ? null : preference,
  );
}
