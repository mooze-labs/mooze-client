import { LoadingRows } from "../../ui/loading-rows";
import { useT } from "../../i18n/messages";
import { NavLink } from "react-router-dom";
import {
  ArrowDownLeft,
  ArrowUpRight,
  ArrowLeftRight,
  QrCode,
} from "lucide-react";
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
      <div className="page-heading overview-heading">
        <div>
          <p className="eyebrow">{t("VISÃO GERAL")}</p>
          <h1>{t("Sua carteira")}</h1>
          <p className="muted">
            {t("Seus ativos e suas movimentações, em um só lugar.")}
          </p>
        </div>
        <span className="network-pill">{host.network} · Bitcoin + Liquid</span>
      </div>
      <nav className="wallet-quick-actions" aria-label={t("Ações da carteira")}>
        <NavLink className="quick-action" to="/receive">
          <span>
            <ArrowDownLeft size={21} />
          </span>
          <strong>{t("Receber")}</strong>
          <small>{t("Bitcoin e Liquid")}</small>
        </NavLink>
        <NavLink className="quick-action" to="/send">
          <span>
            <ArrowUpRight size={21} />
          </span>
          <strong>{t("Enviar")}</strong>
          <small>{t("Para outra carteira")}</small>
        </NavLink>
        {host.pix_enabled && (
          <NavLink className="quick-action" to="/pix">
            <span>
              <QrCode size={21} />
            </span>
            <strong>Pix</strong>
            <small>{t("Reais para sua carteira")}</small>
          </NavLink>
        )}
        {host.swaps_enabled && (
          <NavLink className="quick-action" to="/swap">
            <span>
              <ArrowLeftRight size={21} />
            </span>
            <strong>{t("Trocar")}</strong>
            <small>{t("Entre ativos Liquid")}</small>
          </NavLink>
        )}
      </nav>
      <ErrorNotice>{query.error ? errorText(query.error) : ""}</ErrorNotice>
      <section aria-label={t("Meus ativos")} className="balance-panel">
        <div className="balance-heading">
          <h2>{t("Meus ativos")}</h2>
          <NavLink to="/assets">{t("Ver ativos")}</NavLink>
        </div>
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
            <p>
              {t(
                host.network === "Testnet"
                  ? "Receba moedas de teste para começar."
                  : "Receba Bitcoin ou ativos Liquid para começar.",
              )}
            </p>
            <NavLink className="button" to="/receive">
              {t("Receber")}
            </NavLink>
          </div>
        )}
      </section>
    </div>
  );
}
