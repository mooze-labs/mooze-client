import { useNetwork } from "../../core/network";
import { Textarea } from "../../ui/textarea";
import { PinField } from "../../ui/pin-field";
import { useT } from "../../i18n/messages";
import { useState, useEffect, useRef, type FormEvent } from "react";
import type { DesktopClient, Session } from "../../core/client";
import { errorText } from "../../core/client";
import { Button, ErrorNotice } from "../../ui";
export function SessionScreen({
  client,
  session,
  onSession,
}: {
  client: DesktopClient;
  session: Session;
  onSession: (s: Session) => void;
}) {
  const t = useT();
  const network = useNetwork();
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
      setError(t("Use um PIN de 6 dígitos."));
      return;
    }
    if (importing && pin !== confirm) {
      setError(t("Os PINs não coincidem."));
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
        {t("mooze")}
        <span>●</span>
      </div>
      <span className="network-badge">{network} · BTC + LIQUID</span>
      <section className={`card import-card ${importing ? "" : "unlock-card"}`}>
        <p className="eyebrow">{t("SUAS CHAVES, NESTE COMPUTADOR")}</p>
        <h1>
          {importing
            ? t("Importar carteira")
            : t("Sua carteira está bloqueada")}
        </h1>
        <p className="muted">
          {importing
            ? t("Use sua frase de recuperação para importar a carteira.")
            : t("Digite seu PIN para acessar a carteira.")}
        </p>
        <form onSubmit={submit}>
          {importing && (
            <label className="field">
              <span>{t("Frase de recuperação")}</span>
              <Textarea
                aria-label={t("Frase de recuperação")}
                autoComplete="off"
                spellCheck={false}
                value={phrase}
                onChange={(e) => setPhrase(e.target.value)}
                required
                rows={4}
              />
              <small>
                {t("Palavras BIP39 em inglês. Sem senha adicional.")}
              </small>
            </label>
          )}
          <PinField
            label={importing ? t("Criar PIN") : "PIN"}
            value={pin}
            onValueChange={setPin}
            required
            disabled={busy}
            invalid={!!error}
          />
          {importing && (
            <PinField
              label={t("Confirmar PIN")}
              value={confirm}
              onValueChange={setConfirm}
              required
              disabled={busy}
              invalid={!!error}
            />
          )}
          <ErrorNotice>{error}</ErrorNotice>
          {remaining > 0 && (
            <p role="status">
              {t("Tente novamente em")} {Math.ceil(remaining / 1000)}{" "}
              {t("segundos.")}
            </p>
          )}
          <Button
            className="primary wide"
            disabled={busy || remaining > 0}
            type="submit"
          >
            {busy
              ? t("Abrindo carteira…")
              : importing
                ? t("Importar e continuar")
                : t("Desbloquear")}
          </Button>
        </form>
        <p className="small muted">
          {network === "Testnet" &&
            t("Os ativos de teste não têm valor monetário.")}
        </p>
      </section>
    </main>
  );
}
