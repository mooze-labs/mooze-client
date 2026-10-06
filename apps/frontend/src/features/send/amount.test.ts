import { describe, it, expect } from "vitest";
import { parseNativeAmount, formatBaseUnits } from "./amount";
describe("native amounts", () => {
  it("parses decimal comma exactly down to a satoshi", () => {
    expect(parseNativeAmount("0,00000001")).toEqual({ ok: true, value: 1n });
    expect(parseNativeAmount("1,25")).toEqual({ ok: true, value: 125000000n });
    expect(formatBaseUnits(125000001n, 8)).toBe("1,25000001");
  });
  it.each([
    "0",
    "-1",
    "1e8",
    "1.000,00",
    "0,000000001",
    "90071992,54740992",
    "NaN",
    "",
  ])("rejects invalid or unsafe amount %s", (value) =>
    expect(parseNativeAmount(value).ok).toBe(false),
  );
});
