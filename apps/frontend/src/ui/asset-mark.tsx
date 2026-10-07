import { Bitcoin, Layers2, FlaskConical, Diamond } from "lucide-react";
import lbtc from "../assets/tokens/lbtc.svg";
import depix from "../assets/tokens/depix.svg";
import usdt from "../assets/tokens/usdt.svg";
import type { AssetMetadataDto } from "../../../../crates/mooze-app/generated/types";
export function AssetMark({ metadata }: { metadata: AssetMetadataDto }) {
  const image = metadata.approved
    ? ({ "L-BTC": lbtc, DEPIX: depix, USDT: usdt } as Record<string, string>)[
        metadata.ticker ?? ""
      ]
    : undefined;
  if (image)
    return (
      <img
        className="asset-mark token-image"
        src={image}
        alt=""
        aria-hidden="true"
      />
    );
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
