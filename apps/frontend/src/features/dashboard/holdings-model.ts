import type {
  AssetKeyDto,
  HoldingDto,
} from "../../../../../crates/mooze-app/generated/types";
import type { ChainStateDto } from "../../core/desktop.generated";
import { formatBaseUnits } from "../send/amount";
export const assetKey = (asset: AssetKeyDto) =>
  `${asset.chain}:${asset.asset_id ?? "native"}`;
export const assetPath = (asset: AssetKeyDto) =>
  `/assets/${asset.chain}/${asset.asset_id ?? "native"}`;
export type HoldingView = HoldingDto & {
  key: string;
  balanceText: string | null;
  stale: boolean;
};
export function selectHoldings(
  holdings: HoldingDto[],
  chains: ChainStateDto[],
  activityAssetKeys: string[],
): HoldingView[] {
  return holdings
    .filter(
      (h) =>
        h.metadata.ticker === "BTC" ||
        h.metadata.ticker === "L-BTC" ||
        BigInt(h.balance_units) !== 0n ||
        activityAssetKeys.includes(assetKey(h.metadata.key)),
    )
    .map((h) => {
      const chain = chains.find((c) => c.chain === h.metadata.key.chain);
      return {
        ...h,
        key: assetKey(h.metadata.key),
        balanceText:
          chain?.last_success_at_ms == null
            ? null
            : h.metadata.precision === null
              ? h.balance_units
              : formatBaseUnits(BigInt(h.balance_units), h.metadata.precision),
        stale: chain?.last_success_at_ms != null && chain.phase !== "ready",
      };
    })
    .sort((a, b) => rank(a) - rank(b) || a.key.localeCompare(b.key));
}
function rank(h: HoldingDto) {
  return h.metadata.ticker === "BTC"
    ? 0
    : h.metadata.ticker === "L-BTC"
      ? 1
      : h.metadata.ticker === "TEST"
        ? 2
        : 3;
}
