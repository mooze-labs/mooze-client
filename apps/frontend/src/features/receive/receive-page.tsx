import { SelectField } from "../../ui/select-field";
import { RequestPanel } from "./request-panel";
import { useT } from "../../i18n/messages";
import { useState } from "react";
import { useQuery } from "@tanstack/react-query";
import { useSearchParams } from "react-router-dom";
import { useWalletClient } from "../../app/client-context";
import { useWalletSession } from "../../app/session-provider";
import { assetKey } from "../dashboard/holdings-model";
import { parseAssetAmount } from "../send/amount";
import { Field, ErrorNotice } from "../../ui";
import { errorText } from "../../core/client";
export function ReceivePage() {
  const t = useT();
  const client = useWalletClient();
  const { session } = useWalletSession();
  const [params] = useSearchParams();
  const catalog = useQuery({
    queryKey: ["wallet", session?.generation, "approvedAssets"],
    queryFn: () => client.approvedAssets(),
  });
  const [selected, setSelected] = useState(
    params.get("asset")
      ? `${params.get("chain")}:${params.get("asset")}`
      : "Bitcoin:native",
  );
  const asset = catalog.data?.find((a) => assetKey(a.key) === selected);
  const [amount, setAmount] = useState("");
  const [description, setDescription] = useState("");
  const parsed = amount.trim() ? parseAssetAmount(amount) : null;
  const invalid = parsed !== null && !parsed.ok;
  const units = parsed?.ok ? parsed.value.toString() : null;
  const request = useQuery({
    queryKey: [
      "wallet",
      session?.generation,
      "receiveRequest",
      selected,
      units,
      description,
    ],
    enabled: !!asset && !invalid,
    queryFn: () =>
      client.receiveRequest(asset!.key, units, description || null),
  });
  return (
    <section className="receive-card flow-page">
      <h1>{t("Receba na sua carteira")}</h1>
      <div className="receive-columns">
        <div>
          <SelectField
            label={t("Ativo")}
            value={selected}
            onValueChange={(value) => {
              setSelected(value);
            }}
            items={[
              ...(catalog.data?.map((a) => ({
                value: String(assetKey(a.key)),
                label: (
                  <>
                    {a.ticker} · {a.key.chain} {t("Testnet")}
                  </>
                ),
              })) ?? []),
            ]}
          />
          <Field
            label={t("Quantidade solicitada (opcional)")}
            inputMode="decimal"
            value={amount}
            onChange={(e) => {
              setAmount(e.target.value);
            }}
          />
          <Field
            label={t("Descrição (opcional)")}
            value={description}
            maxLength={512}
            onChange={(e) => {
              setDescription(e.target.value);
            }}
          />
          <ErrorNotice>
            {invalid
              ? t("Informe um valor positivo com até 8 casas decimais.")
              : request.error
                ? errorText(request.error)
                : catalog.error
                  ? errorText(catalog.error)
                  : ""}
          </ErrorNotice>
          {asset?.key.asset_id && (
            <details className="asset-identity">
              <summary>{t("ID do ativo:")}</summary>
              <p className="small mono wrap">{asset.key.asset_id}</p>
            </details>
          )}
          <p className="small muted">
            {asset?.key.chain === "Liquid"
              ? t(
                  "Um endereço Liquid pode receber vários ativos. O pedido de pagamento identifica o ativo solicitado.",
                )
              : t("Envie apenas BTC de teste nesta rede.")}
          </p>
        </div>
        <div className="receive-output">
          <p className="muted">
            {asset?.key.chain} {t("Testnet ·")} {asset?.ticker}
          </p>
          <RequestPanel
            key={`${selected}:${units}:${description}`}
            request={invalid ? null : (request.data ?? null)}
            busy={!invalid && request.isPending}
            error={request.error ? errorText(request.error) : ""}
            onRetry={() => void request.refetch()}
          />
        </div>
      </div>
    </section>
  );
}
