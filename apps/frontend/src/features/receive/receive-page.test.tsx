import { NetworkContext } from "../../core/network";
import { afterEach, expect, it, vi } from "vitest";
import {
  cleanup,
  fireEvent,
  render,
  screen,
  waitFor,
} from "@testing-library/react";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { MemoryRouter } from "react-router-dom";
import { WalletClientProvider } from "../../app/client-context";
import { fakeClient } from "../../testing/client";
import { ReceivePage } from "./receive-page";
vi.mock("../../app/session-provider", () => ({
  useWalletSession: () => ({ session: { generation: 1, status: "unlocked" } }),
}));
afterEach(cleanup);
it("copies an address separately from the exact TEST payment request", async () => {
  const client = fakeClient();
  const id = "38fca2d939696061a8f76d4e6b5eecd54e3b4221c846f24a6b279e79952850a5";
  vi.mocked(client.approvedAssets).mockResolvedValue([
    {
      key: { chain: "Liquid", asset_id: id },
      ticker: "TEST",
      precision: 8,
      approved: true,
    },
  ]);
  vi.mocked(client.receiveRequest).mockImplementation(
    async (_asset, units) => ({
      address: "tlq-address",
      uri: `liquidtestnet:tlq-address?assetid=${id}${units ? "&amount=0.00000001" : ""}`,
    }),
  );
  const writeText = vi.fn(async () => {});
  Object.defineProperty(navigator, "clipboard", {
    configurable: true,
    value: { writeText },
  });
  render(
    <QueryClientProvider
      client={
        new QueryClient({ defaultOptions: { queries: { retry: false } } })
      }
    >
      <WalletClientProvider client={client}>
        <MemoryRouter initialEntries={[`/receive?chain=Liquid&asset=${id}`]}>
          <NetworkContext.Provider value="Testnet">
            <ReceivePage />
          </NetworkContext.Provider>
        </MemoryRouter>
      </WalletClientProvider>
    </QueryClientProvider>,
  );
  fireEvent.change(
    await screen.findByLabelText("Quantidade solicitada (opcional)"),
    { target: { value: "0.00000001" } },
  );
  await waitFor(() =>
    expect(client.receiveRequest).toHaveBeenLastCalledWith(
      { chain: "Liquid", asset_id: id },
      "1",
      null,
    ),
  );
  fireEvent.click(
    await screen.findByRole("button", { name: "Copiar endereço" }),
  );
  await waitFor(() =>
    expect(writeText).toHaveBeenLastCalledWith("tlq-address"),
  );
  fireEvent.click(
    screen.getByRole("button", { name: "Copiar pedido de pagamento" }),
  );
  await waitFor(() =>
    expect(writeText).toHaveBeenLastCalledWith(
      `liquidtestnet:tlq-address?assetid=${id}&amount=0.00000001`,
    ),
  );
});
it("keeps the current asset when an older request resolves last and hides invalid requests", async () => {
  const client = fakeClient();
  const id = "38fca2d939696061a8f76d4e6b5eecd54e3b4221c846f24a6b279e79952850a5";
  vi.mocked(client.approvedAssets).mockResolvedValue([
    {
      key: { chain: "Bitcoin", asset_id: null },
      ticker: "BTC",
      precision: 8,
      approved: true,
    },
    {
      key: { chain: "Liquid", asset_id: id },
      ticker: "TEST",
      precision: 8,
      approved: true,
    },
  ]);
  let resolveOld!: (value: { address: string; uri: string }) => void;
  vi.mocked(client.receiveRequest).mockImplementation((asset) =>
    asset.chain === "Liquid"
      ? new Promise((resolve) => {
          resolveOld = resolve;
        })
      : Promise.resolve({ address: "tb1-current", uri: "bitcoin:tb1-current" }),
  );
  render(
    <QueryClientProvider
      client={
        new QueryClient({ defaultOptions: { queries: { retry: false } } })
      }
    >
      <WalletClientProvider client={client}>
        <MemoryRouter initialEntries={[`/receive?chain=Liquid&asset=${id}`]}>
          <NetworkContext.Provider value="Testnet">
            <ReceivePage />
          </NetworkContext.Provider>
        </MemoryRouter>
      </WalletClientProvider>
    </QueryClientProvider>,
  );
  await waitFor(() => expect(client.receiveRequest).toHaveBeenCalled());
  fireEvent.click(screen.getByRole("combobox", { name: "Ativo" }));
  fireEvent.pointerDown(
    screen.getByRole("option", { name: "BTC · Bitcoin Testnet" }),
  );
  fireEvent.click(
    screen.getByRole("option", { name: "BTC · Bitcoin Testnet" }),
  );
  await screen.findByText("tb1-current");
  resolveOld({
    address: "old-test-address",
    uri: `liquidtestnet:old-test-address?assetid=${id}`,
  });
  await waitFor(() =>
    expect(screen.queryByText("old-test-address")).not.toBeInTheDocument(),
  );
  fireEvent.change(screen.getByLabelText("Quantidade solicitada (opcional)"), {
    target: { value: "0.000000001" },
  });
  expect(
    screen.queryByRole("button", { name: "Copiar endereço" }),
  ).not.toBeInTheDocument();
  expect(document.querySelector(".qr svg")).toBeNull();
});
