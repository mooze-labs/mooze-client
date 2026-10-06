import { useState, useEffect, useRef, type FormEvent } from "react";
import type { DesktopClient, Session } from "../../core/client";
import { errorText } from "../../core/client";
import { Button, Field, ErrorNotice } from "../../ui";
export function SessionScreen({
  client,
  session,
  onSession,
}: {
  client: DesktopClient;
  session: Session;
  onSession: (s: Session) => void;
}) {
  const importing = session.status === "empty";
  const [phrase, setPhrase] = useState("");
  const [pin, setPin] = useState("");
  const [confirm, setConfirm] = useState("");
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState("");
  const submitting = useRef(false);
  const [remaining, setRemaining] = useState(session.retry_after_ms);
  useEffect(() => {
    const end = Date.now() + session.retry_after_ms;
    setRemaining(session.retry_after_ms);
    const timer = setInterval(
      () => setRemaining(Math.max(0, end - Date.now())),
      250,
    );
    return () => clearInterval(timer);
  }, [session.retry_after_ms]);
  async function submit(e: FormEvent) {
    e.preventDefault();
    if (submitting.current || remaining > 0) return;
    setError("");
    if (!/^\d{6}$/.test(pin)) {
      setError("Use um PIN de 6 dígitos.");
      return;
    }
    if (importing && pin !== confirm) {
      setError("Os PINs não coincidem.");
      return;
    }
    submitting.current = true;
    setBusy(true);
    try {
      const s = importing
        ? await client.importWallet(phrase, pin)
        : await client.unlock(pin);
      setPhrase("");
      setPin("");
      setConfirm("");
      onSession(s);
    } catch (e) {
      setError(errorText(e));
      setPin("");
      setConfirm("");
      const state = await client.sessionStatus().catch(() => null);
      if (state) onSession(state);
    } finally {
      submitting.current = false;
      setBusy(false);
    }
  }
  return (
    <main className="onboarding">
      <div className="wordmark">
        mooze<span>●</span>
      </div>
      <span className="network-badge">TESTNET · BTC + LIQUID</span>
      <section className="card import-card">
        <p className="eyebrow">SUAS CHAVES, NESTE COMPUTADOR</p>
        <h1>
          {importing
            ? "Importar carteira de teste"
            : "Sua carteira está bloqueada"}
        </h1>
        <p className="muted">
          {importing
            ? "Use uma frase de recuperação dedicada à rede de testes."
            : "Digite seu PIN para acessar a carteira."}
        </p>
        <form onSubmit={submit}>
          {importing && (
            <label className="field">
              <span>Frase de recuperação</span>
              <textarea
                aria-label="Frase de recuperação"
                autoComplete="off"
                spellCheck={false}
                value={phrase}
                onChange={(e) => setPhrase(e.target.value)}
                required
                rows={4}
              />
              <small>Palavras BIP39 em inglês. Sem senha adicional.</small>
            </label>
          )}
          <Field
            label={importing ? "Criar PIN" : "PIN"}
            type="password"
            inputMode="numeric"
            maxLength={6}
            autoComplete="off"
            value={pin}
            onChange={(e) => setPin(e.target.value)}
            required
          />
          {importing && (
            <Field
              label="Confirmar PIN"
              type="password"
              inputMode="numeric"
              maxLength={6}
              autoComplete="off"
              value={confirm}
              onChange={(e) => setConfirm(e.target.value)}
              required
            />
          )}
          <ErrorNotice>{error}</ErrorNotice>
          {remaining > 0 && (
            <p role="status">
              Tente novamente em {Math.ceil(remaining / 1000)} segundos.
            </p>
          )}
          <Button
            className="primary wide"
            disabled={busy || remaining > 0}
            type="submit"
          >
            {busy
              ? "Abrindo carteira…"
              : importing
                ? "Importar e continuar"
                : "Desbloquear"}
          </Button>
        </form>
        <p className="small muted">
          Os ativos de teste não têm valor monetário.
        </p>
      </section>
    </main>
  );
}
