import { useState } from "react";
import { afterEach, expect, it, vi } from "vitest";
import { cleanup, fireEvent, render, screen } from "@testing-library/react";
import { PinField } from "./pin-field";
afterEach(cleanup);
function Harness({ disabled = false }: { disabled?: boolean }) {
  const [value, setValue] = useState("");
  return (
    <PinField
      label="PIN"
      value={value}
      onValueChange={setValue}
      disabled={disabled}
    />
  );
}
it("masks every slot immediately and exposes one password input with its label", () => {
  const { container } = render(<Harness />);
  const input = screen.getByLabelText("PIN");
  expect(input).toHaveAttribute("type", "password");
  expect(input).toHaveAttribute("inputmode", "numeric");
  fireEvent.change(input, { target: { value: "123456" } });
  expect(input).toHaveValue("123456");
  expect(
    container.querySelectorAll('[data-slot="input-otp-slot"]'),
  ).toHaveLength(6);
  expect(container.textContent).not.toMatch(/[1-6]/);
  expect(container.textContent).toContain("••••••");
  expect(
    container.querySelector('[data-slot="input-otp-group"]'),
  ).toHaveAttribute("aria-hidden", "true");
  fireEvent.change(input, { target: { value: "12345" } });
  expect(input).toHaveValue("12345");
  expect(container.querySelectorAll('[data-filled="true"]')).toHaveLength(5);
});
it("accepts numeric paste, rejects other characters, and never submits on completion", () => {
  const submit = vi.fn((e: React.FormEvent) => e.preventDefault());
  render(
    <form onSubmit={submit}>
      <Harness />
    </form>,
  );
  const input = screen.getByLabelText("PIN") as HTMLInputElement;
  fireEvent.change(input, { target: { value: "12x" } });
  expect(input).toHaveValue("");
  input.focus();
  input.setSelectionRange(0, 0);
  fireEvent.paste(input, { clipboardData: { getData: () => "654321" } });
  expect(input).toHaveValue("654321");
  expect(submit).not.toHaveBeenCalled();
});
it("preserves disabled and invalid states with an accessible error description", () => {
  render(
    <PinField
      label="PIN"
      value=""
      onValueChange={vi.fn()}
      disabled
      invalid
      help="Try again"
    />,
  );
  expect(screen.getByLabelText("PIN")).toBeDisabled();
  expect(screen.getByLabelText("PIN")).toHaveAttribute("aria-invalid", "true");
  expect(screen.getByLabelText("PIN")).toHaveAccessibleDescription("Try again");
});
