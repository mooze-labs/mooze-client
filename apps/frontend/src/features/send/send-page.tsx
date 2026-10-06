import { useEffect, useState, useRef, type FormEvent } from "react";
import { useSearchParams } from "react-router-dom";
import { ArrowUpRight, CheckCircle, Info } from "lucide-react";
import type { DesktopClient, Chain, Review } from "../../core/client";
import type { SubmissionDto } from "../../core/desktop.generated";
import { errorText } from "../../core/client";
import { parseNativeAmount, formatBaseUnits } from "./amount";
import { Button, Field, ErrorNotice } from "../../ui";
export function SendPage({
  client,
  generation,
  onSent,
  submission,
}: {
  client: DesktopClient;
  generation: number;
  onSent: () => void;
  submission?: SubmissionDto | null;
}) {
  const [params] = useSearchParams();
  const [chain, setChain] = useState<Chain>(
    params.get("chain") === "Liquid" ? "Liquid" : "Bitcoin",
  );
  const [destination, setDestination] = useState("");
  const [amount, setAmount] = useState("");
  const [rate, setRate] = useState(chain === "Liquid" ? "0,1" : "1");
  const [review, setReview] = useState<Review | null>(null);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState("");
  const [txid, setTxid] = useState("");
  const [uncertain, setUncertain] = useState(false);
  const [now, setNow] = useState(Date.now());
  const active = useRef(true);
  const submitting = useRef(false);
  useEffect(() => {
    active.current = true;
    const timer = setInterval(() => setNow(Date.now()), 1000);
    return () => {
      active.current = false;
      clearInterval(timer);
    };
  }, [generation]);
  async function acknowledge() {
    try {
      await client.acknowledgeSubmission();
      setTxid("");
      setUncertain(false);
      setReview(null);
      setAmount("");
      setDestination("");
      onSent();
    } catch (e) {
      setError(errorText(e));
    }
  }
  async function estimate(e: FormEvent) {
    e.preventDefault();
    if (submitting.current) return;
    setError("");
    const parsed = parseNativeAmount(amount);
    if (!parsed.ok) {
      setError(
        "Informe um valor positivo com até 8 casas decimais, usando vírgula.",
      );
      return;
    }
    const fee = Number(rate.replace(",", "."));
    if (!/^\d+(,\d+)?$/.test(rate) || !Number.isFinite(fee) || fee <= 0) {
      setError("Informe uma taxa válida em sat/vB.");
      return;
    }
    submitting.current = true;
    setBusy(true);
    try {
      const r = await client.reviewSend({
        chain,
        destination: destination.trim(),
        amount_sat: Number(parsed.value),
        fee_rate_sat_per_vbyte: fee,
      });
      if (active.current && r.generation === generation) setReview(r);
    } catch (e) {
      if (active.current) setError(errorText(e));
    } finally {
      submitting.current = false;
      if (active.current) setBusy(false);
    }
  }
  async function send() {
    if (!review || submitting.current || now >= review.expires_at_ms) return;
    submitting.current = true;
    setBusy(true);
    setError("");
    try {
      const r = await client.confirmSend(review.id);
      if (active.current) {
        setTxid(r.tx_id);
        setReview(null);
      }
    } catch (e) {
      if (active.current) {
        setError(errorText(e));
        setReview(null);
        if (
          e &&
          typeof e === "object" &&
          "code" in e &&
          (e.code === "submission_unknown" || e.code === "transport")
        )
          setUncertain(true);
      }
    } finally {
      onSent();
      submitting.current = false;
      if (active.current) setBusy(false);
    }
  }
  const ticker = chain === "Bitcoin" ? "BTC" : "L-BTC";
  return (
    <>
      <div className="page-heading">
        <div>
          <p className="eyebrow">ENVIAR · TESTNET</p>
          <h1>Envie com clareza</h1>
          <p className="muted">Revise o destino e a taxa antes de confirmar.</p>
        </div>
      </div>
      <div className="send-layout">
        <section className="card">
          <ErrorNotice>{error}</ErrorNotice>
          {(submission?.phase === "sent" ? submission.tx_id : txid) ? (
            <>
              <CheckCircle className="success-mark" size={36} />
              <h2>Transação enviada</h2>
              <p className="muted">Aguardando confirmação da rede.</p>
              <p className="mono wrap">{submission?.tx_id ?? txid}</p>
              <Button onClick={() => void acknowledge()}>Novo envio</Button>
            </>
          ) : uncertain ||
            submission?.phase === "uncertain" ||
            submission?.phase === "submitting" ? (
            <>
              <h2>Verificando o resultado</h2>
              <p>
                O envio pode ter chegado à rede. Confira o histórico antes de
                iniciar outra transação.
              </p>
              <Button
                onClick={() =>
                  void client
                    .refresh()
                    .then(onSent)
                    .catch((e) => setError(errorText(e)))
                }
              >
                Atualizar histórico
              </Button>
              <Button
                disabled={busy || submission?.phase === "submitting"}
                onClick={() => void acknowledge()}
              >
                Conferi o histórico. Preparar outro envio
              </Button>
            </>
          ) : review ? (
            <>
              <p className="eyebrow">REVISÃO DO ENVIO</p>
              <h2>Confirme os detalhes</h2>
              <div className="review-row">
                <span>Rede</span>
                <span>{chain} Testnet</span>
              </div>
              <div className="review-row">
                <span>Destino</span>
                <span className="review-address">
                  {review.request.destination}
                </span>
              </div>
              <div className="review-row">
                <span>Quantidade</span>
                <span className="mono">
                  {formatBaseUnits(BigInt(review.request.amount_sat))} {ticker}
                </span>
              </div>
              <div className="review-row">
                <span>Taxa máxima aprovada</span>
                <span className="mono">
                  {formatBaseUnits(BigInt(review.fee_sat))} {ticker}
                </span>
              </div>
              <div className="review-row review-total">
                <span>Total máximo</span>
                <span className="mono">
                  {formatBaseUnits(BigInt(review.total_sat))}
                </span>
              </div>
              <p className="muted small">
                {now >= review.expires_at_ms
                  ? "Revisão expirada. Volte e revise novamente."
                  : `Revisão válida por ${Math.max(0, Math.ceil((review.expires_at_ms - now) / 1000))} segundos.`}
              </p>
              <div className="actions">
                <Button disabled={busy} onClick={() => setReview(null)}>
                  Editar
                </Button>
                <Button
                  className="primary"
                  disabled={busy || now >= review.expires_at_ms}
                  onClick={() => void send()}
                >
                  <ArrowUpRight size={16} />
                  {busy ? "Enviando…" : "Confirmar envio"}
                </Button>
              </div>
            </>
          ) : (
            <form onSubmit={estimate}>
              <label className="field">
                <span>Ativo e rede</span>
                <select
                  disabled={busy}
                  value={chain}
                  onChange={(e) => {
                    setChain(e.target.value as Chain);
                    setRate(e.target.value === "Liquid" ? "0,1" : "1");
                  }}
                >
                  <option value="Bitcoin">BTC · Bitcoin Testnet</option>
                  <option value="Liquid">L-BTC · Liquid Testnet</option>
                </select>
              </label>
              <Field
                label="Endereço de destino"
                value={destination}
                onChange={(e) => setDestination(e.target.value)}
                required
                disabled={busy}
                autoComplete="off"
                spellCheck={false}
              />
              <Field
                label={`Quantidade (${ticker})`}
                value={amount}
                onChange={(e) => setAmount(e.target.value)}
                inputMode="decimal"
                help="Use vírgula para decimais, sem separador de milhar."
                required
                disabled={busy}
              />
              <Field
                label="Taxa da rede (sat/vB)"
                value={rate}
                onChange={(e) => setRate(e.target.value)}
                help="Valor inicial editável; não é uma recomendação de taxa em tempo real."
                inputMode="decimal"
                required
                disabled={busy}
              />
              <Button type="submit" className="primary wide" disabled={busy}>
                {busy ? "Calculando taxa…" : "Revisar envio"}
              </Button>
            </form>
          )}
        </section>
        <section className="card">
          <Info size={20} className="muted" />
          <h3 className="section-gap">Você mantém o controle</h3>
          <p className="muted">
            O aplicativo verifica a rede do endereço e a taxa antes de assinar.
          </p>
          <hr />
          <p className="small muted">
            Esta versão utiliza somente Bitcoin Testnet e Liquid Testnet. Os
            ativos de teste não têm valor monetário.
          </p>
        </section>
      </div>
    </>
  );
}
