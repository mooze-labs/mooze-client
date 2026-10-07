import { PageHeader } from "../../ui/page-header";
import { SendResult } from "./send-result";
import { selectSubmissionView } from "./submission-view";
import { SendDraftContext } from "./send-draft";
import { SendForm } from "./send-form";
import { SendReviewView } from "./send-review";
import { useT } from "../../i18n/messages";
import {
  useContext,
  useEffect,
  useReducer,
  useRef,
  useState,
  type FormEvent,
} from "react";
import { NavLink, useNavigate, useSearchParams } from "react-router-dom";
import type {
  AssetMetadataDto,
  AssetKeyDto,
} from "../../../../../crates/mooze-app/generated/types";
import type { DesktopClient } from "../../core/client";
import { errorText } from "../../core/client";
import type {
  SubmissionDto,
  FeeOptionsDto,
} from "../../core/desktop.generated";
import { ErrorNotice } from "../../ui";
import { formatBaseUnits, parseAssetAmount } from "./amount";
import { assetKey } from "../dashboard/holdings-model";
import { reduceSend } from "./send-state";
const btc: AssetMetadataDto = {
  key: { chain: "Bitcoin", asset_id: null },
  ticker: "BTC",
  precision: 8,
  approved: true,
};
type SendPageProps = {
  activity?: import("../../../../../crates/mooze-app/generated/types").WalletActivityDto[];
  client: DesktopClient;
  generation: number;
  onSent: () => void;
  submission?: SubmissionDto | null;
};
export function SendPage(props: SendPageProps) {
  return <SendSession key={props.generation} {...props} />;
}
function SendSession({
  client,
  generation,
  onSent,
  submission,
  activity = [],
}: SendPageProps) {
  const t = useT();
  const navigate = useNavigate();
  const [params] = useSearchParams();
  const { draft, save: saveDraft } = useContext(SendDraftContext);
  const [assets, setAssets] = useState<AssetMetadataDto[]>([btc]);
  const [selected, setSelected] = useState(
    () =>
      draft?.selected ??
      (params.get("chain") === "Liquid"
        ? `Liquid:${params.get("asset") ?? ""}`
        : assetKey(btc.key)),
  );
  const asset = assets.find((a) => assetKey(a.key) === selected);
  const ticker = asset?.ticker ?? "ativo";
  const [destination, setDestination] = useState(draft?.destination ?? "");
  const [amount, setAmount] = useState(draft?.amount ?? "");
  const [max, setMax] = useState(false);
  const [rate, setRate] = useState(
    draft?.rate ?? (selected.startsWith("Liquid:") ? "0,1" : "1"),
  );
  const [fees, setFees] = useState<FeeOptionsDto | null>(null);
  const [state, dispatch] = useReducer(reduceSend, { phase: "editing" });
  const [error, setError] = useState("");
  const [now, setNow] = useState(Date.now());
  const active = useRef(true);
  const lastReview = useRef<Awaited<
    ReturnType<DesktopClient["reviewSend"]>
  > | null>(null);
  const inFlight = useRef(false);
  const busy = state.phase === "preparing" || state.phase === "submitting";
  const review =
    state.phase === "reviewing" || state.phase === "submitting"
      ? state.review
      : null;
  useEffect(() => {
    active.current = true;
    let live = true;
    void client
      .approvedAssets()
      .then((a) => {
        if (!live) return;
        setAssets(a);
        if (params.get("chain") === "Liquid" && !params.get("asset")) {
          const lbtc = a.find((a) => a.ticker === "L-BTC");
          if (lbtc) setSelected(assetKey(lbtc.key));
        }
      })
      .catch((e) => {
        if (live) setError(errorText(e));
      });
    const timer = setInterval(() => setNow(Date.now()), 1000);
    return () => {
      active.current = false;
      live = false;
      clearInterval(timer);
    };
  }, [client, generation]);
  useEffect(() => {
    if (!asset) return;
    let live = true;
    setFees(null);

    void client
      .feeOptions(asset.key)
      .then((f) => {
        if (live) setFees(f);
      })
      .catch(() => {});
    return () => {
      live = false;
    };
  }, [client, selected, assets]);
  function changeAsset(next: string) {
    setSelected(next);
    setMax(false);
    setRate(next.startsWith("Liquid:") ? "0,1" : "1");
  }
  function name(key: AssetKeyDto) {
    return (
      assets.find((a) => assetKey(a.key) === assetKey(key))?.ticker ??
      key.asset_id ??
      "BTC"
    );
  }
  async function applyRequest() {
    if (inFlight.current) return;
    setError("");
    try {
      const parsed = await client.parsePaymentRequest(destination);
      setDestination(parsed.address);
      if (parsed.asset) changeAsset(assetKey(parsed.asset));
      else if (parsed.chain === "Liquid") setSelected("");
      if (parsed.amount_units)
        setAmount(formatBaseUnits(BigInt(parsed.amount_units)));
      setMax(false);
      dispatch({ type: "edit" });
    } catch (e) {
      setError(errorText(e));
    }
  }
  async function estimate(e: FormEvent) {
    e.preventDefault();
    if (inFlight.current) return;
    setError("");
    if (!asset) {
      setError(t("Selecione explicitamente o ativo a enviar."));
      return;
    }
    const parsed = parseAssetAmount(amount);
    if (!max && !parsed.ok) {
      setError(t("Informe um valor positivo com até 8 casas decimais."));
      return;
    }
    const fee = Number(rate.replace(",", "."));
    if (!/^\d+([.,]\d+)?$/.test(rate) || !Number.isFinite(fee) || fee <= 0) {
      setError(t("Informe uma taxa válida em sat/vB."));
      return;
    }
    inFlight.current = true;
    dispatch({ type: "prepare" });
    try {
      const result = await client.reviewSend({
        asset: asset.key,
        destination,
        amount: max
          ? { mode: "Max" }
          : { mode: "Exact", units: parsed.ok ? parsed.value.toString() : "0" },
        fee_rate_sat_per_vbyte: fee,
      });
      if (active.current) {
        lastReview.current = result;
        dispatch({ type: "reviewed", review: result });
      }
    } catch (e) {
      if (active.current) dispatch({ type: "failed", message: errorText(e) });
    } finally {
      inFlight.current = false;
    }
  }
  async function send() {
    if (!review || inFlight.current || now >= review.expires_at_ms) return;
    inFlight.current = true;
    dispatch({ type: "confirm" });
    try {
      const result = await client.confirmSend(review.id);
      if (active.current) dispatch({ type: "submitted", txid: result.tx_id });
    } catch (e) {
      const uncertain =
        !(e && typeof e === "object" && "code" in e) ||
        ["submission_unknown", "transport"].includes(
          String((e as { code?: string }).code),
        );
      if (active.current)
        dispatch({
          type: uncertain ? "uncertain" : "failed",
          message: errorText(e),
        });
    } finally {
      inFlight.current = false;
      onSent();
    }
  }
  async function acknowledge() {
    if (inFlight.current) return;
    try {
      await client.acknowledgeSubmission();
      saveDraft(null);
      setAmount("");
      setDestination("");
      dispatch({ type: "submitted", txid: "" });
      dispatch({ type: "edit" });
      onSent();
    } catch (e) {
      setError(errorText(e));
    }
  }
  const uncertain =
    state.phase === "uncertain" ||
    submission?.phase === "uncertain" ||
    submission?.phase === "submitting";
  const sent =
    (state.phase === "submitted" && state.txid) ||
    (submission?.phase === "sent" && submission.tx_id);
  const journal: SubmissionDto | null =
    submission ??
    (sent || uncertain
      ? {
          version: 2,
          phase: uncertain ? "uncertain" : "sent",
          chain:
            lastReview.current?.request.asset.chain === "Liquid"
              ? "Liquid"
              : "Bitcoin",
          tx_id: sent ? String(sent) : null,
          request: lastReview.current?.request ?? null,
          debits: lastReview.current?.debits ?? null,
        }
      : null);
  const result = selectSubmissionView(
    { generation, submission: journal, activity, sync: null, chains: [] },
    lastReview.current,
  );
  return (
    <section className="flow-page transaction-page">
      <PageHeader title={t("Envie da sua carteira")} />
      <div className="send-layout focused-flow">
        <section className="card">
          <ErrorNotice>
            {error ||
              (state.phase === "failed" || state.phase === "uncertain"
                ? state.message
                : "")}
          </ErrorNotice>
          {!review && !sent && !uncertain && asset?.key.chain === "Liquid" && (
            <div className="fee-guidance">
              <p>
                {t(
                  "Transferências Liquid pagam taxas em L-BTC, independentemente do ativo enviado.",
                )}
              </p>
              <NavLink
                onClick={() =>
                  saveDraft({ selected, destination, amount, rate })
                }
                to={`/receive?chain=Liquid&asset=${encodeURIComponent(assets.find((a) => a.ticker === "L-BTC")?.key.asset_id ?? "")}`}
              >
                {t("Receber L-BTC")}
              </NavLink>
            </div>
          )}
          {result ? (
            <SendResult
              assets={assets}
              view={result}
              name={name}
              reviewFee={lastReview.current?.fee_sat}
              busy={submission?.phase === "submitting"}
              onCheck={() =>
                void client
                  .refresh()
                  .then(onSent)
                  .catch((e) => setError(errorText(e)))
              }
              onViewTransaction={() =>
                navigate(
                  result.txid
                    ? `/history?chain=${result.chain}&tx=${encodeURIComponent(result.txid)}`
                    : "/history",
                )
              }
              onReturn={() => navigate("/")}
              onNew={() => void acknowledge()}
            />
          ) : review ? (
            <SendReviewView
              assets={assets}
              review={review}
              busy={busy}
              expiresAtMs={review.expires_at_ms}
              nowMs={now}
              name={name}
              onEdit={() => {
                setMax(false);
                dispatch({ type: "edit" });
              }}
              onConfirm={() => void send()}
            />
          ) : (
            <SendForm
              onReview={estimate}
              onEdit={() => dispatch({ type: "edit" })}
              onReadRequest={() => void applyRequest()}
              busy={busy}
              selected={selected}
              setSelected={changeAsset}
              setMax={setMax}
              assets={assets}
              destination={destination}
              setDestination={setDestination}
              amount={amount}
              setAmount={setAmount}
              max={max}
              rate={rate}
              setRate={setRate}
              fees={fees}
              ticker={ticker}
            />
          )}
        </section>
      </div>
    </section>
  );
}
