import { cleanup, fireEvent, render, screen } from "@testing-library/react";
import { MemoryRouter } from "react-router-dom";
import { afterEach, beforeEach, expect, it, vi } from "vitest";
import { SidebarLayout } from "./sidebar";

afterEach(() => {
  cleanup();
  vi.unstubAllGlobals();
  vi.restoreAllMocks();
});
beforeEach(() => {
  localStorage.clear();
  vi.stubGlobal(
    "matchMedia",
    vi.fn(() => ({ matches: false })),
  );
});
function mount() {
  return render(
    <MemoryRouter initialEntries={["/history"]}>
      <SidebarLayout footer={() => <span>Footer</span>}>
        <main>Workspace</main>
      </SidebarLayout>
    </MemoryRouter>,
  );
}
it("toggles the sidebar, preserves named navigation and restores the saved mode", () => {
  const view = mount();
  fireEvent.click(
    screen.getByRole("button", { name: "Recolher barra lateral" }),
  );
  expect(
    screen.getByRole("button", { name: "Expandir barra lateral" }),
  ).toHaveAttribute("aria-expanded", "false");
  expect(screen.getByRole("link", { name: "Atividade" })).toHaveAttribute(
    "aria-current",
    "page",
  );
  expect(screen.getByRole("link", { name: "Carteira" })).toHaveAttribute(
    "href",
    "/",
  );
  view.unmount();
  mount();
  expect(
    screen.getByRole("button", { name: "Expandir barra lateral" }),
  ).toBeInTheDocument();
});
it("defaults to compact on a small window but honors an explicit expanded preference", () => {
  vi.stubGlobal(
    "matchMedia",
    vi.fn(() => ({ matches: true })),
  );
  const view = mount();
  fireEvent.click(
    screen.getByRole("button", { name: "Expandir barra lateral" }),
  );
  view.unmount();
  mount();
  expect(
    screen.getByRole("button", { name: "Recolher barra lateral" }),
  ).toBeInTheDocument();
});
it("still toggles when local storage is unavailable", () => {
  const spy = vi.spyOn(Storage.prototype, "setItem").mockImplementation(() => {
    throw new Error("Unavailable");
  });
  mount();
  fireEvent.click(
    screen.getByRole("button", { name: "Recolher barra lateral" }),
  );
  expect(
    screen.getByRole("button", { name: "Expandir barra lateral" }),
  ).toBeInTheDocument();
  spy.mockRestore();
});
