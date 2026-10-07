export function parseBrlCents(text: string): string | null {
  text = text.trim();
  if (/^\d{1,3}(?:\.\d{3})+,\d{1,2}$/.test(text))
    text = text.replaceAll(".", "");
  if (!/^\d+(?:[.,]\d{1,2})?$/.test(text.trim())) return null;
  const [whole, fraction = ""] = text.trim().replace(",", ".").split(".");
  const cents = BigInt(whole) * 100n + BigInt(fraction.padEnd(2, "0"));
  return cents > 0n && cents <= BigInt(Number.MAX_SAFE_INTEGER)
    ? cents.toString()
    : null;
}
export function depositStage(status: string) {
  if (["Completed", "Finished"].includes(status)) return "settled";
  if (["Refunded", "FinishedRefund"].includes(status)) return "refunded";
  if (["ProcessingRefund", "BroadcastedRefund", "Med"].includes(status))
    return "refund";
  if (["Failed", "Expired", "Timeout"].includes(status)) return "failed";
  if (status === "Pending") return "payment";
  if (
    [
      "UnderReview",
      "Processing",
      "FundsPrepared",
      "DepixSent",
      "Paid",
      "Broadcasted",
    ].includes(status)
  )
    return "processing";
  return "unknown";
}

export function formatBrlCents(cents: string) {
  const value = BigInt(cents);
  return `R$ ${value / 100n},${(value % 100n).toString().padStart(2, "0")}`;
}
