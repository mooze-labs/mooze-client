import type { AssetMetadataDto } from "../../../../../crates/mooze-app/generated/types";
import type {
  PriceMarketDto,
  PricePointDto,
} from "../../core/desktop.generated";
const LBTC = "6f0279e9ed041c3d710a9f57d0c02928416460c4b722ae3457a11eec381c526d";
const USDT = "ce091c998b83c78bb71a632313ba3760f1763d9cfcffae02258ffa9865a37bd2";
/** Use approved asset identity, never a user-supplied ticker, to select a market. */
export function priceMarket(
  asset: AssetMetadataDto,
  network: string,
): PriceMarketDto | null {
  if (network !== "Mainnet" || !asset.approved) return null;
  if (asset.key.chain === "Bitcoin" && asset.key.asset_id === null)
    return "Bitcoin";
  if (asset.key.chain === "Liquid" && asset.key.asset_id === LBTC)
    return "Bitcoin";
  if (asset.key.chain === "Liquid" && asset.key.asset_id === USDT)
    return "Tether";
  return null;
}
export function chartGeometry(points: PricePointDto[]) {
  const min = Math.min(...points.map((p) => p.price));
  const max = Math.max(...points.map((p) => p.price));
  const start = points[0].timestamp_ms;
  const elapsed = Math.max(1, points.at(-1)!.timestamp_ms - start);
  const padding = (max - min || max * 0.01 || 1) * 0.1;
  const lower = min - padding;
  const upper = max + padding;
  const coordinates = points.map((point) => ({
    x: 12 + ((point.timestamp_ms - start) / elapsed) * 696,
    y: 12 + ((upper - point.price) / (upper - lower)) * 176,
  }));
  return {
    min,
    max,
    coordinates,
    path: coordinates
      .map((p, i) => `${i ? "L" : "M"}${p.x.toFixed(2)},${p.y.toFixed(2)}`)
      .join(" "),
    change: (points.at(-1)!.price / points[0].price - 1) * 100,
  };
}
