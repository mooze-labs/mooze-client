import { afterEach, expect, it, vi } from "vitest";
import { act, cleanup, render, screen, waitFor } from "@testing-library/react";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { WalletClientProvider } from "./client-context";
import {
  SessionProvider,
  useWalletSession,
  useWalletSnapshot,
} from "./session-provider";
import { fakeClient } from "../testing/client";
import type { DesktopEvent, Snapshot } from "../core/client";
afterEach(cleanup);
function Probe() {
  const { session } = useWalletSession();
  const snapshot = useWalletSnapshot();
  return (
    <div>
      {session?.status}
      {session?.status === "unlocked" && snapshot.data && (
        <span>secret balance</span>
      )}
    </div>
  );
}
it("lock discards a late snapshot and ignores an older unlocked event", async () => {
  const client = fakeClient();
  let emit!: (event: DesktopEvent) => void;
  let resolve!: (data: Snapshot) => void;
  vi.mocked(client.subscribe).mockImplementation(async (handler) => {
    emit = handler;
    return vi.fn();
  });
  vi.mocked(client.sessionStatus).mockResolvedValue({
    status: "unlocked",
    generation: 1,
    retry_after_ms: 0,
  });
  vi.mocked(client.snapshot).mockImplementation(
    () =>
      new Promise((r) => {
        resolve = r;
      }),
  );
  const qc = new QueryClient({ defaultOptions: { queries: { retry: false } } });
  render(
    <QueryClientProvider client={qc}>
      <WalletClientProvider client={client}>
        <SessionProvider>
          <Probe />
        </SessionProvider>
      </WalletClientProvider>
    </QueryClientProvider>,
  );
  await waitFor(() => expect(client.snapshot).toHaveBeenCalled());
  await act(async () => {
    emit({
      type: "session",
      data: { status: "locked", generation: 2, retry_after_ms: 0 },
    });
    resolve({ generation: 1 } as Snapshot);
    emit({
      type: "session",
      data: { status: "unlocked", generation: 1, retry_after_ms: 0 },
    });
  });
  expect(screen.getByText("locked")).toBeInTheDocument();
  expect(screen.queryByText("secret balance")).not.toBeInTheDocument();
  expect(qc.getQueriesData({ queryKey: ["wallet", 1] })).toEqual([]);
});
