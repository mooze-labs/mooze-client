import { render, screen, cleanup } from "@testing-library/react";
import { afterEach, expect, it, vi } from "vitest";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { WalletClientProvider } from "../../app/client-context";
import { PrivacyContext } from "../../ui/sensitive-value";
import { fakeClient } from "../../testing/client";
import { AccountPage } from "./account-page";
vi.mock("../../app/session-provider", () => ({
  useWalletSession: () => ({ session: { generation: 1, status: "unlocked" } }),
}));
afterEach(cleanup);
const data = {
  user_id: "8f14e45f-ceea-467f-a0e6-8b4f0e3c1a2b",
  current_level: "silver",
  next_level: "gold",
  progress: 0.4,
  per_transaction_brl: 400,
  minimum_brl: 20,
  daily_limit_brl: 5000,
  spent_today_brl: 125,
  remaining_today_brl: 4875,
  tiers: [],
};
function setup(client = fakeClient(), privacy = false) {
  render(
    <QueryClientProvider
      client={
        new QueryClient({ defaultOptions: { queries: { retry: false } } })
      }
    >
      <WalletClientProvider client={client}>
        <PrivacyContext.Provider value={privacy}>
          <AccountPage />
        </PrivacyContext.Provider>
      </WalletClientProvider>
    </QueryClientProvider>,
  );
}
it("shows the backend level and progress without the Pix limits card", async () => {
  const client = fakeClient();
  vi.mocked(client.accountLevel).mockResolvedValue(data);
  setup(client);
  expect(await screen.findByText("Prata")).toBeVisible();
  expect(screen.getByText("ID da conta")).toBeVisible();
  expect(screen.getByText(data.user_id)).toBeVisible();
  expect(screen.queryByText("Limites Pix")).not.toBeInTheDocument();
  expect(screen.getByRole("progressbar")).toHaveAttribute("value", "0.4");
});
it("handles the highest tier without showing personal limits", async () => {
  const client = fakeClient();
  vi.mocked(client.accountLevel).mockResolvedValue({
    ...data,
    current_level: "diamond",
    next_level: null,
  });
  setup(client, true);
  expect(await screen.findByText("Diamante")).toBeVisible();
  expect(screen.queryByRole("progressbar")).not.toBeInTheDocument();
  expect(screen.queryByText(/400,00/)).not.toBeInTheDocument();
  expect(screen.queryByText("Utilizado hoje")).not.toBeInTheDocument();
});
it("does not invent a default level when the service fails", async () => {
  const client = fakeClient();
  vi.mocked(client.accountLevel).mockRejectedValue(new Error("offline"));
  setup(client);
  expect(
    await screen.findByText(
      "Não foi possível carregar seu nível. Tente novamente.",
    ),
  ).toBeVisible();
  expect(screen.queryByText("Bronze")).not.toBeInTheDocument();
  expect(screen.queryByText("ID da conta")).not.toBeInTheDocument();
});
