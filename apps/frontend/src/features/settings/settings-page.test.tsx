import { fireEvent, render, screen, waitFor } from "@testing-library/react";
import { expect, it, vi } from "vitest";
import { createMemoryRouter, RouterProvider } from "react-router-dom";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { WalletClientProvider } from "../../app/client-context";
import { fakeClient } from "../../testing/client";
import { SettingsPage } from "./settings-page";
vi.mock("../../app/session-provider", () => ({
  useWalletSession: () => ({ session: { generation: 1, status: "unlocked" } }),
}));
it("preserves drafts on chain changes and blocks section and history exits until discarded", async () => {
  const client = fakeClient();
  vi.mocked(client.settings).mockResolvedValue({
    version: 1,
    lock_minutes: 5,
    locale: "en",
    bitcoin_unit: "BTC",
    privacy: false,
    bitcoin_node: null,
    liquid_node: null,
    public_fallback: false,
  });
  const router = createMemoryRouter(
    [
      { path: "/settings", element: <SettingsPage /> },
      { path: "/", element: <p>Wallet home</p> },
    ],
    { initialEntries: ["/", "/settings?section=network"], initialIndex: 1 },
  );
  render(
    <QueryClientProvider
      client={
        new QueryClient({ defaultOptions: { queries: { retry: false } } })
      }
    >
      <WalletClientProvider client={client}>
        <RouterProvider router={router} />
      </WalletClientProvider>
    </QueryClientProvider>,
  );
  const endpoint = await screen.findByLabelText("Nó Electrum personalizado");
  await waitFor(() => expect(endpoint).toBeEnabled());
  fireEvent.change(endpoint, { target: { value: "ssl://btc.example:50002" } });
  fireEvent.click(screen.getByRole("combobox", { name: "Rede" }));
  fireEvent.pointerDown(screen.getByRole("option", { name: "Liquid" }));
  fireEvent.click(screen.getByRole("option", { name: "Liquid" }));
  fireEvent.change(endpoint, {
    target: { value: "ssl://liquid.example:50002" },
  });
  fireEvent.click(screen.getByRole("combobox", { name: "Rede" }));
  fireEvent.pointerDown(screen.getByRole("option", { name: "Bitcoin" }));
  fireEvent.click(screen.getByRole("option", { name: "Bitcoin" }));
  expect(endpoint).toHaveValue("ssl://btc.example:50002");
  fireEvent.click(screen.getByRole("link", { name: "Geral" }));
  await screen.findByRole("dialog", { name: "Descartar alterações?" });
  fireEvent.click(screen.getByRole("button", { name: "Continuar editando" }));
  expect(endpoint).toHaveValue("ssl://btc.example:50002");
  void router.navigate(-1);
  await screen.findByRole("dialog", { name: "Descartar alterações?" });
  fireEvent.click(screen.getByRole("button", { name: "Descartar alterações" }));
  await screen.findByText("Wallet home");
  expect(client.saveNode).not.toHaveBeenCalled();
});
