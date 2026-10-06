import { afterEach, expect, it, vi } from "vitest";
import { cleanup, fireEvent, render, screen } from "@testing-library/react";
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
