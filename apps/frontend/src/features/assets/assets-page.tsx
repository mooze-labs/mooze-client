import { SensitiveValue } from "../../ui/sensitive-value";
import { useState } from "react";
import { NavLink, useParams } from "react-router-dom";
import type { Snapshot } from "../../core/client";
import { errorText } from "../../core/client";
import { useWalletHoldings } from "../../app/session-provider";
import {
  selectHoldings,
  assetKey,
  assetPath,
  type HoldingView,
} from "../dashboard/holdings-model";
import { ErrorNotice } from "../../ui";
export function useHoldingViews(data?: Snapshot) {
  const query = useWalletHoldings();
  const keys =
    data?.transactions.map((t) =>
      assetKey({ chain: t.chain, asset_id: t.asset_id }),
    ) ?? [];
  return {
    query,
    rows: selectHoldings(
      query.data?.holdings ?? [],
      query.data?.chains ?? [],
      keys,
    ),
  };
}
export function HoldingValue({ row }: { row: HoldingView }) {
  return row.balanceText === null ? (
    <span className="muted">Aguardando sincronização</span>
  ) : (
    <>
      <SensitiveValue>
        {row.balanceText} {row.metadata.ticker ?? "unidades brutas"}
      </SensitiveValue>
      {row.stale && <small className="muted"> · saldo anterior</small>}
    </>
  );
}
export function HoldingsTable({ rows }: { rows: HoldingView[] }) {
  return (
    <div className="table-scroll">
      <table>
        <thead>
          <tr>
            <th>Ativo</th>
            <th>Rede</th>
            <th>Saldo</th>
            <th>Pendente (incluído no saldo)</th>
          </tr>
        </thead>
        <tbody>
          {rows.map((row) => (
            <tr key={row.key}>
              <td>
                <NavLink
                  className="asset-link"
                  to={assetPath(row.metadata.key)}
                >
                  <strong>{row.metadata.ticker ?? "Ativo não listado"}</strong>
                  {!row.metadata.approved && (
                    <span className="mono small wrap">
                      {row.metadata.key.asset_id}
                    </span>
                  )}
                </NavLink>
              </td>
              <td>{row.metadata.key.chain} Testnet</td>
              <td>
                <HoldingValue row={row} />
              </td>
              <td>
                {row.balanceText !== null && row.pending_units !== null ? (
                  <SensitiveValue>{row.pending_units} sat</SensitiveValue>
                ) : (
                  <span className="muted">Indisponível</span>
                )}
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}
export function AssetsPage({ data }: { data?: Snapshot }) {
  const { query, rows } = useHoldingViews(data);
  const [search, setSearch] = useState("");
  const [network, setNetwork] = useState("all");
  const filtered = rows.filter(
    (r) =>
      (network === "all" || r.metadata.key.chain === network) &&
      `${r.metadata.ticker ?? ""} ${r.metadata.key.asset_id ?? ""}`
        .toLowerCase()
        .includes(search.toLowerCase().trim()),
  );
  return (
    <section className="card">
      <h1>Meus ativos</h1>
      <div className="actions">
        <label className="field">
          Buscar ativo
          <input
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            placeholder="Nome ou ID do ativo"
          />
        </label>
        <label className="field">
          Rede
          <select value={network} onChange={(e) => setNetwork(e.target.value)}>
            <option value="all">Todas as redes</option>
            <option>Bitcoin</option>
            <option>Liquid</option>
          </select>
        </label>
      </div>
      <ErrorNotice>{query.error ? errorText(query.error) : ""}</ErrorNotice>
      {query.isPending ? (
        <p>Carregando ativos…</p>
      ) : filtered.length ? (
        <HoldingsTable rows={filtered} />
      ) : (
        <p>Nenhum ativo corresponde aos filtros.</p>
      )}
    </section>
  );
}
export function AssetPage({ data }: { data?: Snapshot }) {
  const { chain, assetKey: routeKey } = useParams();
  const { query } = useHoldingViews(data);
  const holding = query.data?.holdings.find(
    (h) =>
      h.metadata.key.chain === chain &&
      (h.metadata.key.asset_id ?? "native") === routeKey,
  );
  const row = holding
    ? selectHoldings([holding], query.data?.chains ?? [], [
        assetKey(holding.metadata.key),
      ])[0]
    : null;
  if (!row)
    return (
      <section className="card">
        <h1>Ativo</h1>
        <ErrorNotice>{query.error ? errorText(query.error) : ""}</ErrorNotice>
        <p>
          {query.isPending
            ? "Carregando…"
            : "Ativo não encontrado nesta carteira."}
        </p>
        <NavLink to="/assets">Ver ativos</NavLink>
      </section>
    );
  const params = new URLSearchParams({
    chain: row.metadata.key.chain,
    asset: row.metadata.key.asset_id ?? "native",
  });
  return (
    <>
      <section className="card">
        <p className="eyebrow">{chain} Testnet</p>
        <h1>{row.metadata.ticker ?? "Ativo não listado"}</h1>
        <h2>
          <HoldingValue row={row} />
        </h2>
        {row.metadata.key.asset_id && (
          <p className="mono wrap">{row.metadata.key.asset_id}</p>
        )}
        {row.metadata.approved ? (
          <div className="actions">
            <NavLink className="button primary" to={`/receive?${params}`}>
              Receber
            </NavLink>
            {row.metadata.ticker !== "TEST" ? (
              <NavLink className="button" to={`/send?${params}`}>
                Enviar
              </NavLink>
            ) : (
              <p className="muted">Envio de TEST em implementação.</p>
            )}
          </div>
        ) : (
          <div className="notice">
            Precisão desconhecida. Valores em unidades brutas. O envio deste
            ativo não é suportado nesta versão.
          </div>
        )}
      </section>
      <section className="card section-gap">
        <h2>Atividade do ativo</h2>
        {data?.transactions
          .filter(
            (t) => t.chain === chain && (t.asset_id ?? "native") === routeKey,
          )
          .map((t) => (
            <div className="activity" key={t.id}>
              <NavLink className="mono wrap" to="/history">
                {t.id}
              </NavLink>
              <span>
                {t.status === "Confirmed" ? "Confirmado" : "Pendente"}
              </span>
            </div>
          ))}
        <NavLink to="/history">Abrir histórico</NavLink>
      </section>
    </>
  );
}
