import { assetKey } from "../dashboard/holdings-model";
import type { Snapshot, Review } from "../../core/client";
import type { SubmissionDto } from "../../core/desktop.generated";
import type { AssetAmountDto } from "../../../../../crates/mooze-app/generated/types";
export type SubmissionView = {
  phase: "broadcast" | "confirmed" | "uncertain";
  chain: SubmissionDto["chain"];
  txid: string | null;
  request: SubmissionDto["request"];
  debits: SubmissionDto["debits"];
  fee: AssetAmountDto | null;
  feeProvenance: "review" | "activity" | "unavailable";
};
export function selectSubmissionView(
  snapshot: Snapshot,
  localReview: Review | null,
): SubmissionView | null {
  const journal = snapshot.submission;
  if (!journal || !["sent", "uncertain", "submitting"].includes(journal.phase))
    return null;
  const activity = journal.tx_id
    ? snapshot.activity.find(
        (a) => a.id === journal.tx_id && a.chain === journal.chain,
      )
    : undefined;
  const request = journal.request ?? localReview?.request ?? null;
  const debits = journal.debits ?? localReview?.debits ?? null;
  let approvedFee: AssetAmountDto | null = null;
  if (request?.amount.mode === "Exact" && debits?.length) {
    const own = debits.filter(
      (d) => assetKey(d.asset) === assetKey(request.asset),
    );
    const other = debits.filter(
      (d) => assetKey(d.asset) !== assetKey(request.asset),
    );
    if (
      own.length === 1 &&
      /^\d+$/.test(own[0].units) &&
      /^\d+$/.test(request.amount.units)
    ) {
      const extra = BigInt(own[0].units) - BigInt(request.amount.units);
      if (other.length === 0 && extra >= 0n)
        approvedFee = { asset: request.asset, units: String(extra) };
      else if (
        extra === 0n &&
        other.length === 1 &&
        other[0].asset.chain === request.asset.chain &&
        /^\d+$/.test(other[0].units)
      )
        approvedFee = other[0];
    }
  }
  const fee = activity?.fee ?? approvedFee;
  return {
    phase:
      activity?.status === "Confirmed"
        ? "confirmed"
        : journal.phase === "sent" || activity?.status === "Pending"
          ? "broadcast"
          : "uncertain",
    chain: journal.chain,
    txid: journal.tx_id,
    request,
    debits,
    fee,
    feeProvenance: activity?.fee
      ? "activity"
      : approvedFee || localReview
        ? "review"
        : "unavailable",
  };
}
