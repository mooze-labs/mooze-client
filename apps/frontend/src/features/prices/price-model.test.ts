import { expect, it } from "vitest";
import { chartGeometry, priceMarket } from "./price-model";
it("maps only approved canonical assets and never values test coins or spoofed tickers", () => {
  const btc = {
    key: { chain: "Bitcoin" as const, asset_id: null },
    ticker: "BTC",
    precision: 8,
    approved: true,
  };
  expect(priceMarket(btc, "Mainnet")).toBe("Bitcoin");
  expect(priceMarket(btc, "Testnet")).toBeNull();
  expect(priceMarket({ ...btc, approved: false }, "Mainnet")).toBeNull();
  expect(
    priceMarket(
      { ...btc, key: { chain: "Liquid", asset_id: "unknown" } },
      "Mainnet",
    ),
  ).toBeNull();
  expect(
    priceMarket(
      {
        ...btc,
        key: {
          chain: "Liquid",
          asset_id:
            "6f0279e9ed041c3d710a9f57d0c02928416460c4b722ae3457a11eec381c526d",
        },
      },
      "Mainnet",
    ),
  ).toBe("Bitcoin");
});
it("uses actual timestamp spacing and handles flat prices without NaN", () => {
  const chart = chartGeometry([
    { timestamp_ms: 1000, price: 1 },
    { timestamp_ms: 2000, price: 1 },
    { timestamp_ms: 5000, price: 1 },
  ]);
  expect(chart.change).toBe(0);
  expect(chart.coordinates[1].x).toBe(186);
  expect(chart.path).not.toMatch(/NaN|Infinity/);
  chart.coordinates.forEach((point) => expect(point.y).toBeCloseTo(100));
});
