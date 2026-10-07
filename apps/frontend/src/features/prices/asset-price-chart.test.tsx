import {
  fireEvent,
  render,
  screen,
  waitFor,
  cleanup,
} from "@testing-library/react";
import { afterEach, expect, it, vi } from "vitest";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { WalletClientProvider } from "../../app/client-context";
import { NetworkContext } from "../../core/network";
import { fakeClient } from "../../testing/client";
import { AssetPriceChart } from "./asset-price-chart";
vi.mock("../../app/session-provider", () => ({
  useWalletSession: () => ({ session: { generation: 1, status: "unlocked" } }),
}));
afterEach(cleanup);
const asset = {
  key: { chain: "Bitcoin" as const, asset_id: null },
  ticker: "BTC",
  precision: 8,
  approved: true,
};
function setup(client = fakeClient()) {
  render(
    <QueryClientProvider
      client={
        new QueryClient({ defaultOptions: { queries: { retry: false } } })
      }
    >
      <WalletClientProvider client={client}>
        <NetworkContext.Provider value="Mainnet">
          <AssetPriceChart asset={asset} />
        </NetworkContext.Provider>
      </WalletClientProvider>
    </QueryClientProvider>,
  );
  return client;
}
it("requests the selected market, period and currency and exposes keyboard price exploration", async () => {
  const client = fakeClient();
  vi.mocked(client.priceHistory).mockResolvedValue({
    points: [
      { timestamp_ms: 1000, price: 100 },
      { timestamp_ms: 2000, price: 110 },
    ],
    source: "CoinGecko",
    fetched_at_ms: 2000,
  });
  setup(client);
  expect(await screen.findByRole("slider")).toBeVisible();
  expect(client.priceHistory).toHaveBeenCalledWith("Bitcoin", "brl", 7);
  fireEvent.change(screen.getByRole("slider"), { target: { value: "0" } });
  expect(screen.getByRole("slider")).toHaveAttribute(
    "aria-valuetext",
    expect.stringContaining("100,00"),
  );
  fireEvent.click(screen.getByRole("button", { name: "1M" }));
  await waitFor(() =>
    expect(client.priceHistory).toHaveBeenCalledWith("Bitcoin", "brl", 30),
  );
  fireEvent.click(screen.getByRole("button", { name: "USD" }));
  await waitFor(() =>
    expect(client.priceHistory).toHaveBeenCalledWith("Bitcoin", "usd", 30),
  );
});
it("shows provider failures without inventing a chart", async () => {
  const client = fakeClient();
  vi.mocked(client.priceHistory).mockRejectedValue(new Error("rate limited"));
  setup(client);
  expect(
    await screen.findByText(
      "Preços indisponíveis. O serviço pode estar temporariamente limitado.",
    ),
  ).toBeVisible();
  expect(screen.queryByRole("img")).not.toBeInTheDocument();
  expect(client.priceHistory).toHaveBeenCalledTimes(1);
});
