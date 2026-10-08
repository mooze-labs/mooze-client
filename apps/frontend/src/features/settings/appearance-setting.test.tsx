import {
  cleanup,
  fireEvent,
  render,
  screen,
  waitFor,
} from "@testing-library/react";
import { afterEach, expect, it, vi } from "vitest";
import { ThemeProvider } from "../../theme/theme-provider";
import { createMemoryThemeStorage } from "../../theme/storage";
import { PreferencesContext } from "../../i18n/preferences";
import { AppearanceSetting } from "./appearance-setting";
import { DisplayPage } from "./display-page";
afterEach(cleanup);
it.each([
  ["pt-BR", "Aparência", "Escuro", "Claro", "Sistema"],
  ["en", "Appearance", "Dark", "Light", "System"],
  ["es", "Apariencia", "Oscuro", "Claro", "Sistema"],
] as const)(
  "selects all appearance modes in %s",
  async (locale, label, dark, light, system) => {
    const storage = createMemoryThemeStorage();
    const save = vi.fn();
    render(
      <ThemeProvider storage={storage}>
        <PreferencesContext.Provider
          value={{
            preferences: { locale, bitcoinUnit: "BTC", privacy: false },
            save,
          }}
        >
          <AppearanceSetting />
        </PreferencesContext.Provider>
      </ThemeProvider>,
    );
    for (const [name, value] of [
      [dark, "dark"],
      [light, "light"],
      [system, "system"],
    ]) {
      fireEvent.click(screen.getByRole("combobox", { name: label }));
      const option = screen.getByRole("option", { name });
      fireEvent.pointerDown(option);
      fireEvent.click(option);
      await waitFor(() => expect(storage.read()).toBe(value));
      if (value !== "system")
        expect(document.documentElement.dataset.theme).toBe(value);
    }
    expect(save).not.toHaveBeenCalled();
  },
);
it("shows a localized save failure while applying the requested appearance", async () => {
  const storage = {
    ...createMemoryThemeStorage(),
    write: () => {
      throw new Error("quota");
    },
  };
  render(
    <ThemeProvider storage={storage}>
      <AppearanceSetting />
    </ThemeProvider>,
  );
  fireEvent.click(screen.getByRole("combobox", { name: "Aparência" }));
  const option = screen.getByRole("option", { name: "Escuro" });
  fireEvent.pointerDown(option);
  fireEvent.click(option);
  expect(await screen.findByRole("status")).toHaveTextContent(
    "Não foi possível salvar a aparência",
  );
  expect(document.documentElement.dataset.theme).toBe("dark");
});
it("remains enabled while wallet display settings are saving", async () => {
  const save = vi.fn(() => new Promise<void>(() => {}));
  render(
    <ThemeProvider storage={createMemoryThemeStorage()}>
      <PreferencesContext.Provider
        value={{
          preferences: { locale: "pt-BR", bitcoinUnit: "BTC", privacy: false },
          save,
        }}
      >
        <DisplayPage />
      </PreferencesContext.Provider>
    </ThemeProvider>,
  );
  fireEvent.click(screen.getByRole("switch", { name: "Ocultar valores" }));
  expect(screen.getByRole("combobox", { name: "Idioma" })).toBeDisabled();
  expect(screen.getByRole("combobox", { name: "Aparência" })).toBeEnabled();
});
