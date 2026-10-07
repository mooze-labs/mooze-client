import { useNetwork } from "../../core/network";
import { Input } from "../../ui/input";
import { SelectField } from "../../ui/select-field";
import { usePreferences } from "../../i18n/preferences";
import { useT } from "../../i18n/messages";
import { useState } from "react";
import { useSearchParams } from "react-router-dom";
import type { Snapshot } from "../../core/client";
import { useWalletHoldings } from "../../app/session-provider";
import { Button, Modal } from "../../ui";
import { Activity, Movement, statusText } from "./activity";
import {
  filterActivity,
  type ActivityFilter,
  direction,
} from "./activity-model";
import { assetKey } from "../dashboard/holdings-model";
export function HistoryPage({ data }: { data?: Snapshot }) {
  const t = useT();
  const network = useNetwork();
  const { preferences } = usePreferences();
  const [filter, setFilter] = useState<ActivityFilter>({});
  const [params, setParams] = useSearchParams();
  const [copied, setCopied] = useState("");
  const holdings = useWalletHoldings();
  const rows = filterActivity(data?.activity ?? [], filter);
  const selected = data?.activity.find(
    (t) => t.id === params.get("tx") && t.chain === params.get("chain"),
  );
  const field = (key: keyof ActivityFilter, value: string) =>
    setFilter((old) => ({ ...old, [key]: value || undefined }));
  return (
    <section className="history-page">
      <h1>{t("Atividade")}</h1>
      {params.get("tx") && !selected && (
        <div className="notice">
          <p>{t("Aguardando dados desta transação.")}</p>
          <p className="mono wrap small">{params.get("tx")}</p>
        </div>
      )}
      <details className="filter-disclosure">
        <summary>
          {Object.values(filter).filter(Boolean).length
            ? t("Filtros ({count})", {
                count: Object.values(filter).filter(Boolean).length,
              })
            : t("Filtros")}
        </summary>
        <div className="history-filters">
          <SelectField
            label={t("Ativo")}
            value={filter.asset ?? ""}
            onValueChange={(value) => field("asset", value)}
            items={[
              { value: "", label: <>{t("Todos os ativos")}</> },
              ...(holdings.data?.holdings.map((h) => ({
                value: String(assetKey(h.metadata.key)),
                label: <>{h.metadata.ticker ?? h.metadata.key.asset_id}</>,
              })) ?? []),
            ]}
          />
          <SelectField
            label={t("Rede")}
            value={filter.network ?? ""}
            onValueChange={(value) => field("network", value)}
            items={[
              { value: "", label: <>{t("Todas as redes")}</> },
              { value: "Bitcoin", label: <>{t("Bitcoin")}</> },
              { value: "Liquid", label: <>{t("Liquid")}</> },
            ]}
          />
          <SelectField
            label={t("Status")}
            value={filter.status ?? ""}
            onValueChange={(value) => field("status", value)}
            items={[
              { value: "", label: <>{t("Todos os status")}</> },
              { value: "Pending", label: <>{t("Pendente")}</> },
              { value: "Confirmed", label: <>{t("Confirmado")}</> },
              { value: "Failed", label: <>{t("Falhou")}</> },
            ]}
          />
          <SelectField
            label={t("Direção")}
            value={filter.direction ?? ""}
            onValueChange={(value) => field("direction", value)}
            items={[
              { value: "", label: <>{t("Todas")}</> },
              { value: "Incoming", label: <>{t("Recebido")}</> },
              { value: "Outgoing", label: <>{t("Enviado")}</> },
              {
                value: "SelfTransfer",
                label: <>{t("Transferência própria")}</>,
              },
            ]}
          />
          <label className="field">
            {t("De")}
            <Input
              type="date"
              value={filter.from ?? ""}
              onChange={(e) => field("from", e.target.value)}
            />
          </label>
          <label className="field">
            {t("Até")}
            <Input
              type="date"
              value={filter.to ?? ""}
              onChange={(e) => field("to", e.target.value)}
            />
          </label>
        </div>
        <Button className="ghost" onClick={() => setFilter({})}>
          {t("Limpar filtros")}
        </Button>
      </details>
      {!data ? (
        <p>{t("Histórico indisponível enquanto a carteira carrega.")}</p>
      ) : !rows.length ? (
        <p>
          {data.activity.length
            ? t("Nenhuma transação corresponde aos filtros.")
            : t("Nenhuma transação por enquanto.")}
        </p>
      ) : (
        <Activity rows={rows} />
      )}
      <Modal
        title={t("Detalhes da transação")}
        className="history-panel"
        open={!!selected}
        onOpenChange={(open) => {
          if (!open) setParams({});
        }}
      >
        {selected && (
          <>
            <p>
              {selected.chain} {network + " ·"} {t(statusText(selected))}
            </p>
            <p>
              {t("Confirmações:")}
              {selected.confirmations}
            </p>
            <p>
              {selected.timestamp_ms
                ? new Date(selected.timestamp_ms).toLocaleString(
                    preferences.locale,
                  )
                : t("Data indisponível")}
            </p>
            <p className="mono wrap">{selected.id}</p>
            <Button
              onClick={() =>
                void navigator.clipboard
                  .writeText(selected.id)
                  .then(() => setCopied(t("ID copiado")))
                  .catch(() => setCopied(t("Não foi possível copiar.")))
              }
            >
              {t("Copiar ID")}
            </Button>
            <p role="status">{copied}</p>
            <h3>{t("Movimentações (sem taxa)")}</h3>
            {selected.movements.map((m) => (
              <div key={assetKey(m.asset)}>
                <Movement mode="exact" asset={m.asset} units={m.delta_units} />
                {m.asset.asset_id && (
                  <p className="small mono wrap">{m.asset.asset_id}</p>
                )}
              </div>
            ))}
            <h3>{t("Taxa debitada da carteira")}</h3>
            {selected.fee ? (
              <Movement
                mode="exact"
                asset={selected.fee.asset}
                units={selected.fee.units}
              />
            ) : (
              <p>{t("Indisponível ou paga pelo remetente.")}</p>
            )}
            <h3>{t("Endereços")}</h3>
            {selected.addresses.length ? (
              selected.addresses.map((a) => (
                <p className="mono wrap" key={a}>
                  {a}
                </p>
              ))
            ) : (
              <p>{t("Indisponíveis nesta transação.")}</p>
            )}
            <Button onClick={() => setParams({})}>{t("Fechar")}</Button>
          </>
        )}
      </Modal>
    </section>
  );
}
