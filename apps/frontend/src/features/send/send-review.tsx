import { useSendAmount } from "./send-amount";
import type { Review } from "../../core/client";
import type {
  AssetKeyDto,
  AssetMetadataDto,
} from "../../../../../crates/mooze-app/generated/types";
import { useT } from "../../i18n/messages";
import { Button } from "../../ui";
import { SensitiveValue } from "../../ui/sensitive-value";
import { assetKey } from "../dashboard/holdings-model";
export function SendReviewView({
  review,
  busy,
  expiresAtMs,
  nowMs,
  onEdit,
  onConfirm,
  name,
  assets = [],
}: {
  assets?: AssetMetadataDto[];
  review: Review;
  busy: boolean;
  expiresAtMs: number;
  nowMs: number;
  onEdit: () => void;
  onConfirm: () => void;
  name: (asset: AssetKeyDto) => string;
}) {
  const t = useT();
  const format = useSendAmount(assets);
  return (
    <>
      <p className="eyebrow">{t("REVISÃO DO ENVIO")}</p>
      <h2>{t("Confirme os detalhes")}</h2>
      <div className="review-row">
        <span>{t("Rede")}</span>
        <span>
          {review.request.asset.chain} {t("Testnet")}
        </span>
      </div>
      <div className="review-row">
        <span>{t("Destino")}</span>
        <span className="review-address">{review.request.destination}</span>
      </div>
      <div className="review-row review-amount">
        <span>{t("Quantidade")}</span>
        <SensitiveValue>
          {review.request.amount.mode === "Exact"
            ? format.amount(review.request.amount.units, review.request.asset)
            : t("Indisponível")}
        </SensitiveValue>
      </div>
      <div className="review-row">
        <span>{t("Taxa máxima aprovada")}</span>
        <SensitiveValue>
          {format.nativeFee(String(review.fee_sat), review.request.asset.chain)}
        </SensitiveValue>
      </div>
      <h3>{t("Débitos máximos")}</h3>
      {review.debits.map((d) => (
        <div className="review-row" key={assetKey(d.asset)}>
          <span>{name(d.asset)}</span>
          <SensitiveValue>{format.amount(d.units, d.asset)}</SensitiveValue>
        </div>
      ))}
      <p className="muted small">
        {nowMs >= expiresAtMs
          ? t("Revisão expirada. Volte e revise novamente.")
          : t("Revisão válida por {seconds} segundos.", {
              seconds: Math.max(0, Math.ceil((expiresAtMs - nowMs) / 1000)),
            })}
      </p>
      <div className="actions">
        <Button disabled={busy} onClick={onEdit}>
          {t("Editar")}
        </Button>
        <Button
          className="primary"
          disabled={busy || nowMs >= expiresAtMs}
          onClick={onConfirm}
        >
          {busy ? t("Enviando…") : t("Confirmar envio")}
        </Button>
      </div>
    </>
  );
}
