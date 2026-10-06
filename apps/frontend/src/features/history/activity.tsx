import { ArrowDownLeft, ArrowUpRight, ArrowLeftRight } from "lucide-react";
import { useT } from "../../i18n/messages";
import { usePreferences } from "../../i18n/preferences";
import { displayAssetAmount } from "../../i18n/amount";
import { NavLink } from "react-router-dom";
import type {
  WalletActivityDto,
  AssetKeyDto,
} from "../../../../../crates/mooze-app/generated/types";
import { useWalletHoldings } from "../../app/session-provider";
import { SensitiveValue } from "../../ui/sensitive-value";
import { assetKey } from "../dashboard/holdings-model";
import { direction } from "./activity-model";
import type { HostInfo } from "../../core/client";
export function Movement({
  asset,
  units,
  mode,
}: {
  asset: AssetKeyDto;
  units: string;
  mode: "compact" | "exact";
}) {
  const t = useT();
  const holdings = useWalletHoldings();
  const metadata = holdings.data?.holdings.find(
    (h) => assetKey(h.metadata.key) === assetKey(asset),
  )?.metadata;
  const { preferences } = usePreferences();
  const formatted = displayAssetAmount(
    units,
    metadata ?? {
      key: asset,
      ticker: asset.chain === "Bitcoin" ? "BTC" : null,
      precision: asset.chain === "Bitcoin" ? 8 : null,
      approved: asset.chain === "Bitcoin",
    },
    preferences,
    mode,
  );
  return (
    <SensitiveValue className="amount-value">
      {formatted.amount} {t(formatted.ticker)}
    </SensitiveValue>
  );
}
export function activityLink(row: WalletActivityDto) {
  return `/history?chain=${row.chain}&tx=${encodeURIComponent(row.id)}`;
}
export function statusText(row: WalletActivityDto) {
  return row.status === "Confirmed"
    ? "Confirmado"
    : row.status === "Failed"
      ? "Falhou"
      : "Pendente";
}
export function Activity({
  rows,
}: {
  rows: WalletActivityDto[];
  host?: HostInfo;
}) {
  const t = useT();
  const { preferences } = usePreferences();
  return rows.length ? (
    <div>
      {rows.map((row) => (
        <NavLink
          to={activityLink(row)}
          className="activity"
          key={row.chain + row.id}
        >
          <span className="activity-mark" aria-hidden="true">
            {direction(row) === "Incoming" ? (
              <ArrowDownLeft size={18} />
            ) : direction(row) === "Outgoing" ? (
              <ArrowUpRight size={18} />
            ) : (
              <ArrowLeftRight size={18} />
            )}
          </span>
          <div>
            <strong>
              {direction(row) === "Incoming"
                ? t("Recebido")
                : direction(row) === "Outgoing"
                  ? t("Enviado")
                  : t("Transferência própria")}
            </strong>

            <p className="small muted">
              {row.chain} ·{" "}
              {row.timestamp_ms !== null
                ? new Date(row.timestamp_ms).toLocaleDateString(
                    preferences.locale,
                  )
                : t("Data indisponível")}
            </p>
          </div>
          <div className="activity-amount">
            {row.movements.map((m) => (
              <div key={assetKey(m.asset)}>
                <Movement
                  mode="compact"
                  asset={m.asset}
                  units={m.delta_units}
                />
              </div>
            ))}
            <small className="muted">{t(statusText(row))}</small>
          </div>
        </NavLink>
      ))}
    </div>
  ) : (
    <p className="muted">{t("Nenhuma transação por enquanto.")}</p>
  );
}
