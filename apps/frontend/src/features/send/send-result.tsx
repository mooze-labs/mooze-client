import { useNetworkLabel } from "../../core/network";
import { useSendAmount } from "./send-amount";
import { Check, Clock, Search } from "lucide-react";
import type { SubmissionView } from "./submission-view";
import type {
  AssetKeyDto,
  AssetMetadataDto,
} from "../../../../../crates/mooze-app/generated/types";
import { useT } from "../../i18n/messages";
import { Button } from "../../ui";
import { SensitiveValue } from "../../ui/sensitive-value";
import { assetKey } from "../dashboard/holdings-model";
export function SendResult({
  view,
  onCheck,
  onViewTransaction,
  onReturn,
  onNew,
  name,
  reviewFee,
  busy,
  assets = [],
}: {
  assets?: AssetMetadataDto[];
  view: SubmissionView;
  onCheck: () => void;
  onViewTransaction: () => void;
  onReturn: () => void;
  onNew: () => void;
  name: (key: AssetKeyDto) => string;
  reviewFee?: number;
  busy: boolean;
}) {
  const t = useT();
  const network = useNetworkLabel();
  const format = useSendAmount(assets);
  const Icon =
    view.phase === "confirmed"
      ? Check
      : view.phase === "broadcast"
        ? Clock
        : Search;
  return (
    <div className="send-result">
      <span aria-hidden="true" className={`result-mark ${view.phase}`}>
        <Icon size={28} />
      </span>
      <h2>
        {t(
          view.phase === "confirmed"
            ? "Transação confirmada"
            : view.phase === "broadcast"
              ? "Transação enviada"
              : "Verificando o resultado",
        )}
      </h2>
      <p className="muted">
        {t(
          view.phase === "confirmed"
            ? "Confirmado pela rede."
            : view.phase === "broadcast"
              ? "Aguardando confirmação da rede."
              : "O envio pode ter chegado à rede. Confira o histórico antes de iniciar outra transação.",
        )}
      </p>
      <section className="receipt" aria-label={t("Detalhes do envio")}>
        <div className="review-row">
          <span>{t("Rede")}</span>
          <span>
            {view.chain} {network}
          </span>
        </div>
        {view.request ? (
          <>
            <div className="review-row review-amount">
              <span>{t("Quantidade")}</span>
              <SensitiveValue>
                {view.request.amount.mode === "Exact"
                  ? format.amount(view.request.amount.units, view.request.asset)
                  : t("Indisponível")}
              </SensitiveValue>
            </div>
            <div className="review-row">
              <span>{t("Destino")}</span>
              <span className="review-address">{view.request.destination}</span>
            </div>
          </>
        ) : (
          <p>
            {t(
              "Detalhes indisponíveis para este envio antigo. Confira o histórico antes de continuar.",
            )}
          </p>
        )}
        <div className="review-row">
          <span>
            {t(
              view.feeProvenance === "activity"
                ? "Taxa"
                : "Taxa máxima aprovada",
            )}
          </span>
          <SensitiveValue>
            {view.fee
              ? format.amount(view.fee.units, view.fee.asset)
              : view.feeProvenance === "review" && reviewFee !== undefined
                ? format.nativeFee(String(reviewFee), view.chain)
                : t("Indisponível")}
          </SensitiveValue>
        </div>
        {view.debits && (
          <details>
            <summary>{t("Débitos máximos")}</summary>
            {view.debits.map((d) => (
              <div className="review-row" key={assetKey(d.asset)}>
                <span>{name(d.asset)}</span>
                <SensitiveValue>
                  {format.amount(d.units, d.asset)}
                </SensitiveValue>
              </div>
            ))}
          </details>
        )}
        {view.txid && (
          <details>
            <summary>{t("ID da transação")}</summary>
            <p className="mono wrap small">{view.txid}</p>
          </details>
        )}
      </section>
      <div className="actions">
        {view.phase === "uncertain" ? (
          <Button className="primary" onClick={onCheck}>
            {t("Atualizar histórico")}
          </Button>
        ) : (
          <Button className="primary" onClick={onViewTransaction}>
            {t("Ver histórico")}
          </Button>
        )}
        <Button onClick={onReturn}>{t("Voltar à carteira")}</Button>
      </div>
      <Button className="ghost" disabled={busy} onClick={onNew}>
        {t(
          view.phase === "uncertain"
            ? "Conferi o histórico. Preparar outro envio"
            : "Novo envio",
        )}
      </Button>
    </div>
  );
}
