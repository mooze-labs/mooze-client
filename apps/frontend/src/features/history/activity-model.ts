import type { WalletActivityDto } from "../../../../../crates/mooze-app/generated/types";
import { assetKey } from "../dashboard/holdings-model";
export type ActivityFilter = {
  asset?: string;
  network?: string;
  status?: string;
  direction?: string;
  from?: string;
  to?: string;
};
export function direction(
  row: WalletActivityDto,
): "Incoming" | "Outgoing" | "SelfTransfer" {
  const deltas = row.movements.map((m) => BigInt(m.delta_units));
  return deltas.some((v) => v < 0n)
    ? "Outgoing"
    : deltas.some((v) => v > 0n)
      ? "Incoming"
      : "SelfTransfer";
}
export function filterActivity(
  rows: WalletActivityDto[],
  filter: ActivityFilter,
): WalletActivityDto[] {
  const from = filter.from
    ? new Date(`${filter.from}T00:00:00`).getTime()
    : null;
  const to = filter.to ? new Date(`${filter.to}T23:59:59.999`).getTime() : null;
  return rows
    .filter(
      (row) =>
        (!filter.asset ||
          row.movements.some((m) => assetKey(m.asset) === filter.asset)) &&
        (!filter.network || row.chain === filter.network) &&
        (!filter.status || row.status === filter.status) &&
        (!filter.direction || direction(row) === filter.direction) &&
        (from === null ||
          (row.timestamp_ms !== null && row.timestamp_ms >= from)) &&
        (to === null || (row.timestamp_ms !== null && row.timestamp_ms <= to)),
    )
    .sort(
      (a, b) =>
        (b.timestamp_ms ?? Number.MAX_SAFE_INTEGER) -
          (a.timestamp_ms ?? Number.MAX_SAFE_INTEGER) ||
        a.id.localeCompare(b.id),
    );
}
