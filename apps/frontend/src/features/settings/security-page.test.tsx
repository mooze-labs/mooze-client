import { afterEach, expect, it, vi } from "vitest";
import {
  cleanup,
  fireEvent,
  render,
  screen,
  waitFor,
} from "@testing-library/react";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { WalletClientProvider } from "../../app/client-context";
import { fakeClient } from "../../testing/client";
import { SecurityPage } from "./security-page";
vi.mock("../../app/session-provider", () => ({
  useWalletSession: () => ({ session: { generation: 1, status: "unlocked" } }),
}));
afterEach(cleanup);
it("does not share PIN input between recovery and change-PIN operations", () => {
  const client = fakeClient();
  vi.mocked(client.settings).mockImplementation(() => new Promise(() => {}));
  render(
    <QueryClientProvider client={new QueryClient()}>
      <WalletClientProvider client={client}>
        <SecurityPage />
      </WalletClientProvider>
    </QueryClientProvider>,
  );
  fireEvent.click(
    screen.getByRole("button", { name: "Ver frase de recuperação" }),
  );
  fireEvent.change(screen.getByLabelText("PIN para recuperação"), {
    target: { value: "123456" },
  });
  fireEvent.click(screen.getByRole("button", { name: "Cancelar" }));
  fireEvent.click(screen.getByRole("button", { name: "Alterar PIN" }));
  expect(screen.getByLabelText("PIN atual")).toHaveValue("");
  expect(
    screen.queryByLabelText("PIN para recuperação"),
  ).not.toBeInTheDocument();
});
it("requires wallet PIN for native preference changes and preserves disabled state on failure", async () => {
  const client = fakeClient();
  vi.mocked(client.settings).mockImplementation(() => new Promise(() => {}));
  vi.mocked(client.nativeAuthStatus).mockResolvedValue({
    kind: "windows_hello",
    availability: "available",
    enabled: false,
    setup_offer_pending: false,
  });
  vi.mocked(client.setNativeAuthEnabled).mockRejectedValue({
    code: "storage",
    message: "Storage failed",
  });
  render(
    <QueryClientProvider client={new QueryClient()}>
      <WalletClientProvider client={client}>
        <SecurityPage />
      </WalletClientProvider>
    </QueryClientProvider>,
  );
  const enable = await screen.findByRole("button", {
    name: "Ativar Windows Hello",
  });
  await waitFor(() => expect(enable).toBeEnabled());
  fireEvent.click(enable);
  expect(client.setNativeAuthEnabled).not.toHaveBeenCalled();
  fireEvent.change(screen.getByLabelText("PIN da carteira"), {
    target: { value: "123456" },
  });
  fireEvent.click(
    screen.getByRole("button", { name: "Confirmar autenticação" }),
  );
  expect(await screen.findByText("Storage failed")).toBeInTheDocument();
  expect(client.setNativeAuthEnabled).toHaveBeenCalledWith(true, "123456");
  expect(screen.getByLabelText("PIN da carteira")).toHaveValue("");
  fireEvent.click(screen.getByRole("button", { name: "Cancelar" }));
  expect(
    screen.getByRole("button", { name: "Ativar Windows Hello" }),
  ).toBeInTheDocument();
});
