import type {
  AssetKeyDto,
  AssetMetadataDto,
} from "../../../../../crates/mooze-app/generated/types";
import { usePreferences } from "../../i18n/preferences";
import { useT } from "../../i18n/messages";
import { displayAssetAmount } from "../../i18n/amount";
import { assetKey } from "../dashboard/holdings-model";
export function useSendAmount(assets: AssetMetadataDto[]) {
  const { preferences } = usePreferences();
  const t = useT();
  const format = (units: string, metadata: AssetMetadataDto) => {
    const value = displayAssetAmount(units, metadata, preferences, "exact");
    return `${value.amount} ${t(value.ticker)}`;
  };
  return {
    amount: (units: string, key: AssetKeyDto) =>
      format(
        units,
        assets.find((a) => assetKey(a.key) === assetKey(key)) ?? {
          key,
          ticker:
            key.chain === "Bitcoin" && key.asset_id === null ? "BTC" : null,
          precision:
            key.chain === "Bitcoin" && key.asset_id === null ? 8 : null,
          approved: key.chain === "Bitcoin" && key.asset_id === null,
        },
      ),
    // The host review's fee_sat is explicitly denominated in the chain's native fee asset.
    nativeFee: (units: string, chain: AssetKeyDto["chain"]) =>
      format(units, {
        key: { chain, asset_id: null },
        ticker: chain === "Bitcoin" ? "BTC" : "L-BTC",
        precision: 8,
        approved: true,
      }),
  };
}
