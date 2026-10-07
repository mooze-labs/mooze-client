import { Check, Clock3, QrCode, CircleHelp } from "lucide-react";
import { QRCodeSVG } from "qrcode.react";
import type { PixDepositViewDto } from "../../core/desktop.generated";
import { useT } from "../../i18n/messages";
import { usePreferences } from "../../i18n/preferences";
import { CopyButton } from "../../ui/copy-button";
import { SensitiveValue } from "../../ui/sensitive-value";
import { useNow } from "../../ui/use-now";
import { depositStage, formatBrlCents } from "./pix-state";
export const statusLabels: Record<string, string> = {
  payment: "Aguardando pagamento",
  processing: "Pagamento em processamento",
  settled: "Ativos recebidos",
  refunded: "Devolução concluída",
  refund: "Devolução em análise ou processamento",
  failed: "Solicitação encerrada",
  unknown: "Status indisponível",
};
export function PixPayment({ deposit }: { deposit: PixDepositViewDto }) {
  const t = useT();
  const { preferences } = usePreferences();
  const stage = depositStage(deposit.status);
  const now = useNow(stage === "payment" && deposit.expires_at_ms !== null);
  const expired =
    stage === "payment" &&
    deposit.expires_at_ms !== null &&
    now >= deposit.expires_at_ms;
  const completed = stage === "settled" || stage === "refunded";
  const Icon = completed
    ? Check
    : expired || stage === "failed" || stage === "unknown"
      ? CircleHelp
      : stage === "payment"
        ? QrCode
        : Clock3;
  const step = stage === "settled" ? 2 : stage === "processing" ? 1 : 0;
  const steps = ["Solicitação criada", "Processamento", "Entrega dos ativos"];
  const seconds = Math.max(
    0,
    Math.ceil(((deposit.expires_at_ms ?? now) - now) / 1000),
  );
  return (
    <section
      className="card pix-payment transaction-receipt"
      aria-label={t("Pagamento Pix")}
    >
      <div className="pix-payment-heading">
        <div
          className={`receipt-symbol ${completed ? "is-complete" : ""}`}
          key={stage}
          aria-hidden="true"
        >
          <Icon size={24} />
        </div>
        <h2 aria-live="polite">
          {t(expired ? "QR code expirado" : statusLabels[stage])}
        </h2>
      </div>
      <p className="receipt-amount">
        <SensitiveValue>
          {formatBrlCents(deposit.amount_in_cents)}
        </SensitiveValue>
      </p>
      {!expired && ["payment", "processing", "settled"].includes(stage) && (
        <ol className="payment-progress" aria-label={t("Progresso do Pix")}>
          {steps.map((label, index) => (
            <li
              key={label}
              data-complete={index < step || stage === "settled"}
              aria-current={index === step ? "step" : undefined}
            >
              <span aria-hidden="true">
                {index < step || stage === "settled" ? (
                  <Check size={12} />
                ) : (
                  index + 1
                )}
              </span>
              {t(label)}
            </li>
          ))}
        </ol>
      )}
      {stage === "payment" && !expired && (
        <>
          <SensitiveValue>
            <QRCodeSVG
              className="pix-qr"
              value={deposit.pix_key}
              size={208}
              marginSize={3}
            />
          </SensitiveValue>
          <CopyButton
            value={deposit.pix_key}
            label={t("Copiar código Pix")}
            className="primary"
          />
          <details className="receipt-details">
            <summary>{t("Código Pix")}</summary>
            <p className="mono wrap small">
              <SensitiveValue>{deposit.pix_key}</SensitiveValue>
            </p>
          </details>
          {deposit.expires_at_ms !== null && (
            <p className="quote-deadline">
              <Clock3 size={14} aria-hidden="true" />
              {t("Válido por {time}", {
                time: `${Math.floor(seconds / 60)}:${String(seconds % 60).padStart(2, "0")}`,
              })}
            </p>
          )}
        </>
      )}
      {expired && (
        <p className="notice">
          {t(
            "Atualize o status antes de criar uma nova solicitação. Se você já pagou, acompanhe o processamento.",
          )}
        </p>
      )}
      <p className="small muted">
        {t(
          "O pagamento Pix e a entrega dos ativos são etapas diferentes. Acompanhe o status aqui.",
        )}
      </p>
      <div className="receipt-meta">
        <div className="review-row">
          <span>{t("Rede")}</span>
          <span>Liquid</span>
        </div>
        <div className="review-row">
          <span>{t("Criado em")}</span>
          <span>
            {new Date(deposit.created_at_ms).toLocaleString(preferences.locale)}
          </span>
        </div>
        {deposit.blockchain_txid && (
          <details className="receipt-details">
            <summary>{t("ID da transação")}</summary>
            <p className="mono wrap small">
              <SensitiveValue>{deposit.blockchain_txid}</SensitiveValue>
            </p>
            <CopyButton
              value={deposit.blockchain_txid}
              label={t("Copiar ID da transação")}
            />
          </details>
        )}
      </div>
    </section>
  );
}
