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
import { SwapPage } from "./swap-page";
vi.mock("../../app/session-provider", () => ({
  useWalletSession: () => ({ session: { generation: 1, status: "unlocked" } }),
}));
afterEach(cleanup);
it("reverses the assets and discards the previous amount and quote", async () => {
  const client = fakeClient();
  vi.mocked(client.hostInfo).mockResolvedValue({
    network: "Mainnet",
    backend: "Electrum",
    liquid_policy_asset: "lbtc",
    bitcoin_endpoints: [],
    liquid_endpoints: [],
    pix_enabled: true,
    swaps_enabled: true,
  });
  vi.mocked(client.swapMarkets).mockResolvedValue([
    {
      base_asset_id: "lbtc",
      quote_asset_id: "usdt",
      fee_asset: "Quote",
      market_type: "Stablecoin",
    },
  ]);
  vi.mocked(client.approvedAssets).mockResolvedValue(
    ["L-BTC", "USDT"].map((ticker, i) => ({
      key: { chain: "Liquid", asset_id: i ? "usdt" : "lbtc" },
      ticker,
      precision: 8,
      approved: true,
    })),
  );
  vi.mocked(client.holdings).mockResolvedValue({
    generation: 1,
    holdings: [],
    chains: [],
  });
  vi.mocked(client.swapStart).mockResolvedValue({
    phase: "Quoting",
    review: null,
    txid: null,
    message: null,
  });
  render(
    <QueryClientProvider
      client={
        new QueryClient({ defaultOptions: { queries: { retry: false } } })
      }
    >
      <WalletClientProvider client={client}>
        <SwapPage />
      </WalletClientProvider>
    </QueryClientProvider>,
  );
  const input = await screen.findByLabelText("Quantidade a trocar");
  fireEvent.change(input, { target: { value: "0,01" } });
  fireEvent.click(screen.getByRole("button", { name: "Inverter ativos" }));
  expect(input).toHaveValue("");
  expect(
    screen.getByRole("combobox", { name: "Ativo de origem" }),
  ).toHaveTextContent("USDT");
  expect(
    screen.getByRole("combobox", { name: "Ativo de destino" }),
  ).toHaveTextContent("L-BTC");
  expect(client.swapStop).toHaveBeenCalled();
  expect(
    screen.queryByRole("button", { name: "Confirmar troca" }),
  ).not.toBeInTheDocument();
  fireEvent.change(input, { target: { value: "12,34" } });
  fireEvent.click(screen.getByRole("button", { name: "Obter cotação" }));
  await waitFor(() =>
    expect(client.swapStart).toHaveBeenCalledExactlyOnceWith({
      send_asset_id: "usdt",
      receive_asset_id: "lbtc",
      amount_units: "1234000000",
    }),
  );
});
