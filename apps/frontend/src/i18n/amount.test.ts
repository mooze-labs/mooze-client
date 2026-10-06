import { it, expect } from "vitest";
import { displayAssetAmount } from "./amount";
it("keeps TEST precision fixed while Bitcoin display uses sat, without rounding large amounts", () => {
  const preferences = {
    locale: "en",
    bitcoinUnit: "sat",
    privacy: false,
  } as const;
  const asset = {
    key: { chain: "Liquid", asset_id: "test" },
    ticker: "TEST",
    precision: 8,
    approved: true,
  } as const;
  expect(displayAssetAmount("1", asset, preferences)).toEqual({
    amount: "0.00000001",
    ticker: "TEST",
  });
  expect(
    displayAssetAmount(
      "9007199254740993",
      { ...asset, ticker: "L-BTC" },
      preferences,
    ),
  ).toEqual({ amount: "9007199254740993", ticker: "sat" });
});

it("trims only trailing fractional zeros without rounding", () => {
  const p = { locale: "en", bitcoinUnit: "BTC", privacy: false } as const;
  const a = {
    key: { chain: "Liquid", asset_id: "test" },
    ticker: "TEST",
    precision: 8,
    approved: true,
  } as const;
  for (const [units, expected] of [
    ["2485000", "0.02485"],
    ["12500000000", "125"],
    ["1", "0.00000001"],
    ["0", "0"],
    ["-2485000", "-0.02485"],
    ["100010000", "1.0001"],
    ["18446744073709551615", "184467440737.09551615"],
  ]) {
    expect(displayAssetAmount(units, a, p, "compact").amount).toBe(expected);
  }
  expect(
    displayAssetAmount("2485000", a, { ...p, locale: "pt-BR" }, "exact").amount,
  ).toBe("0,02485000");
  expect(
    displayAssetAmount("12500000000", a, { ...p, locale: "es" }, "compact")
      .amount,
  ).toBe("125");
  expect(displayAssetAmount("0", a, p, "exact").amount).toBe("0.00000000");
  expect(
    displayAssetAmount(
      "9007199254740993",
      { ...a, precision: null, approved: false },
      p,
      "compact",
    ).amount,
  ).toBe("9007199254740993");
});

it("does not apply sat preference to an unapproved ticker impersonation", () => {
  const p = { locale: "en", bitcoinUnit: "sat", privacy: false } as const;
  const a = {
    key: { chain: "Liquid", asset_id: "unknown" },
    ticker: "BTC",
    precision: null,
    approved: false,
  } as const;
  expect(displayAssetAmount("100", a, p, "compact")).toEqual({
    amount: "100",
    ticker: "unidades brutas",
  });
});
