import { expect, it, afterEach } from "vitest";
import { render, screen, cleanup } from "@testing-library/react";
import { SensitiveValue } from "./sensitive-value";
afterEach(cleanup);
it("conceals values from text accessible labels and tooltips", () => {
  const { container } = render(
    <SensitiveValue hidden>123.456 TEST</SensitiveValue>,
  );
  expect(container.textContent).not.toContain("123.456");
  expect(container.innerHTML).not.toContain("123.456");
  expect(screen.getByLabelText("Valor oculto")).toBeInTheDocument();
});
