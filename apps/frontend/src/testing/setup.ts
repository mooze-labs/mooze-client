import "@testing-library/jest-dom/vitest";

// jsdom 26 lacks PointerEvent, used by Base UI to forward checkbox/switch clicks.
if (!window.PointerEvent) {
  class TestPointerEvent extends MouseEvent {
    readonly pointerType: string;
    readonly pointerId: number;
    readonly isPrimary: boolean;
    constructor(type: string, init: PointerEventInit = {}) {
      super(type, init);
      this.pointerType = init.pointerType ?? "";
      this.pointerId = init.pointerId ?? 0;
      this.isPrimary = init.isPrimary ?? false;
    }
  }
  Object.defineProperty(window, "PointerEvent", { value: TestPointerEvent });
}
