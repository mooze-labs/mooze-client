import { useRef, useState } from "react";
import { cleanup, fireEvent, render, screen } from "@testing-library/react";
import { MemoryRouter, useNavigate } from "react-router-dom";
import { afterEach, expect, it, vi } from "vitest";
import { ScreenTransition } from "./screen-transition";
const state = vi.hoisted(() => ({
  reduced: false,
  animate: vi.fn(),
  cancel: vi.fn(),
}));
vi.mock("motion/react", () => ({ useReducedMotion: () => state.reduced }));
vi.mock("motion/react-mini", () => ({
  useAnimate: () => [useRef(null), state.animate],
}));
function Example() {
  const navigate = useNavigate();
  const [value, setValue] = useState(0);
  return (
    <>
      <button onClick={() => navigate("/history")}>Navigate</button>
      <button onClick={() => navigate("/history?tx=123")}>Details</button>
      <ScreenTransition>
        <button onClick={() => setValue(value + 1)}>Value {value}</button>
      </ScreenTransition>
    </>
  );
}
function setup() {
  vi.spyOn(document, "hidden", "get").mockReturnValue(false);
  Object.defineProperty(Element.prototype, "animate", {
    configurable: true,
    value: vi.fn(),
  });
  state.animate.mockReturnValue({ cancel: state.cancel });
  return render(
    <MemoryRouter>
      <Example />
    </MemoryRouter>,
  );
}
afterEach(() => {
  cleanup();
  delete (Element.prototype as Partial<Element>).animate;
  vi.restoreAllMocks();
  state.reduced = false;
  state.animate.mockClear();
  state.cancel.mockClear();
});
it("animates pathname navigation without replaying for data or query changes or resetting local state", () => {
  setup();
  expect(state.animate).toHaveBeenCalledTimes(1);
  fireEvent.click(screen.getByText("Value 0"));
  expect(state.animate).toHaveBeenCalledTimes(1);
  fireEvent.click(screen.getByText("Navigate"));
  expect(state.animate).toHaveBeenCalledTimes(2);
  expect(state.cancel).toHaveBeenCalledTimes(1);
  expect(screen.getByText("Value 1")).toBeVisible();
  fireEvent.click(screen.getByText("Details"));
  expect(state.animate).toHaveBeenCalledTimes(2);
});
it("shows content immediately without motion when reduced motion is enabled", () => {
  state.reduced = true;
  setup();
  fireEvent.click(screen.getByText("Navigate"));
  expect(screen.getByText("Value 0")).toBeVisible();
  expect(state.animate).not.toHaveBeenCalled();
});
it("cancels an entrance when the window becomes hidden", () => {
  setup();
  vi.spyOn(document, "hidden", "get").mockReturnValue(true);
  fireEvent(document, new Event("visibilitychange"));
  expect(state.cancel).toHaveBeenCalledTimes(1);
});
