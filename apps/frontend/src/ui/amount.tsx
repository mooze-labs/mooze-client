import type { AssetMetadataDto } from "../../../../crates/mooze-app/generated/types";
import { displayAssetAmount } from "../i18n/amount";
import { usePreferences } from "../i18n/preferences";
import { useT } from "../i18n/messages";
import { SensitiveValue } from "./sensitive-value";

export function Amount({
  units,
  metadata,
  mode,
  className = "amount-value",
}: {
  units: string;
  metadata: AssetMetadataDto;
  mode: "compact" | "exact";
  className?: string;
}) {
  const { preferences } = usePreferences();
  const t = useT();
  const value = displayAssetAmount(units, metadata, preferences, mode);
  return (
    <SensitiveValue className={className}>
      {value.amount} <small>{t(value.ticker)}</small>
    </SensitiveValue>
  );
}
