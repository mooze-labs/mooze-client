import { describe, it, expect } from "vitest";
import { parseBrlCents, depositStage } from "./pix-state";
describe("Pix amounts and settlement", () => {
  it("converts cents exactly and rejects fractions of a cent", () => {
    expect(parseBrlCents("12,34")).toBe("1234");
    expect(parseBrlCents("12.34")).toBe("1234");
    for (const value of [
      "0",
      "-1",
      "1,001",
      "1.00,00",
      "1e3",
      "9007199254740993",
    ])
      expect(parseBrlCents(value)).toBeNull();
  });
  it("does not report payment receipt as asset settlement", () => {
    expect(depositStage("Pending")).toBe("payment");
    expect(depositStage("Paid")).toBe("processing");
    expect(depositStage("Completed")).toBe("settled");
    expect(depositStage("ProcessingRefund")).toBe("refund");
    expect(depositStage("Refunded")).toBe("refunded");
    expect(depositStage("FinishedRefund")).toBe("refunded");
    expect(depositStage("Unknown")).toBe("unknown");
  });
});
