import { expect, it } from "vitest";
import { isWalletActivity } from "./activity";
it("accepts focused trusted interaction and ignores background synthetic or sync events", () => {
  expect(isWalletActivity({ type: "keydown", isTrusted: true }, true)).toBe(
    true,
  );
  expect(isWalletActivity({ type: "pointermove", isTrusted: true }, true)).toBe(
    true,
  );
  expect(
    isWalletActivity({ type: "pointerdown", isTrusted: true }, false),
  ).toBe(false);
  expect(isWalletActivity({ type: "keydown", isTrusted: false }, true)).toBe(
    false,
  );
  expect(isWalletActivity({ type: "sync", isTrusted: true }, true)).toBe(false);
});
