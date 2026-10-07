import { afterEach, expect, it, vi } from "vitest";
import { cleanup, fireEvent, render, screen } from "@testing-library/react";
import { SwapReview } from "./swap-review";
afterEach(cleanup);
it("keeps the quote readable but prevents confirmation at its expiry", () => {
  const review = {
    id: "quote",
    generation: 1,
    send_asset_id: "lbtc",
    receive_asset_id: "depix",
    send_units: "1000000",
    receive_units: "25000000000",
    fees: [],
    expires_at_ms: 2000,
  };
  const asset = (id: string) => ({
    key: { chain: "Liquid" as const, asset_id: id },
    ticker: id === "lbtc" ? "L-BTC" : "DEPIX",
    approved: true,
    precision: 8,
  });
  const confirm = vi.fn();
  const { rerender } = render(
    <SwapReview
      review={review}
      asset={asset}
      now={1999}
      enabled
      confirm={confirm}
    />,
  );
  expect(screen.getByRole("button", { name: "Confirmar troca" })).toBeEnabled();
  rerender(
    <SwapReview
      review={review}
      asset={asset}
      now={2000}
      enabled
      confirm={confirm}
    />,
  );
  const button = screen.getByRole("button", { name: "Confirmar troca" });
  expect(button).toBeDisabled();
  fireEvent.click(button);
  expect(confirm).not.toHaveBeenCalled();
  expect(screen.getByText("Cotação expirada")).toBeInTheDocument();
  expect(screen.getByText("Você recebe")).toBeInTheDocument();
});
