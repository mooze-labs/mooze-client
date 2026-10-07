import { useNetwork } from "../../core/network";
import { Checkbox } from "../../ui/checkbox";
import { SelectField } from "../../ui/select-field";
import type { FormEvent } from "react";
import type { AssetMetadataDto } from "../../../../../crates/mooze-app/generated/types";
import type { FeeOptionsDto } from "../../core/desktop.generated";
import { useT } from "../../i18n/messages";
import { usePreferences } from "../../i18n/preferences";
import { Button, Field } from "../../ui";
import { assetKey } from "../dashboard/holdings-model";
export function SendForm({
  onReview,
  onEdit,
  onReadRequest,
  busy,
  selected,
  setSelected,
  setMax,
  assets,
  destination,
  setDestination,
  amount,
  setAmount,
  max,
  rate,
  setRate,
  fees,
  ticker,
}: {
  onReview: (e: FormEvent) => void;
  onEdit: () => void;
  onReadRequest: () => void;
  busy: boolean;
  selected: string;
  setSelected: (s: string) => void;
  setMax: (v: boolean) => void;
  assets: AssetMetadataDto[];
  destination: string;
  setDestination: (s: string) => void;
  amount: string;
  setAmount: (s: string) => void;
  max: boolean;
  rate: string;
  setRate: (s: string) => void;
  fees: FeeOptionsDto | null;
  ticker: string;
}) {
  const t = useT();
  const network = useNetwork();
  const { preferences } = usePreferences();
  return (
    <form className="send-form" onSubmit={onReview}>
      <SelectField
        label={t("Ativo e rede")}
        disabled={busy}
        value={selected}
        onValueChange={(value) => {
          setSelected(value);
          setMax(false);
          onEdit();
        }}
        items={[
          { value: "", label: <>{t("Selecione o ativo")}</> },
          ...(assets.map((a) => ({
            value: String(assetKey(a.key)),
            label: (
              <>
                {a.ticker} · {a.key.chain} {network}
              </>
            ),
          })) ?? []),
        ]}
      />
      <Field
        label={t("Endereço de destino")}
        value={destination}
        onChange={(e) => setDestination(e.target.value)}
        required
        disabled={busy}
        autoComplete="off"
        spellCheck={false}
      />
      <Button
        className="read-request"
        disabled={busy || !destination}
        onClick={() => onReadRequest()}
      >
        {t("Ler pedido de pagamento")}
      </Button>
      <Field
        label={t("Quantidade ({ticker})", { ticker })}
        value={amount}
        onChange={(e) => {
          setAmount(e.target.value);
          setMax(false);
        }}
        inputMode="decimal"
        help={t("Até 8 casas decimais, sem separador de milhar.")}
        required={!max}
        disabled={busy || max}
      />
      <label className="checkbox-row">
        <Checkbox checked={max} disabled={busy} onCheckedChange={setMax} />
        {t("Enviar saldo disponível (Máximo)")}
      </label>
      {fees?.kind === "live" ? (
        <div
          className="actions fee-options"
          role="group"
          aria-label={t("Taxas da rede")}
        >
          {fees.rates.map((r, i) => (
            <Button
              key={i}
              disabled={busy}
              aria-pressed={Number(rate.replace(",", ".")) === r}
              onClick={() => setRate(String(r).replace(".", ","))}
            >
              {[t("Econômica"), "Normal", t("Rápida")][i]} · {r} {t("sat/vB")}
            </Button>
          ))}
        </div>
      ) : (
        <p className="muted small">
          {fees?.kind === "configured"
            ? t("Taxa configurada para Liquid; ajustável.")
            : t("Estimativa indisponível. Informe uma taxa personalizada.")}
        </p>
      )}
      {fees && (
        <p className="small muted">
          {t("Fonte")}: {fees.source}
          {fees.observed_at_ms > 0 && (
            <>
              {" "}
              ·{" "}
              {new Date(fees.observed_at_ms).toLocaleTimeString(
                preferences.locale,
              )}
            </>
          )}
        </p>
      )}
      <details className="custom-fee" open={fees?.kind !== "live"}>
        <summary>
          {t("Taxa personalizada")} · {rate} {t("sat/vB")}
        </summary>
        <Field
          label={t("Taxa da rede (sat/vB)")}
          value={rate}
          onChange={(e) => setRate(e.target.value)}
          required
          inputMode="decimal"
          disabled={busy}
        />
      </details>
      <Button type="submit" className="primary wide" disabled={busy}>
        {busy ? t("Calculando taxa…") : t("Revisar envio")}
      </Button>
    </form>
  );
}
