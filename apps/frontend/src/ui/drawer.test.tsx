import { useRef } from "react";
import { render, screen, cleanup } from "@testing-library/react";
import { afterEach, expect, it, vi } from "vitest";
import { Modal } from "./dialog";
const state = vi.hoisted(() => ({
  reduced: false,
  animate: vi.fn(),
  cancel: vi.fn(),
}));
vi.mock("motion/react", () => ({ useReducedMotion: () => state.reduced }));
vi.mock("motion/react-mini", () => ({
  useAnimate: () => [useRef(null), state.animate],
}));
afterEach(() => {
  cleanup();
  vi.unstubAllGlobals();
  vi.restoreAllMocks();
  state.reduced = false;
  state.animate.mockClear();
  state.cancel.mockClear();
});
function setup() {
  // jsdom has no Web Animations API; exercise the integration through Motion's boundary.
  vi.spyOn(document, "hidden", "get").mockReturnValue(false);
  Object.defineProperty(Element.prototype, "animate", {
    configurable: true,
    value: vi.fn(),
  });
  state.animate.mockReturnValue({ cancel: state.cancel });
}
afterEach(() => {
  delete (Element.prototype as Partial<Element>).animate;
});
it("animates a mounted drawer and cancels motion when it unmounts", async () => {
  setup();
  const view = render(
    <Modal title="Details" presentation="drawer" open onOpenChange={() => {}}>
      Transaction
    </Modal>,
  );
  expect(await screen.findByRole("dialog", { name: "Details" })).toBeVisible();
  expect(state.animate).toHaveBeenCalledTimes(2);
  view.unmount();
  expect(state.cancel).toHaveBeenCalledTimes(2);
});
it("keeps the drawer accessible without animation when reduced motion is requested", async () => {
  setup();
  state.reduced = true;
  render(
    <Modal title="Details" presentation="drawer" open onOpenChange={() => {}}>
      Transaction
    </Modal>,
  );
  expect(await screen.findByRole("dialog", { name: "Details" })).toBeVisible();
  expect(state.animate).not.toHaveBeenCalled();
});
