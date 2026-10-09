import { afterEach, expect, it, vi } from "vitest";
import {
  cleanup,
  fireEvent,
  render,
  screen,
  waitFor,
} from "@testing-library/react";
import { CopyButton } from "./copy-button";
afterEach(() => {
  cleanup();
  vi.useRealTimers();
});
it("only confirms successful copying, keeps its accessible purpose, and reports failure", async () => {
  const copied = vi.fn();
  const writeText = vi.fn().mockResolvedValue(undefined);
  Object.defineProperty(navigator, "clipboard", {
    configurable: true,
    value: { writeText },
  });
  const { rerender } = render(
    <CopyButton value="request-uri" label="Copy request" onCopied={copied} />,
  );
  fireEvent.click(screen.getByRole("button", { name: "Copy request" }));
  await screen.findByText("Copiado");
  expect(copied).toHaveBeenCalledExactlyOnceWith();
  expect(writeText).toHaveBeenCalledWith("request-uri");
  expect(screen.getByRole("button", { name: "Copy request" })).toBeEnabled();
  rerender(
    <CopyButton value="new-uri" label="Copy request" onCopied={copied} />,
  );
  expect(screen.queryByText("Copiado")).not.toBeInTheDocument();
  writeText.mockRejectedValue(new Error("clipboard denied"));
  fireEvent.click(screen.getByRole("button", { name: "Copy request" }));
  await waitFor(() =>
    expect(screen.getByRole("status")).toHaveTextContent(
      "Não foi possível copiar",
    ),
  );
  expect(screen.queryByText("Copiado")).not.toBeInTheDocument();
  expect(copied).toHaveBeenCalledTimes(1);
});
