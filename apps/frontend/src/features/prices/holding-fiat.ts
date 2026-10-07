import type { HoldingView } from "../dashboard/holdings-model";
import type {
  PriceHistoryDto,
  PriceMarketDto,
} from "../../core/desktop.generated";
import { priceMarket } from "./price-model";
export const MAX_RATE_AGE_MS = 3_600_000;
const DEPIX =
  "02f22f8d9c76ab41661a2729e4752e2c5d1a263012141b86ea98af5472df5189";
export type FiatRate = { price: number; timestamp: number; source: string };
export type FiatValue = {
  cents: bigint | null;
  rate?: FiatRate;
  fixed: boolean;
};
export type FiatRates = Partial<Record<PriceMarketDto, FiatRate | null>>;
export function latestRate(
  history: PriceHistoryDto | undefined,
  now: number,
): FiatRate | null {
  const point = history?.points
    .filter(
      (p) =>
        Number.isFinite(p.price) &&
        p.price > 0 &&
        Number.isFinite(p.timestamp_ms) &&
        p.timestamp_ms <= now &&
        now - p.timestamp_ms <= MAX_RATE_AGE_MS,
    )
    .reduce<PriceHistoryDto["points"][number] | undefined>(
      (latest, p) =>
        !latest || p.timestamp_ms > latest.timestamp_ms ? p : latest,
      undefined,
    );
  return point && history
    ? {
        price: point.price,
        timestamp: point.timestamp_ms,
        source: history.source,
      }
    : null;
}
/** Prices are estimates; wallet quantities stay integers throughout valuation. */
export function holdingFiat(
  row: HoldingView,
  network: string,
  rates: FiatRates,
): FiatValue {
  const { metadata } = row;
  const fixed =
    network === "Mainnet" &&
    metadata.approved &&
    metadata.key.chain === "Liquid" &&
    metadata.key.asset_id === DEPIX;
  const unavailable = { cents: null, fixed };
  const precision = metadata.precision;
  if (
    row.balanceText === null ||
    row.stale ||
    precision === null ||
    !Number.isInteger(precision) ||
    precision < 0 ||
    precision > 18
  )
    return unavailable;
  const market = priceMarket(metadata, network);
  if (!fixed && !market) return unavailable;
  const rate = market ? rates[market] : null;
  const units = BigInt(row.balance_units);
  if (units < 0n) return unavailable;
  if (units === 0n) return { cents: 0n, fixed };
  const scaled = Math.round((fixed ? 1 : (rate?.price ?? NaN)) * 100_000_000);
  if (!Number.isSafeInteger(scaled) || scaled <= 0) return unavailable;
  const divisor = 10n ** BigInt(precision) * 100_000_000n;
  return {
    cents: (units * BigInt(scaled) * 100n + divisor / 2n) / divisor,
    fixed,
    rate: rate ?? undefined,
  };
}
export function summarizeFiat(rows: HoldingView[], values: FiatValue[]) {
  const partial = rows.some(
    (row, i) =>
      values[i].cents === null &&
      (row.balanceText === null || BigInt(row.balance_units) !== 0n),
  );
  const known = values.filter((value) => value.cents !== null);
  return {
    cents: known.length
      ? known.reduce((sum, value) => sum + value.cents!, 0n)
      : null,
    partial,
  };
}
export function formatBrl(cents: bigint, locale: string) {
  return new Intl.NumberFormat(locale, {
    style: "currency",
    currency: "BRL",
    minimumFractionDigits: 2,
    maximumFractionDigits: 2,
  })
    .formatToParts(cents / 100n)
    .map((part) =>
      part.type === "fraction"
        ? (cents % 100n).toString().padStart(2, "0")
        : part.value,
    )
    .join("");
}
