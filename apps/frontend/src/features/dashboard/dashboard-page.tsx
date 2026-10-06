import { useState } from "react";
import { NavLink } from "react-router-dom";
import { RefreshCw } from "lucide-react";
import { useWalletClient } from "../../app/client-context";
import { HoldingsTable, useHoldingViews } from "../assets/assets-page";
import { Activity } from "../history/activity";
import { Button, ErrorNotice } from "../../ui";
import { errorText, type Snapshot, type HostInfo } from "../../core/client";
export function DashboardPage({
  data,
  host,
}: {
  data?: Snapshot;
  host: HostInfo;
}) {
  const client = useWalletClient();
  const { query, rows } = useHoldingViews(data);
  const [error, setError] = useState("");
  return (
    <>
      <div className="page-heading">
        <div>
          <p className="eyebrow">VISÃO GERAL · TESTNET</p>
          <h1>Sua carteira</h1>
          <p className="muted">Bitcoin e ativos Liquid, sob seu controle.</p>
        </div>
      </div>
      <ErrorNotice>
        {error || (query.error ? errorText(query.error) : "")}
      </ErrorNotice>
      <div className="dashboard-grid">
        <section className="card portfolio">
          <div className="card-top">
            <h2>Meus ativos</h2>
            <div className="actions">
              <NavLink className="button primary" to="/receive">
                Receber
              </NavLink>
              <NavLink className="button" to="/send">
                Enviar
              </NavLink>
            </div>
          </div>
          {query.isPending ? (
            <p>Carregando ativos…</p>
          ) : (
            <HoldingsTable rows={rows} />
          )}
          <p className="muted small">
            Ativos de teste não possuem cotação em reais.
          </p>
        </section>
        <section className="card">
          <h2>Estado das redes</h2>
          {["Bitcoin", "Liquid"].map((chain) => {
            const state = query.data?.chains.find((c) => c.chain === chain);
            return (
              <div className="network-state" key={chain}>
                <div className="status-row">
                  <strong>{chain}</strong>
                  <span>
                    {state?.phase === "ready"
                      ? "Sincronizado"
                      : state?.phase === "error"
                        ? "Falha de conexão"
                        : "Sincronizando…"}
                  </span>
                </div>
                <p className="small muted">
                  {state?.last_success_at_ms != null
                    ? `Última sincronização: ${new Date(state.last_success_at_ms).toLocaleString("pt-BR")}`
                    : "Aguardando a primeira sincronização"}
                </p>
              </div>
            );
          })}
          <Button
            onClick={() =>
              void client
                .refresh()
                .then(() => setError(""))
                .catch((e) => setError(errorText(e)))
            }
          >
            <RefreshCw size={14} />
            Atualizar
          </Button>
        </section>
        <section className="card full-width">
          <div className="card-top">
            <h2>Atividade recente</h2>
            <NavLink to="/history">Ver histórico</NavLink>
          </div>
          {data?.transactions.length ? (
            <Activity rows={data.transactions.slice(0, 5)} host={host} />
          ) : (
            <div className="empty">
              <p>Receba moedas de teste para começar.</p>
              <NavLink className="button" to="/receive">
                Receber
              </NavLink>
            </div>
          )}
        </section>
      </div>
    </>
  );
}
