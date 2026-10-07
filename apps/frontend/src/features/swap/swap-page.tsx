import { FlowStep } from "../../ui/flow-step";
import { PageHeader } from "../../ui/page-header";
import { ArrowDownUp, Layers2 } from "lucide-react";
import { useEffect, useRef, useState } from "react";
import { useQuery, useQueryClient } from "@tanstack/react-query";
import { useWalletClient } from "../../app/client-context";
import { useWalletSession } from "../../app/session-provider";
import { useT } from "../../i18n/messages";
import { Button, ErrorNotice } from "../../ui";
import { Input } from "../../ui/input";
import { AssetMark } from "../../ui/asset-mark";
import { SensitiveValue } from "../../ui/sensitive-value";
import { SelectField } from "../../ui/select-field";
import { errorText } from "../../core/client";
import { formatBaseUnits, parseAssetAmount } from "../send/amount";
import { SwapReview } from "./swap-review";
import { SwapResult } from "./swap-result";
import { LoadingRows } from "../../ui/loading-rows";
import { useNow } from "../../ui/use-now";
import { canConfirm } from "./swap-state";
export function SwapPage() {
  const t = useT();
  const client = useWalletClient();
  const { session } = useWalletSession();
  const qc = useQueryClient();
  const prefix = ["wallet", session?.generation];
  const key = [...prefix, "swap"];
  const host = useQuery({
    queryKey: ["host"],
    queryFn: () => client.hostInfo(),
  });
  const enabled = host.data?.swaps_enabled === true;
  const markets = useQuery({
    queryKey: [...prefix, "swapMarkets"],
    queryFn: () => client.swapMarkets(),
    enabled,
    retry: false,
  });
  const catalog = useQuery({
    queryKey: [...prefix, "approvedAssets"],
    queryFn: () => client.approvedAssets(),
    enabled,
  });
  const holdings = useQuery({
    queryKey: [...prefix, "holdings"],
    queryFn: () => client.holdings(),
    enabled,
  });
  const state = useQuery({
    queryKey: key,
    queryFn: () => client.swapStatus(),
    enabled,
    refetchInterval: 1000,
    retry: false,
  });
  const [reviewing, setReviewing] = useState(false);
  const [reviewAllowed, setReviewAllowed] = useState(false);
  const [send, setSend] = useState("");
  const [receive, setReceive] = useState("");
  const [amount, setAmount] = useState("");
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState("");
  const now = useNow();
  const quoteQueue = useRef<Promise<void>>(Promise.resolve());
  const immediateQuote = useRef(false);
  const [quoteRequest, setQuoteRequest] = useState(0);
  const [quoting, setQuoting] = useState(false);
  const source = send || markets.data?.[0]?.base_asset_id || "";
  const destinations =
    markets.data?.flatMap((m) =>
      m.base_asset_id === source
        ? [m.quote_asset_id]
        : m.quote_asset_id === source
          ? [m.base_asset_id]
          : [],
    ) ?? [];
  const target = destinations.includes(receive)
    ? receive
    : destinations[0] || "";
  const ids = [
    ...new Set(
      markets.data?.flatMap((m) => [m.base_asset_id, m.quote_asset_id]) ?? [],
    ),
  ];
  const asset = (id: string) =>
    catalog.data?.find((a) => a.key.asset_id === id);
  const ticker = (id: string) =>
    catalog.data?.find((a) => a.key.asset_id === id)?.ticker || id;
  const assetLabel = (id: string) => {
    const metadata = catalog.data?.find((a) => a.key.asset_id === id);
    return (
      <span className="swap-asset-label">
        {metadata && <AssetMark metadata={metadata} />}
        <span>{ticker(id)}</span>
      </span>
    );
  };
  const parsed = parseAssetAmount(amount);
  const balance = holdings.data?.holdings.find(
    (h) => h.metadata.key.asset_id === source,
  )?.balance_units;
  const exceeds =
    parsed.ok && balance !== undefined && parsed.value > BigInt(balance);
  const submitted = ["Submitting", "Succeeded", "Uncertain"].includes(
    state.data?.phase || "",
  );
  // Serialize subscription changes: a slow start must finish before its stop
  // and replacement. Cleanup also prevents obsolete responses updating the UI.
  useEffect(() => {
    setReviewAllowed(false);
    setQuoting(false);
    if (!enabled || submitted) return;
    let active = true;
    const queryKey = ["wallet", session?.generation, "swap"];
    const delay = immediateQuote.current ? 0 : 800;
    immediateQuote.current = false;
    const validAmount = parseAssetAmount(amount);
    const timer =
      validAmount.ok && !exceeds && source && target
        ? setTimeout(() => {
            setQuoting(true);
            setError("");
            quoteQueue.current = quoteQueue.current.then(async () => {
              if (!active) return;
              try {
                await qc.cancelQueries({ queryKey });
                if (!active) return;
                const next = await client.swapStart({
                  send_asset_id: source,
                  receive_asset_id: target,
                  amount_units: validAmount.value.toString(),
                });
                if (!active) return;
                await qc.cancelQueries({ queryKey });
                if (!active) return;
                qc.setQueryData(queryKey, next);
                setReviewAllowed(true);
              } catch (e) {
                if (active) setError(errorText(e));
              } finally {
                if (active) setQuoting(false);
              }
            });
          }, delay)
        : undefined;
    return () => {
      active = false;
      clearTimeout(timer);
      quoteQueue.current = quoteQueue.current.then(async () => {
        try {
          await client.swapStop();
        } catch {
          // Best effort on navigation; the next start replaces the subscription.
        }
      });
    };
  }, [
    amount,
    source,
    target,
    enabled,
    exceeds,
    submitted,
    client,
    qc,
    session?.generation,
    quoteRequest,
  ]);
  const currentReview =
    reviewAllowed &&
    state.data?.phase === "Review" &&
    state.data.review?.send_asset_id === source &&
    state.data.review.receive_asset_id === target
      ? state.data.review
      : undefined;
  function reverse() {
    setSend(target);
    setReceive(source);
    setAmount("");
    stopEditing();
  }
  function stopEditing() {
    setReviewing(false);
    setReviewAllowed(false);
    setError("");
  }
  function quote() {
    if (!parsed.ok || busy || quoting || exceeds || !source || !target) return;
    immediateQuote.current = true;
    setQuoteRequest((value) => value + 1);
  }
  async function confirm() {
    const review = state.data?.review;
    if (!reviewAllowed || !review || !canConfirm(state.data, Date.now(), busy))
      return;
    setBusy(true);
    setError("");
    try {
      await qc.cancelQueries({ queryKey: key });
      qc.setQueryData(key, await client.swapConfirm(review.id));
      await qc.invalidateQueries({ queryKey: [...prefix, "holdings"] });
    } catch (e) {
      setError(errorText(e));
      await state.refetch();
    } finally {
      setBusy(false);
    }
  }
  if (host.isPending) return <p>{t("Carregando…")}</p>;
  if (!enabled)
    return (
      <section>
        <h1>{t("Trocar ativos")}</h1>
        <p>
          {t(
            host.data?.network === "Testnet"
              ? "Trocas indisponíveis nesta rede."
              : "Trocas indisponíveis no momento.",
          )}
        </p>
        <ErrorNotice>{host.error ? errorText(host.error) : ""}</ErrorNotice>
      </section>
    );
  return (
    <section className="flow-page transaction-page">
      <PageHeader
        title={t("Trocar ativos")}
        description={t("Troque ativos Liquid com cotação em tempo real.")}
      />
      <ErrorNotice>
        {error ||
          (markets.error ? errorText(markets.error) : "") ||
          (state.error ? errorText(state.error) : "")}
      </ErrorNotice>
      {submitted && state.data ? (
        <SwapResult
          state={state.data}
          asset={asset}
          busy={busy}
          onNew={() => {
            setBusy(true);
            void client
              .swapAcknowledge()
              .then(() => state.refetch())
              .catch((e) => setError(errorText(e)))
              .finally(() => setBusy(false));
          }}
        />
      ) : (
        <FlowStep
          className="swap-container"
          step={reviewing && currentReview ? "review" : "edit"}
        >
          {reviewing && currentReview ? (
            <div className="flow-step" key="review">
              <SwapReview
                review={currentReview}
                asset={asset}
                now={now}
                enabled={reviewAllowed && canConfirm(state.data, now, busy)}
                confirm={() => void confirm()}
              />
              <div className="flow-actions">
                <Button disabled={busy} onClick={() => setReviewing(false)}>
                  {t("Editar troca")}
                </Button>
                {currentReview.expires_at_ms <= now && (
                  <Button
                    disabled={busy || quoting}
                    onClick={() => {
                      setReviewing(false);
                      quote();
                    }}
                  >
                    {t("Obter cotação")}
                  </Button>
                )}
              </div>
            </div>
          ) : (
            <form
              className="card swap-card flow-step"
              onSubmit={(e) => {
                e.preventDefault();
                if (currentReview && canConfirm(state.data, Date.now(), busy)) {
                  setReviewing(true);
                } else quote();
              }}
            >
              <div className="swap-card-heading">
                <h2>{t("Trocar")}</h2>
                <span className="swap-network">
                  <Layers2 size={14} /> Liquid
                </span>
              </div>
              <div className="swap-token-panel">
                <label className="swap-panel-label" htmlFor="swap-send-amount">
                  {t("Você envia")}
                </label>
                <div className="swap-token-row">
                  <Input
                    id="swap-send-amount"
                    className="swap-amount-input"
                    aria-label={t("Quantidade a trocar")}
                    aria-describedby="swap-amount-guidance"
                    aria-invalid={!!amount && (!parsed.ok || exceeds)}
                    inputMode="decimal"
                    placeholder="0"
                    autoComplete="off"
                    value={amount}
                    disabled={busy}
                    onChange={(e) => {
                      setAmount(e.target.value);
                      stopEditing();
                    }}
                  />
                  <SelectField
                    className="swap-asset-select"
                    label={t("Ativo de origem")}
                    value={source}
                    items={ids.map((id) => ({
                      value: id,
                      label: assetLabel(id),
                    }))}
                    disabled={busy}
                    onValueChange={(id) => {
                      setSend(id);
                      stopEditing();
                    }}
                  />
                </div>
                <div className="swap-balance muted small">
                  {t("Saldo disponível")}:{" "}
                  <SensitiveValue>
                    {balance === undefined
                      ? "—"
                      : formatBaseUnits(BigInt(balance))}{" "}
                    {ticker(source)}
                  </SensitiveValue>
                </div>
              </div>
              <div className="swap-direction-wrap">
                <Button
                  type="button"
                  variant="outline"
                  size="icon"
                  className="swap-direction"
                  aria-label={t("Inverter ativos")}
                  disabled={busy || !source || !target}
                  onClick={reverse}
                >
                  <ArrowDownUp size={18} />
                </Button>
              </div>
              <div className="swap-token-panel">
                <span className="swap-panel-label">{t("Você recebe")}</span>
                <div className="swap-token-row">
                  <output
                    className="swap-receive-amount"
                    aria-label={t("Quantidade a receber")}
                    aria-live="polite"
                  >
                    <SensitiveValue>
                      {currentReview && currentReview.expires_at_ms > now
                        ? formatBaseUnits(BigInt(currentReview.receive_units))
                        : "—"}
                    </SensitiveValue>
                  </output>
                  <SelectField
                    className="swap-asset-select"
                    label={t("Ativo de destino")}
                    value={target}
                    items={destinations.map((id) => ({
                      value: id,
                      label: assetLabel(id),
                    }))}
                    disabled={busy}
                    onValueChange={(id) => {
                      setReceive(id);
                      stopEditing();
                    }}
                  />
                </div>
                <p className="muted small">
                  {t("O valor será atualizado com a cotação.")}
                </p>
              </div>
              <p
                id="swap-amount-guidance"
                className="form-guidance small"
                data-invalid={exceeds || (!!amount && !parsed.ok)}
              >
                {exceeds
                  ? t("Saldo insuficiente.")
                  : !amount
                    ? t("Informe a quantidade para obter uma cotação.")
                    : !parsed.ok
                      ? t(
                          "Informe uma quantidade válida, com até oito casas decimais.",
                        )
                      : !source || !target
                        ? t("Escolha os ativos da troca.")
                        : t("Você revisará os valores antes de confirmar.")}
              </p>
              <Button
                type="submit"
                variant="default"
                className="swap-primary-action primary"
                disabled={
                  busy || quoting || !parsed.ok || !source || !target || exceeds
                }
              >
                {t(
                  busy || quoting
                    ? "Aguarde…"
                    : currentReview && canConfirm(state.data, now, busy)
                      ? "Revisar troca"
                      : "Obter cotação",
                )}
              </Button>
              {markets.isPending && <p>{t("Carregando mercados…")}</p>}
              {markets.data?.length === 0 && (
                <p>{t("Nenhum mercado disponível.")}</p>
              )}
            </form>
          )}
          <div className="swap-quote-details">
            {state.data?.phase === "Quoting" && (
              <div className="card quote-loading">
                <LoadingRows label={t("Aguardando cotação…")} rows={2} />
              </div>
            )}
            {state.data?.message && (
              <ErrorNotice>{state.data.message}</ErrorNotice>
            )}
            {state.data?.phase === "Expired" && !currentReview && (
              <p>{t("Cotação expirada. Solicite uma nova cotação.")}</p>
            )}
          </div>
        </FlowStep>
      )}
    </section>
  );
}
