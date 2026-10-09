import { afterEach, expect, it, vi } from "vitest";
import {
  act,
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
import { analytics } from "../../analytics/runtime";
import { MemoryRouter } from "react-router-dom";
vi.mock("../../app/session-provider", () => ({
  useWalletSession: () => ({ session: { generation: 1, status: "unlocked" } }),
}));
afterEach(() => {
  cleanup();
  vi.useRealTimers();
  vi.restoreAllMocks();
});
async function setup() {
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
  const view = render(
    <QueryClientProvider
      client={
        new QueryClient({ defaultOptions: { queries: { retry: false } } })
      }
    >
      <WalletClientProvider client={client}>
        <MemoryRouter>
          <SwapPage />
        </MemoryRouter>
      </WalletClientProvider>
    </QueryClientProvider>,
  );
  const input = await screen.findByLabelText("Quantidade a trocar");
  await waitFor(() =>
    expect(
      screen.getByRole("combobox", { name: "Ativo de origem" }),
    ).toHaveTextContent("L-BTC"),
  );
  return { client, input, ...view };
}
it.each(["Succeeded", "Failed", "Uncertain"])(
  "records swap review and the real %s outcome without financial data",
  async (phase) => {
    const capture = vi.spyOn(analytics, "track");
    const { client, input } = await setup();
    const review = {
      id: "private-quote",
      generation: 1,
      send_asset_id: "lbtc",
      receive_asset_id: "usdt",
      send_units: "1000000",
      receive_units: "2000000",
      fees: [],
      expires_at_ms: Date.now() + 60000,
    };
    vi.mocked(client.swapStart).mockResolvedValue({
      phase: "Review",
      review,
      txid: null,
      message: null,
    });
    vi.mocked(client.swapStatus).mockResolvedValue({
      phase: "Review",
      review,
      txid: null,
      message: null,
    });
    vi.mocked(client.swapConfirm).mockResolvedValue({
      phase,
      review: null,
      txid: phase === "Succeeded" ? "private-txid" : null,
      message: null,
    });
    fireEvent.change(input, { target: { value: "0,01" } });
    const reviewButton = await screen.findByRole("button", {
      name: "Revisar troca",
    });
    fireEvent.click(reviewButton);
    fireEvent.click(
      await screen.findByRole("button", { name: "Confirmar troca" }),
    );
    await waitFor(() =>
      expect(capture.mock.calls.map(([e]) => e.name)).toEqual([
        "swap_review_opened",
        "swap_started",
        phase === "Succeeded" ? "swap_submission_succeeded" : "swap_failed",
      ]),
    );
    expect(capture.mock.calls.map(([e]) => e.properties)).toEqual([
      { swap_type: "liquid" },
      { swap_type: "liquid" },
      { swap_type: "liquid" },
    ]);
  },
);
it("reverses the assets and discards the previous amount and quote", async () => {
  const { client, input } = await setup();
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

async function advance(ms: number) {
  await act(async () => {
    await vi.advanceTimersByTimeAsync(ms);
  });
}
it("fetches only the latest amount after typing pauses for 800 ms", async () => {
  const { client, input } = await setup();
  vi.useFakeTimers();
  fireEvent.change(input, { target: { value: "0,01" } });
  await advance(600);
  fireEvent.change(input, { target: { value: "0,02" } });
  await advance(799);
  expect(client.swapStart).not.toHaveBeenCalled();
  await advance(1);
  expect(client.swapStart).toHaveBeenCalledExactlyOnceWith({
    send_asset_id: "lbtc",
    receive_asset_id: "usdt",
    amount_units: "2000000",
  });
  await advance(2000);
  expect(client.swapStart).toHaveBeenCalledTimes(1);
});
it.each(["", "0", "invalid"])(
  "cancels the pending quote for %j",
  async (value) => {
    const { client, input, unmount } = await setup();
    vi.useFakeTimers();
    fireEvent.change(input, { target: { value: "1" } });
    await advance(400);
    fireEvent.change(input, { target: { value } });
    await advance(800);
    expect(client.swapStart).not.toHaveBeenCalled();
    fireEvent.change(input, { target: { value: "2" } });
    unmount();
    await advance(800);
    expect(client.swapStart).not.toHaveBeenCalled();
  },
);
it("keeps typing enabled and discards a superseded quote response", async () => {
  const { client, input } = await setup();
  vi.useFakeTimers();
  let resolve!: (value: Awaited<ReturnType<typeof client.swapStart>>) => void;
  vi.mocked(client.swapStart).mockImplementationOnce(
    () =>
      new Promise((r) => {
        resolve = r;
      }),
  );
  fireEvent.change(input, { target: { value: "1" } });
  await advance(800);
  expect(client.swapStart).toHaveBeenCalledTimes(1);
  expect(input).toBeEnabled();
  fireEvent.change(input, { target: { value: "2" } });
  await advance(800);
  await act(async () =>
    resolve({
      phase: "Review",
      txid: null,
      message: null,
      review: {
        id: "old",
        generation: 1,
        send_asset_id: "lbtc",
        receive_asset_id: "usdt",
        send_units: "100000000",
        receive_units: "123000000",
        fees: [],
        expires_at_ms: Date.now() + 30000,
      },
    }),
  );
  await advance(0);
  expect(
    screen.queryByRole("button", { name: "Confirmar troca" }),
  ).not.toBeInTheDocument();
  expect(client.swapStart).toHaveBeenLastCalledWith({
    send_asset_id: "lbtc",
    receive_asset_id: "usdt",
    amount_units: "200000000",
  });
});

it("shows the automatic quote and cancels a duplicate debounced fetch after manual refresh", async () => {
  const { client, input } = await setup();
  vi.useFakeTimers();
  const quote = {
    phase: "Review",
    txid: null,
    message: null,
    review: {
      id: "current",
      generation: 1,
      send_asset_id: "lbtc",
      receive_asset_id: "usdt",
      send_units: "100000000",
      receive_units: "123000000",
      fees: [],
      expires_at_ms: Date.now() + 30000,
    },
  };
  vi.mocked(client.swapStart).mockResolvedValue(quote);
  vi.mocked(client.swapStatus).mockResolvedValue(quote);
  fireEvent.change(input, { target: { value: "1" } });
  await advance(800);
  expect(screen.getByLabelText("Quantidade a receber")).toHaveTextContent(
    "1,23000000",
  );
  expect(
    screen.queryByRole("button", { name: "Confirmar troca" }),
  ).not.toBeInTheDocument();
  fireEvent.click(screen.getByRole("button", { name: "Revisar troca" }));
  expect(screen.getByRole("button", { name: "Confirmar troca" })).toBeEnabled();
  expect(screen.getByRole("heading", { name: "Revisar troca" })).toHaveFocus();
  expect(
    screen.queryByLabelText("Quantidade a trocar"),
  ).not.toBeInTheDocument();
  fireEvent.click(screen.getByRole("button", { name: "Editar troca" }));
  fireEvent.change(screen.getByLabelText("Quantidade a trocar"), {
    target: { value: "2" },
  });
  expect(
    screen.queryByRole("button", { name: "Confirmar troca" }),
  ).not.toBeInTheDocument();
  fireEvent.click(screen.getByRole("button", { name: "Obter cotação" }));
  await advance(0);
  expect(client.swapStart).toHaveBeenCalledTimes(2);
  await advance(800);
  expect(client.swapStart).toHaveBeenCalledTimes(2);
});
