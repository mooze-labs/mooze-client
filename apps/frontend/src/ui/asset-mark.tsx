import { Bitcoin, Layers2, FlaskConical, Diamond } from "lucide-react";
import type { AssetMetadataDto } from "../../../../crates/mooze-app/generated/types";
export function AssetMark({ metadata }: { metadata: AssetMetadataDto }) {
  const kind = metadata.approved
    ? metadata.ticker === "BTC"
      ? "bitcoin"
      : metadata.ticker === "L-BTC"
        ? "liquid"
        : "test"
    : "unknown";
  const Icon =
    kind === "bitcoin"
      ? Bitcoin
      : kind === "liquid"
        ? Layers2
        : kind === "test"
          ? FlaskConical
          : Diamond;
  return (
    <span aria-hidden="true" className={`asset-mark ${kind}`}>
      <Icon size={22} strokeWidth={1.7} />
    </span>
  );
}
