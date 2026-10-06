import { render, screen, fireEvent, waitFor } from "@testing-library/react";
import { expect, it, vi } from "vitest";
import { PreferencesContext } from "../../i18n/preferences";
import { DisplayPage } from "./display-page";
it("exposes privacy as a labeled switch and saves the complete preference value", async () => {
  const save = vi.fn(async () => {});
  render(
    <PreferencesContext.Provider
      value={{
        preferences: { locale: "pt-BR", bitcoinUnit: "sat", privacy: false },
        save,
      }}
    >
      <DisplayPage />
    </PreferencesContext.Provider>,
  );
  fireEvent.click(screen.getByRole("switch", { name: "Ocultar valores" }));
  await waitFor(() =>
    expect(save).toHaveBeenCalledWith({
      locale: "pt-BR",
      bitcoinUnit: "sat",
      privacy: true,
    }),
  );
});
