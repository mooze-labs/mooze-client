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
import { PixPage } from "./pix-page";
import { analytics } from "../../analytics/runtime";
vi.mock("../../app/session-provider", () => ({
  useWalletSession: () => ({ session: { generation: 1, status: "unlocked" } }),
}));
afterEach(() => {
  cleanup();
  vi.restoreAllMocks();
});
it("creates exactly one BRL request and shows its payment code without claiming settlement", async () => {
  const events = vi.spyOn(analytics, "track");
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
  vi.mocked(client.approvedAssets).mockResolvedValue([
    {
      key: { chain: "Liquid", asset_id: "depix" },
      ticker: "DEPIX",
      precision: 8,
      approved: true,
    },
    {
      key: { chain: "Liquid", asset_id: "usdt" },
      ticker: "USDT",
      precision: 8,
      approved: true,
    },
  ]);
  vi.mocked(client.pixCreate).mockResolvedValue({
    deposit_id: "d1",
    pix_key: "000201payment",
    asset_id: "depix",
    amount_in_cents: "1234",
    status: "Pending",
    created_at_ms: 0,
    expires_at_ms: null,
    blockchain_txid: null,
    asset_amount: null,
  });
  render(
    <QueryClientProvider
      client={
        new QueryClient({ defaultOptions: { queries: { retry: false } } })
      }
    >
      <WalletClientProvider client={client}>
        <PixPage />
      </WalletClientProvider>
    </QueryClientProvider>,
  );
  const assetSelector = await screen.findByRole("combobox", {
    name: "Ativo a receber",
  });
  fireEvent.click(assetSelector);
  await screen.findByRole("option", { name: "DEPIX" });
  expect(
    screen.queryByRole("option", { name: "USDT" }),
  ).not.toBeInTheDocument();
  expect(screen.queryByText("USDT")).not.toBeInTheDocument();
  fireEvent.keyDown(assetSelector, { key: "Escape" });
  fireEvent.change(await screen.findByLabelText("Valor em reais"), {
    target: { value: "12,34" },
  });
  expect(screen.getByRole("button", { name: "Criar Pix" })).toBeDisabled();
  fireEvent.change(screen.getByLabelText("CPF ou CNPJ do pagador"), {
    target: { value: "52998224725" },
  });
  await waitFor(() =>
    expect(
      screen.getByRole("button", { name: "Criar Pix" }),
    ).not.toBeDisabled(),
  );
  fireEvent.click(screen.getByRole("button", { name: "Criar Pix" }));
  await screen.findByText("000201payment");
  expect(events.mock.calls.map(([event]) => event)).toEqual([
    { name: "pix_request_started", properties: {} },
    { name: "pix_request_created", properties: {} },
  ]);
  expect(client.pixCreate).toHaveBeenCalledExactlyOnceWith({
    amount_in_cents: "1234",
    asset_id: "depix",
    tax_id_number: "52998224725",
  });
  expect(screen.queryByText("Ativos recebidos")).not.toBeInTheDocument();
  expect(screen.queryByLabelText("Valor em reais")).not.toBeInTheDocument();
  fireEvent.click(screen.getByRole("button", { name: "Nova solicitação" }));
  expect(screen.getByRole("heading", { name: "Novo Pix" })).toHaveFocus();
  expect(screen.getByLabelText("Valor em reais")).toHaveValue("");
  expect(screen.getByLabelText("CPF ou CNPJ do pagador")).toHaveValue("");
  expect(client.pixCreate).toHaveBeenCalledTimes(1);
});
