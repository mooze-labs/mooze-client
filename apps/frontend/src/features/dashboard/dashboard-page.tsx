import { LoadingRows } from "../../ui/loading-rows";
import { useT } from "../../i18n/messages";
import { NavLink } from "react-router-dom";
import { ArrowDownLeft, ArrowUpRight } from "lucide-react";
import { HoldingsTable, useHoldingViews } from "../assets/assets-page";
import { Activity } from "../history/activity";
import { ErrorNotice } from "../../ui";
import { errorText, type Snapshot, type HostInfo } from "../../core/client";
export function DashboardPage({
  data,
  host,
}: {
  data?: Snapshot;
  host: HostInfo;
}) {
  const t = useT();
  const { query, rows } = useHoldingViews(data);
  return (
    <div className="wallet-overview">
      <div className="page-heading">
        <h1>{t("Sua carteira")}</h1>
        <div className="actions">
          <NavLink className="button primary" to="/receive">
            <ArrowDownLeft size={16} />
            {t("Receber")}
          </NavLink>
          <NavLink className="button" to="/send">
            <ArrowUpRight size={16} />
            {t("Enviar")}
          </NavLink>
        </div>
      </div>
      <ErrorNotice>{query.error ? errorText(query.error) : ""}</ErrorNotice>
      <section aria-label={t("Meus ativos")} className="balance-panel">
        {query.isPending ? (
          <LoadingRows label={t("Carregando ativos…")} />
        ) : (
          <HoldingsTable rows={rows} />
        )}
      </section>
      <section className="recent-activity">
        <div className="card-top">
          <h2>{t("Atividade recente")}</h2>
          <NavLink to="/history">{t("Ver histórico")}</NavLink>
        </div>
        {!data ? (
          <LoadingRows label={t("Carregando atividade…")} rows={3} />
        ) : data.activity.length ? (
          <Activity rows={data.activity.slice(0, 5)} host={host} />
        ) : (
          <div className="empty">
            <ArrowDownLeft size={28} aria-hidden="true" />
            <p>{t("Receba moedas de teste para começar.")}</p>
            <NavLink className="button" to="/receive">
              {t("Receber")}
            </NavLink>
          </div>
        )}
      </section>
    </div>
  );
}
