import { expect, it } from "vitest";
import { quoteRate } from "./quote-rate";
it("derives an indicative rate using exact integers including tiny and large quotes", () => {
  expect(quoteRate("1000000", "25000000000")).toBe("25000");
  expect(quoteRate("300000000", "100000000")).toBe("0.33333333");
  expect(quoteRate("10000000000000000", "1")).toBe("<0.00000001");
  expect(quoteRate("0", "100")).toBeNull();
});
