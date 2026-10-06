import { render, screen, fireEvent } from "@testing-library/react";
import { MemoryRouter } from "react-router-dom";
import { expect, it, vi } from "vitest";
import { HistoryPage } from "./history-page";
import type { Snapshot } from "../../core/client";
vi.mock("../../app/session-provider", () => ({
  useWalletHoldings: () => ({ data: { holdings: [] } }),
}));
const data: Snapshot = {
  generation: 1,
  submission: null,
  sync: null,
  chains: [],
  activity: [
    {
      id: "tx",
      chain: "Bitcoin",
      timestamp_ms: null,
      status: "Pending",
      confirmations: 0,
      movements: [
        { asset: { chain: "Bitcoin", asset_id: null }, delta_units: "100000" },
      ],
      addresses: [],
      fee: null,
    },
  ],
};
it("shows active filters, clears them, and distinguishes no matches from an empty wallet", () => {
  render(
    <MemoryRouter>
      <HistoryPage data={data} />
    </MemoryRouter>,
  );
  fireEvent.click(screen.getByText("Filtros"));
  fireEvent.click(screen.getByRole("combobox", { name: "Rede" }));
  fireEvent.pointerDown(screen.getByRole("option", { name: "Liquid" }));
  fireEvent.click(screen.getByRole("option", { name: "Liquid" }));
  expect(screen.getByText("Filtros (1)")).toBeInTheDocument();
  expect(
    screen.getByText("Nenhuma transação corresponde aos filtros."),
  ).toBeInTheDocument();
  fireEvent.click(screen.getByRole("button", { name: "Limpar filtros" }));
  expect(
    screen.queryByText("Nenhuma transação corresponde aos filtros."),
  ).not.toBeInTheDocument();
  expect(screen.getByText(/Data indisponível/)).toBeInTheDocument();
});
it("keeps a direct transaction lookup visible until data arrives, then shows exact details", async () => {
  const view = render(
    <MemoryRouter initialEntries={["/history?chain=Bitcoin&tx=tx"]}>
      <HistoryPage />
    </MemoryRouter>,
  );
  expect(
    screen.getByText("Aguardando dados desta transação."),
  ).toBeInTheDocument();
  view.rerender(
    <MemoryRouter initialEntries={["/history?chain=Bitcoin&tx=tx"]}>
      <HistoryPage data={data} />
    </MemoryRouter>,
  );
  expect(
    await screen.findByRole("dialog", { name: "Detalhes da transação" }),
  ).toBeInTheDocument();
  expect(screen.getByText("0,00100000 BTC")).toBeInTheDocument();
  fireEvent.click(screen.getByRole("button", { name: "Fechar" }));
});
