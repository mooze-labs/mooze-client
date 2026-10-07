import { afterEach, expect, it, vi } from "vitest";
import {
  cleanup,
  fireEvent,
  render,
  screen,
  waitFor,
} from "@testing-library/react";
import { fakeClient } from "../../testing/client";
import { NativeAuthOffer } from "./native-auth-offer";
afterEach(cleanup);
const status = {
  kind: "touch_id",
  availability: "available",
  enabled: false,
  setup_offer_pending: true,
} as const;
it("only continues after native enrollment is confirmed, and cancellation permits skip", async () => {
  const client = fakeClient();
  const done = vi.fn();
  vi.mocked(client.completeNativeAuthOffer).mockRejectedValueOnce({
    code: "native_cancelled",
  });
  render(<NativeAuthOffer client={client} status={status} onDone={done} />);
  fireEvent.click(screen.getByRole("button", { name: "Ativar Touch ID" }));
  await waitFor(() =>
    expect(screen.getByRole("button", { name: "Agora não" })).toBeEnabled(),
  );
  expect(done).not.toHaveBeenCalled();
  expect(screen.queryByRole("alert")).not.toBeInTheDocument();
  fireEvent.click(screen.getByRole("button", { name: "Agora não" }));
  await waitFor(() => expect(done).toHaveBeenCalledOnce());
  expect(client.completeNativeAuthOffer).toHaveBeenLastCalledWith(false);
});
it("successful enrollment uses the backend result", async () => {
  const client = fakeClient();
  const done = vi.fn();
  const enabled = { ...status, enabled: true, setup_offer_pending: false };
  vi.mocked(client.completeNativeAuthOffer).mockResolvedValue(enabled);
  render(<NativeAuthOffer client={client} status={status} onDone={done} />);
  fireEvent.click(screen.getByRole("button", { name: "Ativar Touch ID" }));
  await waitFor(() => expect(done).toHaveBeenCalledWith(enabled));
});
