import { render, screen } from "@testing-library/react";
import { expect, it, vi } from "vitest";
import { SendReviewView } from "./send-review";
import type { Review } from "../../core/client";
it("keeps TEST and L-BTC debits separate and disables an expired review", () => {
  const review: Review = {
    id: "opaque",
    generation: 1,
    is_max: false,
    expires_at_ms: 100,
    fee_sat: 10,
    request: {
      asset: { chain: "Liquid", asset_id: "test" },
      destination: "tlq-full-destination",
      amount: { mode: "Exact", units: "1" },
      fee_rate_sat_per_vbyte: 0.1,
    },
    debits: [
      { asset: { chain: "Liquid", asset_id: "test" }, units: "1" },
      { asset: { chain: "Liquid", asset_id: "policy" }, units: "10" },
    ],
  };
  render(
    <SendReviewView
      assets={[
        {
          key: { chain: "Liquid", asset_id: "test" },
          ticker: "TEST",
          precision: 8,
          approved: true,
        },
        {
          key: { chain: "Liquid", asset_id: "policy" },
          ticker: "L-BTC",
          precision: 8,
          approved: true,
        },
      ]}
      review={review}
      busy={false}
      nowMs={100}
      expiresAtMs={100}
      onEdit={vi.fn()}
      onConfirm={vi.fn()}
      name={(a) => (a.asset_id === "test" ? "TEST" : "L-BTC")}
    />,
  );
  expect(screen.getByText("tlq-full-destination")).toBeInTheDocument();
  expect(screen.getAllByText("0,00000001 TEST")[0]).toBeInTheDocument();
  expect(screen.getAllByText("0,00000010 L-BTC")[0]).toBeInTheDocument();
  expect(
    screen.getByRole("button", { name: "Confirmar envio" }),
  ).toBeDisabled();
});
import { PreferencesContext } from "../../i18n/preferences";
it("uses English exact decimals for TEST and sat units for native fee assets", () => {
  const review: Review = {
    id: "opaque",
    generation: 1,
    is_max: false,
    expires_at_ms: 100,
    fee_sat: 10,
    request: {
      asset: { chain: "Liquid", asset_id: "test" },
      destination: "tlq",
      amount: { mode: "Exact", units: "1" },
      fee_rate_sat_per_vbyte: 0.1,
    },
    debits: [
      { asset: { chain: "Liquid", asset_id: "test" }, units: "1" },
      { asset: { chain: "Liquid", asset_id: "policy" }, units: "10" },
    ],
  };
  render(
    <PreferencesContext.Provider
      value={{
        preferences: { locale: "en", bitcoinUnit: "sat", privacy: false },
        save: async () => {},
      }}
    >
      <SendReviewView
        assets={[
          {
            key: { chain: "Liquid", asset_id: "test" },
            ticker: "TEST",
            precision: 8,
            approved: true,
          },
          {
            key: { chain: "Liquid", asset_id: "policy" },
            ticker: "L-BTC",
            precision: 8,
            approved: true,
          },
        ]}
        review={review}
        busy={false}
        nowMs={0}
        expiresAtMs={100}
        onEdit={vi.fn()}
        onConfirm={vi.fn()}
        name={(a) => (a.asset_id === "test" ? "TEST" : "L-BTC")}
      />
    </PreferencesContext.Provider>,
  );
  expect(screen.getAllByText("0.00000001 TEST")[0]).toBeInTheDocument();
  expect(screen.getAllByText("10 sat")[0]).toBeInTheDocument();
});
