import {
  cleanup,
  render,
  screen,
  fireEvent,
  waitFor,
} from "@testing-library/react";
import { afterEach, expect, it, vi } from "vitest";
import { SelectField } from "./select-field";
afterEach(cleanup);
it("labels the trigger, displays its value before opening, and selects an option", async () => {
  const onValueChange = vi.fn();
  render(
    <SelectField
      label="Network"
      value="Bitcoin"
      onValueChange={onValueChange}
      items={[
        { value: "Bitcoin", label: "Bitcoin Testnet" },
        { value: "Liquid", label: "Liquid Testnet" },
      ]}
    />,
  );
  const trigger = screen.getByRole("combobox", { name: "Network" });
  expect(trigger).toHaveTextContent("Bitcoin Testnet");
  fireEvent.click(trigger);
  const option = await screen.findByRole("option", { name: "Liquid Testnet" });
  fireEvent.pointerDown(option);
  fireEvent.click(option);
  await waitFor(() => expect(onValueChange).toHaveBeenCalledWith("Liquid"));
});
it("keeps disabled selectors closed", () => {
  render(
    <SelectField
      label="Network"
      value=""
      disabled
      onValueChange={vi.fn()}
      items={[{ value: "", label: "All networks" }]}
    />,
  );
  const trigger = screen.getByRole("combobox", { name: "Network" });
  expect(trigger).toBeDisabled();
  fireEvent.click(trigger);
  expect(screen.queryByRole("listbox")).not.toBeInTheDocument();
});
