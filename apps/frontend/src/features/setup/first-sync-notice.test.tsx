import { afterEach, expect, it, vi } from "vitest";
import {
  cleanup,
  fireEvent,
  render,
  screen,
  waitFor,
} from "@testing-library/react";
import { FirstSyncNotice } from "./first-sync-notice";
afterEach(cleanup);
it("distinguishes a saved wallet from an unfinished or failed first sync", async () => {
  const retry = vi.fn().mockRejectedValue(new Error("offline"));
  const { rerender } = render(
    <FirstSyncNotice
      chains={[
        {
          chain: "Bitcoin",
          phase: "ready",
          last_success_at_ms: 100,
          error: null,
        },
        {
          chain: "Liquid",
          phase: "error",
          last_success_at_ms: null,
          error: "network",
        },
      ]}
      retry={retry}
    />,
  );
  expect(screen.getByRole("status")).toHaveTextContent("carteira está salva");
  expect(screen.getByText("Falha de conexão")).toBeVisible();
  fireEvent.click(screen.getByRole("button", { name: "Tentar novamente" }));
  await waitFor(() =>
    expect(screen.getByRole("alert")).toHaveTextContent("offline"),
  );
  rerender(
    <FirstSyncNotice
      chains={[
        {
          chain: "Bitcoin",
          phase: "ready",
          last_success_at_ms: 100,
          error: null,
        },
        {
          chain: "Liquid",
          phase: "ready",
          last_success_at_ms: 200,
          error: null,
        },
      ]}
      retry={retry}
    />,
  );
  expect(screen.queryByRole("status")).not.toBeInTheDocument();
});
