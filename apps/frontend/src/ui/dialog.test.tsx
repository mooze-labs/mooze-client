import { useState } from "react";
import { fireEvent, render, screen, waitFor } from "@testing-library/react";
import { expect, it } from "vitest";
import { Modal, Button } from "./index";

it("uses contextual dialog description and restores focus after Escape", async () => {
  function Example() {
    const [open, setOpen] = useState(false);
    return (
      <>
        <Button onClick={() => setOpen(true)}>Open</Button>
        <Modal
          title="Recovery"
          description="Keep these words private."
          open={open}
          onOpenChange={setOpen}
        >
          <input aria-label="PIN" />
        </Modal>
      </>
    );
  }
  render(<Example />);
  const trigger = screen.getByText("Open");
  trigger.focus();
  fireEvent.click(trigger);
  expect(await screen.findByRole("dialog")).toHaveAccessibleDescription(
    "Keep these words private.",
  );
  await waitFor(() =>
    expect(screen.getByRole("dialog")).toContainElement(
      document.activeElement as HTMLElement,
    ),
  );
  fireEvent.keyDown(document.activeElement!, { key: "Escape" });
  await waitFor(() =>
    expect(screen.queryByRole("dialog")).not.toBeInTheDocument(),
  );
  await waitFor(() => expect(trigger).toHaveFocus());
});
