import { render, screen } from "@testing-library/react";
import { MemoryRouter } from "react-router-dom";
import { expect, it } from "vitest";
import { HoldingsTable } from "../assets/assets-page";
import { selectHoldings } from "./holdings-model";
import { PrivacyContext } from "../../ui/sensitive-value";

const rows = selectHoldings(
  [
    {
      metadata: {
        key: { chain: "Bitcoin", asset_id: null },
        ticker: "BTC",
        precision: 8,
        approved: true,
      },
      balance_units: "2485000",
      pending_units: "1",
      available_units: null,
    },
    {
      metadata: {
        key: { chain: "Liquid", asset_id: "ab".repeat(32) },
        ticker: null,
        precision: null,
        approved: false,
      },
      balance_units: "1",
      pending_units: null,
      available_units: null,
    },
  ],
  [
    { chain: "Bitcoin", phase: "error", last_success_at_ms: 1, error: null },
    { chain: "Liquid", phase: "ready", last_success_at_ms: 1, error: null },
  ],
  [],
);
it("shows compact balances with stale status and preserves unknown asset navigation", () => {
  render(
    <MemoryRouter>
      <HoldingsTable rows={rows} />
    </MemoryRouter>,
  );
  expect(
    screen.getByText(
      (_, el) =>
        el?.className === "amount-value" && el.textContent === "0,02485 BTC",
    ),
  ).toBeInTheDocument();
  expect(screen.getByText("· saldo anterior")).toBeInTheDocument();
  expect(
    screen.getByRole("link", { name: /Ativo não listado/ }),
  ).toHaveAttribute("href", `/assets/Liquid/${"ab".repeat(32)}`);
});
it("hides pending and balance values from accessible content", () => {
  const { container } = render(
    <MemoryRouter>
      <PrivacyContext.Provider value={true}>
        <HoldingsTable rows={rows} />
      </PrivacyContext.Provider>
    </MemoryRouter>,
  );
  expect(container.innerHTML).not.toContain("0,02485");
  expect(container.innerHTML).not.toContain("0,00000001");
  expect(screen.getAllByLabelText("Valor oculto").length).toBeGreaterThan(1);
});
