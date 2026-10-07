import { useT } from "../../i18n/messages";
import { usePreferences } from "../../i18n/preferences";
import { SensitiveValue } from "../../ui/sensitive-value";
import { Button } from "../../ui";
import { formatBrl, type FiatValue } from "./holding-fiat";
import type { useHoldingFiat } from "./use-holding-fiat";
export function HoldingFiatValue({ value }: { value: FiatValue }) {
  const t = useT();
  const { preferences } = usePreferences();
  return (
    <small className="holding-fiat muted">
      {value.cents === null ? (
        t("Valor em BRL indisponível")
      ) : (
        <SensitiveValue className="fiat-value">
          {value.fixed ? "" : "≈ "}
          {formatBrl(value.cents, preferences.locale)}
        </SensitiveValue>
      )}
    </small>
  );
}
export function FiatSummary({
  fiat,
}: {
  fiat: ReturnType<typeof useHoldingFiat>;
}) {
  const t = useT();
  const { preferences } = usePreferences();
  const timestamp = fiat.rates.length
    ? Math.min(...fiat.rates.map((rate) => rate.timestamp))
    : null;
  const sources = [...new Set(fiat.rates.map((rate) => rate.source))].join(
    ", ",
  );
  return (
    <section className="fiat-summary" aria-label={t("Saldo estimado em BRL")}>
      <p className="muted">
        {t(
          fiat.total.partial
            ? "Saldo parcial estimado em BRL"
            : "Saldo estimado em BRL",
        )}
      </p>
      <strong className="fiat-total">
        {fiat.total.cents === null ? (
          "—"
        ) : (
          <SensitiveValue className="fiat-value">
            ≈ {formatBrl(fiat.total.cents, preferences.locale)}
          </SensitiveValue>
        )}
      </strong>
      <p className="muted small">
        {t("1 DePix = R$ 1,00. L-BTC usa a cotação do Bitcoin.")}
      </p>
      {fiat.loading ? (
        <p className="muted small" role="status">
          {t("Carregando preços…")}
        </p>
      ) : (
        fiat.total.partial && (
          <p className="muted small">
            {t("Ativos sem cotação ou saldo atualizado não entram no total.")}
          </p>
        )
      )}
      {timestamp !== null && (
        <p className="muted small">
          {t("Cotações: {source} · {date}", {
            source: sources,
            date: new Date(timestamp).toLocaleString(preferences.locale),
          })}
        </p>
      )}
      {fiat.refreshFailed && (
        <div className="fiat-retry">
          <span className="muted small">
            {t("Não foi possível atualizar as cotações.")}
          </span>
          <Button onClick={fiat.retry}>{t("Tentar novamente")}</Button>
        </div>
      )}
    </section>
  );
}
