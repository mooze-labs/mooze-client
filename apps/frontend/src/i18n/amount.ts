import type { AssetMetadataDto } from "../../../../crates/mooze-app/generated/types";
import type { Preferences } from "./preferences";
import { formatBaseUnits } from "../features/send/amount";
export function displayAssetAmount(
  units: string,
  metadata: AssetMetadataDto,
  preferences: Preferences,
  mode: "compact" | "exact" = "exact",
) {
  const sat =
    metadata.approved &&
    preferences.bitcoinUnit === "sat" &&
    ((metadata.key.chain === "Bitcoin" && metadata.key.asset_id === null) ||
      metadata.ticker === "L-BTC");
  const precision = sat ? 0 : metadata.precision;
  const exact =
    precision == null ? units : formatBaseUnits(BigInt(units), precision);
  const amount =
    mode === "compact" && precision != null && precision > 0
      ? exact.replace(/0+$/, "").replace(/,$/, "")
      : exact;
  return {
    amount: preferences.locale === "en" ? amount.replace(",", ".") : amount,
    ticker:
      precision == null
        ? "unidades brutas"
        : sat
          ? "sat"
          : (metadata.ticker ?? "unidades brutas"),
  };
}
