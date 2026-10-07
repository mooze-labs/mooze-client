import { ArrowDownLeft, ArrowUpRight, ArrowLeftRight } from "lucide-react";
import type { WalletActivityDto } from "../../../../../crates/mooze-app/generated/types";
import { useNetworkLabel } from "../../core/network";
import { useT } from "../../i18n/messages";
import { usePreferences } from "../../i18n/preferences";
import { CopyButton } from "../../ui/copy-button";
import { SensitiveValue } from "../../ui/sensitive-value";
import { assetKey } from "../dashboard/holdings-model";
import { Movement, statusText } from "./activity";
import { direction } from "./activity-model";

export function TransactionDetails({
  transaction,
}: {
  transaction: WalletActivityDto;
}) {
  const t = useT();
  const network = useNetworkLabel();
  const { preferences } = usePreferences();
  const flow = direction(transaction);
  const Icon =
    flow === "Incoming"
      ? ArrowDownLeft
      : flow === "Outgoing"
        ? ArrowUpRight
        : ArrowLeftRight;
  const label =
    flow === "Incoming"
      ? "Recebido"
      : flow === "Outgoing"
        ? "Enviado"
        : "Transferência própria";
  return (
    <div className="transaction-details">
      <section
        className="transaction-summary"
        aria-label={t("Movimentações (sem taxa)")}
      >
        <div className="transaction-summary-heading">
          <span className="transaction-direction" aria-hidden="true">
            <Icon size={22} />
          </span>
          <strong>{t(label)}</strong>
          <span className="transaction-status" data-status={transaction.status}>
            {t(statusText(transaction))}
          </span>
        </div>
        <div className="transaction-amounts">
          {transaction.movements.map((movement) => (
            <div key={assetKey(movement.asset)}>
              <Movement
                mode="exact"
                asset={movement.asset}
                units={movement.delta_units}
              />
            </div>
          ))}
        </div>
        <p className="muted small">{t("Movimentações (sem taxa)")}</p>
      </section>

      <dl className="transaction-facts">
        <div>
          <dt>{t("Rede")}</dt>
          <dd>
            {transaction.chain}{" "}
            {network && <span className="muted">· {network}</span>}
          </dd>
        </div>
        <div>
          <dt>{t("Data")}</dt>
          <dd>
            {transaction.timestamp_ms !== null
              ? new Date(transaction.timestamp_ms).toLocaleString(
                  preferences.locale,
                )
              : t("Data indisponível")}
          </dd>
        </div>
        <div>
          <dt>{t("Confirmações")}</dt>
          <dd>{transaction.confirmations}</dd>
        </div>
        <div>
          <dt>{t("Taxa debitada da carteira")}</dt>
          <dd>
            {transaction.fee ? (
              <Movement
                mode="exact"
                asset={transaction.fee.asset}
                units={transaction.fee.units}
              />
            ) : (
              <span className="muted">
                {t("Indisponível ou paga pelo remetente.")}
              </span>
            )}
          </dd>
        </div>
      </dl>

      <section className="transaction-addresses">
        <h3>{t("Endereços")}</h3>
        {transaction.addresses.length ? (
          transaction.addresses.map((address) => (
            <div className="transaction-address" key={address}>
              <p className="mono wrap">
                <SensitiveValue>{address}</SensitiveValue>
              </p>
              <CopyButton value={address} label={t("Copiar endereço")} />
            </div>
          ))
        ) : (
          <p className="muted small">{t("Indisponíveis nesta transação.")}</p>
        )}
      </section>

      <details className="transaction-technical">
        <summary>{t("Detalhes técnicos")}</summary>
        <h3>{t("ID da transação")}</h3>
        <p className="mono wrap">
          <SensitiveValue>{transaction.id}</SensitiveValue>
        </p>
        <CopyButton value={transaction.id} label={t("Copiar ID")} />
        {transaction.movements.map(
          (movement) =>
            movement.asset.asset_id && (
              <div key={assetKey(movement.asset)}>
                <h3>{t("ID do ativo:")}</h3>
                <p className="mono wrap">{movement.asset.asset_id}</p>
              </div>
            ),
        )}
      </details>
    </div>
  );
}
