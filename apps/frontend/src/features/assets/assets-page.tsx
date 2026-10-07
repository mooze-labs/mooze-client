import { useNetwork } from "../../core/network";
import { SelectField } from "../../ui/select-field";
import { Input } from "../../ui/input";
import { Amount } from "../../ui/amount";
import { AssetMark } from "../../ui/asset-mark";
import { useT } from "../../i18n/messages";
import { Activity } from "../history/activity";
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
    data?.activity.flatMap((t) => t.movements.map((m) => assetKey(m.asset))) ??
    [];
  return {
    query,
    rows: selectHoldings(
      query.data?.holdings ?? [],
      query.data?.chains ?? [],
      keys,
    ),
  };
}
export function HoldingValue({
  row,
  mode = "compact",
}: {
  row: HoldingView;
  mode?: "compact" | "exact";
}) {
  const t = useT();
  const buildNetwork = useNetwork();
  return row.balanceText === null ? (
    <span className="muted">{t("Aguardando sincronização")}</span>
  ) : (
    <>
      <Amount units={row.balance_units} metadata={row.metadata} mode={mode} />
      {row.stale && <small className="muted">{t("· saldo anterior")}</small>}
    </>
  );
}
export function HoldingsTable({ rows }: { rows: HoldingView[] }) {
  const t = useT();
  const buildNetwork = useNetwork();
  return (
    <div className="holding-list">
      {rows.map((row) => (
        <NavLink
          className="holding-row"
          key={row.key}
          to={assetPath(row.metadata.key)}
        >
          <AssetMark metadata={row.metadata} />
          <div className="holding-name">
            <strong>{row.metadata.ticker ?? t("Ativo não listado")}</strong>
            <small className="muted">
              {row.metadata.key.chain}
              {!row.metadata.approved && (
                <>
                  {" "}
                  · {row.metadata.key.asset_id?.slice(0, 8)}…
                  {row.metadata.key.asset_id?.slice(-6)}
                </>
              )}
            </small>
          </div>
          <div className="holding-balance">
            <HoldingValue row={row} />
            {row.balanceText !== null &&
              row.pending_units !== null &&
              BigInt(row.pending_units) !== 0n && (
                <small className="muted pending-amount">
                  {t("Pendente (incluído no saldo)")}:{" "}
                  <Amount
                    units={row.pending_units}
                    metadata={row.metadata}
                    mode="compact"
                  />
                </small>
              )}
          </div>
          <span className="muted" aria-hidden="true">
            ›
          </span>
        </NavLink>
      ))}
    </div>
  );
}
export function AssetsPage({ data }: { data?: Snapshot }) {
  const t = useT();
  const buildNetwork = useNetwork();
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
      <h1>{t("Meus ativos")}</h1>
      <div className="actions">
        <label className="field">
          {t("Buscar ativo")}
          <Input
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            placeholder={t("Nome ou ID do ativo")}
          />
        </label>
        <SelectField
          label={t("Rede")}
          value={network}
          onValueChange={(value) => setNetwork(value)}
          items={[
            { value: "all", label: <>{t("Todas as redes")}</> },
            { value: "Bitcoin", label: <>{t("Bitcoin")}</> },
            { value: "Liquid", label: <>{t("Liquid")}</> },
          ]}
        />
      </div>
      <ErrorNotice>{query.error ? errorText(query.error) : ""}</ErrorNotice>
      {query.isPending ? (
        <p>{t("Carregando ativos…")}</p>
      ) : filtered.length ? (
        <HoldingsTable rows={filtered} />
      ) : (
        <p>{t("Nenhum ativo corresponde aos filtros.")}</p>
      )}
    </section>
  );
}
export function AssetPage({ data }: { data?: Snapshot }) {
  const t = useT();
  const buildNetwork = useNetwork();
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
        <h1>{t("Ativo")}</h1>
        <ErrorNotice>{query.error ? errorText(query.error) : ""}</ErrorNotice>
        <p>
          {query.isPending
            ? "Carregando…"
            : t("Ativo não encontrado nesta carteira.")}
        </p>
        <NavLink to="/assets">{t("Ver ativos")}</NavLink>
      </section>
    );
  const params = new URLSearchParams({
    chain: row.metadata.key.chain,
    asset: row.metadata.key.asset_id ?? "native",
  });
  return (
    <>
      <section className="card">
        <p className="eyebrow">
          {chain} {buildNetwork}
        </p>
        <h1>{row.metadata.ticker ?? t("Ativo não listado")}</h1>
        <h2>
          <HoldingValue row={row} mode="exact" />
        </h2>
        {row.metadata.key.asset_id && (
          <p className="mono wrap">{row.metadata.key.asset_id}</p>
        )}
        {row.metadata.approved ? (
          <div className="actions">
            <NavLink className="button primary" to={`/receive?${params}`}>
              {t("Receber")}
            </NavLink>
            <NavLink className="button" to={`/send?${params}`}>
              {t("Enviar")}
            </NavLink>
          </div>
        ) : (
          <div className="notice">
            {t(
              "Precisão desconhecida. Valores em unidades brutas. O envio deste ativo não é suportado nesta versão.",
            )}
          </div>
        )}
      </section>
      <section className="card section-gap">
        <h2>{t("Atividade do ativo")}</h2>
        <Activity
          rows={
            data?.activity.filter((t) =>
              t.movements.some(
                (m) =>
                  m.asset.chain === chain &&
                  (m.asset.asset_id ?? "native") === routeKey,
              ),
            ) ?? []
          }
        />
        <NavLink to="/history">{t("Abrir histórico")}</NavLink>
      </section>
    </>
  );
}
