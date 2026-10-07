import { Clock3, CircleHelp } from "lucide-react";
import { CopyButton } from "../../ui/copy-button";
import { SwapAmounts, type SwapAssetLookup } from "./swap-review";
import { NavLink } from "react-router-dom";
import type { SwapStateDto } from "../../core/desktop.generated";
import { useT } from "../../i18n/messages";
import { Button } from "../../ui";
import { SensitiveValue } from "../../ui/sensitive-value";
export function SwapResult({
  state,
  onNew,
  busy,
  asset,
}: {
  state: SwapStateDto;
  onNew: () => void;
  busy: boolean;
  asset: SwapAssetLookup;
}) {
  const t = useT();
  return (
    <section className="card receipt transaction-receipt swap-result">
      <div className="receipt-symbol" aria-hidden="true">
        {state.phase === "Uncertain" ? (
          <CircleHelp size={26} />
        ) : (
          <Clock3 size={26} />
        )}
      </div>
      <h2 aria-live="polite">
        {t(
          state.phase === "Succeeded"
            ? "Troca enviada"
            : state.phase === "Submitting"
              ? "Enviando troca…"
              : "Resultado da troca incerto",
        )}
      </h2>
      <p>
        {t(
          state.message ||
            (state.phase === "Succeeded"
              ? "Aguardando confirmação da rede."
              : "Não repita a operação. Confira o histórico para acompanhar o resultado."),
        )}
      </p>
      {state.review && <SwapAmounts review={state.review} asset={asset} />}
      {state.txid && (
        <details className="receipt-details">
          <summary>{t("ID da transação")}</summary>
          <p className="mono wrap small">
            <SensitiveValue>{state.txid}</SensitiveValue>
          </p>
          <CopyButton value={state.txid} label={t("Copiar ID da transação")} />
        </details>
      )}
      <div className="flow-actions">
        <NavLink
          className="button primary"
          to={
            state.txid
              ? `/history?chain=Liquid&tx=${encodeURIComponent(state.txid)}`
              : "/history"
          }
        >
          {t("Ver histórico")}
        </NavLink>
        {state.phase === "Succeeded" && (
          <Button disabled={busy} onClick={onNew}>
            {t("Nova troca")}
          </Button>
        )}
      </div>
    </section>
  );
}
