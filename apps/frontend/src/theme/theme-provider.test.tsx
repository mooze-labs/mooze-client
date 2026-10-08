import { StrictMode } from "react";
import {
  act,
  cleanup,
  fireEvent,
  render,
  screen,
  waitFor,
} from "@testing-library/react";
import { afterEach, beforeEach, expect, it, vi } from "vitest";
import { ThemeProvider, useTheme } from "./theme-provider";
import { createBrowserThemeStorage, createMemoryThemeStorage } from "./storage";
let dark = false;
let listeners: Set<() => void>;
beforeEach(() => {
  dark = false;
  listeners = new Set();
  localStorage.clear();
  vi.stubGlobal("matchMedia", () => ({
    get matches() {
      return dark;
    },
    addEventListener: (_name: string, listener: () => void) =>
      listeners.add(listener),
    removeEventListener: (_name: string, listener: () => void) =>
      listeners.delete(listener),
  }));
});
afterEach(() => {
  cleanup();
  vi.unstubAllGlobals();
  vi.restoreAllMocks();
  delete document.documentElement.dataset.theme;
});
function Controls() {
  const theme = useTheme();
  return (
    <>
      <output>
        {theme.preference}/{theme.resolvedTheme}/
        {String(theme.persistenceError)}
      </output>
      {(["system", "light", "dark"] as const).map((mode) => (
        <button key={mode} onClick={() => theme.setPreference(mode)}>
          {mode}
        </button>
      ))}
    </>
  );
}
function os(value: boolean) {
  act(() => {
    dark = value;
    listeners.forEach((listener) => listener());
  });
}
it("restores overrides, follows system only when selected, and cleans listeners in StrictMode", () => {
  const storage = createMemoryThemeStorage("dark");
  const view = render(
    <StrictMode>
      <ThemeProvider storage={storage}>
        <Controls />
      </ThemeProvider>
    </StrictMode>,
  );
  expect(document.documentElement.dataset.theme).toBe("dark");
  expect(listeners.size).toBe(1);
  os(true);
  fireEvent.click(screen.getByText("light"));
  os(false);
  os(true);
  expect(screen.getByRole("status")).toHaveTextContent("light/light/false");
  fireEvent.click(screen.getByText("system"));
  expect(document.documentElement.dataset.theme).toBe("dark");
  os(false);
  expect(document.documentElement.style.colorScheme).toBe("light");
  view.unmount();
  expect(listeners.size).toBe(0);
});
it("updates in memory and reports failed persistence, clearing the error after recovery", () => {
  let fail = true;
  const storage = {
    ...createMemoryThemeStorage(),
    write: () => {
      if (fail) throw new Error("quota");
    },
  };
  render(
    <ThemeProvider storage={storage}>
      <Controls />
    </ThemeProvider>,
  );
  fireEvent.click(screen.getByText("dark"));
  expect(screen.getByRole("status")).toHaveTextContent("dark/dark/true");
  fail = false;
  fireEvent.click(screen.getByText("light"));
  expect(screen.getByRole("status")).toHaveTextContent("light/light/false");
});
it("survives denied localStorage access and invalid stored preferences", () => {
  const original = Object.getOwnPropertyDescriptor(window, "localStorage")!;
  Object.defineProperty(window, "localStorage", {
    configurable: true,
    get: () => {
      throw new Error("denied");
    },
  });
  try {
    render(
      <ThemeProvider storage={createBrowserThemeStorage()}>
        <Controls />
      </ThemeProvider>,
    );
    expect(screen.getByRole("status")).toHaveTextContent("system/light/false");
    fireEvent.click(screen.getByText("dark"));
    expect(document.documentElement.dataset.theme).toBe("dark");
  } finally {
    Object.defineProperty(window, "localStorage", original);
  }
});
it("handles cross-window changes and removal without echo writes or unrelated events", () => {
  const storage = createBrowserThemeStorage();
  const write = vi.spyOn(storage, "write");
  localStorage.setItem("mooze.theme", "invalid");
  render(
    <ThemeProvider storage={storage}>
      <Controls />
    </ThemeProvider>,
  );
  const update = (key: string | null, newValue: string | null) =>
    act(() =>
      window.dispatchEvent(
        new StorageEvent("storage", {
          key,
          newValue,
          storageArea: localStorage,
        }),
      ),
    );
  update("mooze.display", "dark");
  expect(document.documentElement.dataset.theme).toBe("light");
  update("mooze.theme", "dark");
  expect(document.documentElement.dataset.theme).toBe("dark");
  update("mooze.theme", null);
  expect(screen.getByRole("status")).toHaveTextContent("system/light/false");
  update("mooze.theme", "dark");
  update(null, null);
  expect(document.documentElement.dataset.theme).toBe("light");
  expect(write).not.toHaveBeenCalled();
});
it("serializes native changes and recovers after rejection without blocking the DOM", async () => {
  let release: () => void = () => {};
  const calls: string[] = [];
  const native = async (mode: string) => {
    calls.push(mode);
    if (calls.length === 1)
      await new Promise<void>((resolve) => {
        release = resolve;
      });
    if (mode === "light") throw new Error("native unavailable");
  };
  render(
    <ThemeProvider
      storage={createMemoryThemeStorage("dark")}
      applyNative={native}
    >
      <Controls />
    </ThemeProvider>,
  );
  await waitFor(() => expect(calls).toEqual(["dark"]));
  fireEvent.click(screen.getByText("light"));
  fireEvent.click(screen.getByText("system"));
  expect(document.documentElement.dataset.theme).toBe("light");
  await act(async () => release());
  await waitFor(() => expect(calls.at(-1)).toBe("system"));
});

it("reconciles a preference changed after bootstrap but before provider subscription", () => {
  const storage = createMemoryThemeStorage("light");
  const initialPreference = "light" as const;
  storage.write("dark");
  render(
    <ThemeProvider storage={storage} initialPreference={initialPreference}>
      <Controls />
    </ThemeProvider>,
  );
  expect(screen.getByRole("status")).toHaveTextContent("dark/dark/false");
});

it("recovers after an active native request rejects", async () => {
  const warning = vi.spyOn(console, "warn").mockImplementation(() => {});
  const calls: string[] = [];
  const applyNative = async (mode: string) => {
    calls.push(mode);
    if (mode === "dark") throw new Error("native denied");
  };
  render(
    <ThemeProvider
      storage={createMemoryThemeStorage("dark")}
      applyNative={applyNative}
    >
      <Controls />
    </ThemeProvider>,
  );
  await waitFor(() => expect(warning).toHaveBeenCalledOnce());
  expect(document.documentElement.dataset.theme).toBe("dark");
  fireEvent.click(screen.getByText("light"));
  await waitFor(() => expect(calls).toEqual(["dark", "light"]));
  expect(document.documentElement.dataset.theme).toBe("light");
});
