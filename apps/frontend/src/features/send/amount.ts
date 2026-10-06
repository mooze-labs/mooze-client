export type Result<T, E> = { ok: true; value: T } | { ok: false; error: E };
export type AmountError =
  "invalid_format" | "nonpositive" | "precision" | "overflow";
export function parseNativeAmount(text: string): Result<bigint, AmountError> {
  const value = text.trim();
  if (!/^\d+(,\d+)?$/.test(value))
    return { ok: false, error: "invalid_format" };
  const [whole, fraction = ""] = value.split(",");
  if (fraction.length > 8) return { ok: false, error: "precision" };
  const sats = BigInt(whole) * 100000000n + BigInt(fraction.padEnd(8, "0"));
  if (sats <= 0n) return { ok: false, error: "nonpositive" };
  if (sats > BigInt(Number.MAX_SAFE_INTEGER))
    return { ok: false, error: "overflow" };
  return { ok: true, value: sats };
}
export function formatBaseUnits(value: bigint, precision = 8): string {
  const sign = value < 0n ? "-" : "";
  const raw = (value < 0n ? -value : value)
    .toString()
    .padStart(precision + 1, "0");
  return (
    sign +
    (precision ? raw.slice(0, -precision) + "," + raw.slice(-precision) : raw)
  );
}

/** Exact supported-asset input; comma or dot decimal, never grouping. */
export function parseAssetAmount(text: string): Result<bigint, AmountError> {
  const value = text.trim();
  if (!/^\d+(?:[.,]\d+)?$/.test(value))
    return { ok: false, error: "invalid_format" };
  const [whole, fraction = ""] = value.replace(",", ".").split(".");
  if (fraction.length > 8) return { ok: false, error: "precision" };
  const units = BigInt(whole) * 100_000_000n + BigInt(fraction.padEnd(8, "0"));
  if (units <= 0n) return { ok: false, error: "nonpositive" };
  if (units > 18446744073709551615n) return { ok: false, error: "overflow" };
  return { ok: true, value: units };
}
