import { act, cleanup, render, screen, waitFor } from "@testing-library/react";
import { afterEach, expect, it, vi } from "vitest";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { WalletClientProvider } from "../../app/client-context";
import { NetworkContext } from "../../core/network";
import { PrivacyContext } from "../../ui/sensitive-value";
import { fakeClient } from "../../testing/client";
import { FiatSummary, HoldingFiatValue } from "./fiat-value";
import { useHoldingFiat } from "./use-holding-fiat";
import { selectHoldings } from "../dashboard/holdings-model";
vi.mock("../../app/session-provider", () => ({
  useWalletSession: () => ({ session: { generation: 1, status: "unlocked" } }),
}));
afterEach(() => {
  cleanup();
  vi.useRealTimers();
});
const assets = [
  {
    chain: "Bitcoin" as const,
    asset_id: null,
    ticker: "BTC",
    units: "100000000",
  },
  {
    chain: "Liquid" as const,
    asset_id:
      "6f0279e9ed041c3d710a9f57d0c02928416460c4b722ae3457a11eec381c526d",
    ticker: "L-BTC",
    units: "100000000",
  },
  {
    chain: "Liquid" as const,
    asset_id:
      "02f22f8d9c76ab41661a2729e4752e2c5d1a263012141b86ea98af5472df5189",
    ticker: "DEPIX",
    units: "25000000000",
  },
];
const rows = selectHoldings(
  assets.map((a) => ({
    metadata: {
      key: { chain: a.chain, asset_id: a.asset_id },
      ticker: a.ticker,
      precision: 8,
      approved: true,
    },
    balance_units: a.units,
    available_units: null,
    pending_units: "0",
  })),
  ["Bitcoin", "Liquid"].map((chain) => ({
    chain: chain as "Bitcoin" | "Liquid",
    phase: "ready",
    last_success_at_ms: Date.now(),
    error: null,
  })),
  [],
);
function Content() {
  const fiat = useHoldingFiat(rows);
  return (
    <>
      <FiatSummary fiat={fiat} />
      {Object.entries(fiat.values).map(([key, value]) => (
        <HoldingFiatValue key={key} value={value} />
      ))}
    </>
  );
}
function mount(client = fakeClient(), hidden = false) {
  return render(
    <QueryClientProvider
      client={
        new QueryClient({ defaultOptions: { queries: { retry: false } } })
      }
    >
      <WalletClientProvider client={client}>
        <NetworkContext.Provider value="Mainnet">
          <PrivacyContext.Provider value={hidden}>
            <Content />
          </PrivacyContext.Provider>
        </NetworkContext.Provider>
      </WalletClientProvider>
    </QueryClientProvider>,
  );
}
it("shares the Bitcoin quote across BTC and L-BTC and totals BRL with fixed DePix", async () => {
  const client = fakeClient();
  vi.mocked(client.priceHistory).mockResolvedValue({
    points: [{ price: 500000, timestamp_ms: Date.now() }],
    fetched_at_ms: Date.now(),
    source: "Provider",
  });
  mount(client);
  expect(await screen.findByText(/1\.000\.250,00/)).toBeInTheDocument();
  expect(client.priceHistory).toHaveBeenCalledTimes(1);
  expect(client.priceHistory).toHaveBeenCalledWith("Bitcoin", "brl", 1);
});
it("keeps the fixed DePix subtotal and labels partial results when prices fail", async () => {
  const client = fakeClient();
  vi.mocked(client.priceHistory).mockRejectedValue(new Error("offline"));
  mount(client);
  expect(
    await screen.findByText("Não foi possível atualizar as cotações."),
  ).toBeInTheDocument();
  expect(screen.getByText("Saldo parcial estimado em BRL")).toBeInTheDocument();
  expect(screen.getAllByText(/250,00/)).toHaveLength(2);
  expect(screen.getAllByText("Valor em BRL indisponível")).toHaveLength(2);
});
it("removes fiat amounts from accessible content in privacy mode", async () => {
  const client = fakeClient();
  vi.mocked(client.priceHistory).mockResolvedValue({
    points: [{ price: 500000, timestamp_ms: Date.now() }],
    fetched_at_ms: Date.now(),
    source: "Provider",
  });
  const view = mount(client, true);
  await waitFor(() =>
    expect(screen.getAllByLabelText("Valor oculto")).toHaveLength(4),
  );
  expect(view.container.textContent).not.toContain("250,00");
  expect(view.container.textContent).not.toContain("500.000");
});

it("expires a quote while the screen remains open", async () => {
  vi.useFakeTimers();
  vi.setSystemTime(new Date("2026-10-07T12:00:00Z"));
  const client = fakeClient();
  vi.mocked(client.priceHistory).mockResolvedValue({
    points: [{ price: 500000, timestamp_ms: Date.now() - 3_599_000 }],
    fetched_at_ms: Date.now(),
    source: "Provider",
  });
  mount(client);
  await act(async () => {
    await vi.advanceTimersByTimeAsync(10);
  });
  expect(screen.getByText(/1\.000\.250,00/)).toBeInTheDocument();
  await act(async () => {
    await vi.advanceTimersByTimeAsync(1100);
  });
  expect(screen.queryByText(/1\.000\.250,00/)).not.toBeInTheDocument();
  expect(screen.getByText("Saldo parcial estimado em BRL")).toBeInTheDocument();
});
