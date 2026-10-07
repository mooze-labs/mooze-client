import { expect, it } from "vitest";
import { formatTaxId, taxIdDigits, formatBrlInput } from "./pix-input";
import { parseBrlCents } from "./pix-state";
it("formats pasted CPF/CNPJ without changing their digits", () => {
  expect(formatTaxId("52998224725")).toBe("529.982.247-25");
  expect(formatTaxId("11222333000181")).toBe("11.222.333/0001-81");
  expect(taxIdDigits(formatTaxId("11222333000181"))).toBe("11222333000181");
});
it("preserves decimal drafts and parses grouped BRL exactly", () => {
  expect(formatBrlInput("1234,")).toBe("1.234,");
  expect(formatBrlInput("1234,50")).toBe("1.234,50");
  expect(parseBrlCents("1.234,50")).toBe("123450");
  expect(parseBrlCents("12.34")).toBe("1234");
  expect(parseBrlCents("1.23,45")).toBeNull();
  expect(formatBrlInput("12,345")).toBe("12,345");
  expect(parseBrlCents(formatBrlInput("12,345"))).toBeNull();
});
