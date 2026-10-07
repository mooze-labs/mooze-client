import { FlowStep } from "../../ui/flow-step";
import { useNetwork, networkLabel } from "../../core/network";
import { SelectField } from "../../ui/select-field";
import { SetupProgress } from "./setup-progress";
import { PinField } from "../../ui/pin-field";
import { useT } from "../../i18n/messages";
import { useEffect, useRef, useState, type FormEvent } from "react";
import { Button, Field, ErrorNotice } from "../../ui";
import { errorText, type DesktopClient, type Session } from "../../core/client";
import type { SetupDto } from "../../core/desktop.generated";
import { SessionScreen } from "../session/session-screen";
export function SetupPage({
  client,
  onSession,
}: {
  client: DesktopClient;
  onSession: (s: Session) => void;
}) {
  const t = useT();
  const network = useNetwork();
  const [mode, setMode] = useState<
    "welcome" | "import" | "backup" | "verify" | "pin"
  >("welcome");
  const [extended, setExtended] = useState(false);
  const [setup, setSetup] = useState<SetupDto | null>(null);
  const [answers, setAnswers] = useState<string[]>([]);
  const [pin, setPin] = useState("");
  const [confirm, setConfirm] = useState("");
  const [error, setError] = useState("");
  const [busy, setBusy] = useState(false);
  const active = useRef(true);
  useEffect(() => {
    active.current = true;
    return () => {
      active.current = false;
    };
  }, []);
  useEffect(() => {
    if (!setup) return;
    const timer = setTimeout(() => {
      setSetup(null);
      setPin("");
      setConfirm("");
      setAnswers([]);
      setMode("welcome");
      setError(t("A criação expirou. Comece novamente."));
    }, 600_000);
    return () => {
      clearTimeout(timer);
      void client.cancelSetup(setup.setup_id).catch(() => {});
    };
  }, [setup, client]);
  async function begin() {
    setBusy(true);
    setError("");
    try {
      const result = await client.beginSetup(extended);
      if (!active.current) {
        void client.cancelSetup(result.setup_id);
        return;
      }
      setSetup(result);
      setAnswers(result.challenge_indices.map(() => ""));
      setMode("backup");
    } catch (e) {
      setError(errorText(e));
    } finally {
      setBusy(false);
    }
  }
  async function complete(e: FormEvent) {
    e.preventDefault();
    if (!setup || busy) return;
    if (pin !== confirm) {
      setError(t("Os PINs não coincidem."));
      return;
    }
    if (!/^\d{6}$/.test(pin)) {
      setError(t("Use um PIN de 6 dígitos."));
      return;
    }
    setBusy(true);
    setError("");
    try {
      const session = await client.completeSetup(setup.setup_id, answers, pin);
      setSetup(null);
      setPin("");
      setConfirm("");
      setAnswers([]);
      onSession(session);
    } catch (e) {
      setError(errorText(e));
      setPin("");
      setConfirm("");
    } finally {
      setBusy(false);
    }
  }
  if (mode === "import")
    return (
      <>
        <SessionScreen
          client={client}
          session={{ status: "empty", generation: 0, retry_after_ms: 0 }}
          onSession={onSession}
        />
        <div className="setup-back">
          <Button onClick={() => setMode("welcome")}>{t("Voltar")}</Button>
        </div>
      </>
    );
  return (
    <main className="onboarding">
      <div className="wordmark">
        {t("mooze")}
        <span>●</span>
      </div>
      {networkLabel(network) && (
        <span className="network-badge">{networkLabel(network)}</span>
      )}
      <section className="card import-card setup-card">
        <SetupProgress
          step={
            mode === "welcome"
              ? 0
              : mode === "backup"
                ? 1
                : mode === "verify"
                  ? 2
                  : 3
          }
        />
        <ErrorNotice>{error}</ErrorNotice>
        <FlowStep step={mode}>
          <div key={mode} className="flow-step">
            {mode === "welcome" ? (
              <>
                <h1>{t("Sua carteira")}</h1>
                <p>
                  {t(
                    "Crie uma carteira ou importe sua frase de recuperação. Guarde-a em um lugar seguro.",
                  )}
                </p>
                <SelectField
                  label={t("Frase de recuperação")}
                  value={extended ? "24" : "12"}
                  onValueChange={(value) => setExtended(value === "24")}
                  items={[
                    { value: "12", label: <>{t("12 palavras")}</> },
                    { value: "24", label: <>{t("24 palavras")}</> },
                  ]}
                />
                <div className="setup-actions">
                  <Button
                    className="primary"
                    disabled={busy}
                    onClick={() => void begin()}
                  >
                    {t("Criar carteira")}
                  </Button>
                  <Button disabled={busy} onClick={() => setMode("import")}>
                    {t("Importar carteira")}
                  </Button>
                </div>
              </>
            ) : mode === "backup" && setup ? (
              <>
                <h1>{t("Guarde sua frase")}</h1>
                <p>
                  {t(
                    "Anote as palavras na ordem indicada. Elas permitem recuperar sua carteira.",
                  )}
                </p>
                <ol className="seed-grid">
                  {setup.words.map((word, i) => (
                    <li key={i}>{word}</li>
                  ))}
                </ol>
              </>
            ) : mode === "verify" && setup ? (
              <form
                id="wallet-setup"
                onSubmit={(e) => {
                  e.preventDefault();
                  if (
                    !setup.challenge_indices.every(
                      (index, i) =>
                        answers[i].trim().toLowerCase() === setup.words[index],
                    )
                  ) {
                    setError(t("Confira as palavras na ordem indicada."));
                    return;
                  }
                  setAnswers(
                    answers.map((answer) => answer.trim().toLowerCase()),
                  );
                  setError("");
                  setMode("pin");
                }}
              >
                <h1>{t("Confirme sua recuperação")}</h1>
                <p className="muted">
                  {t(
                    "Preencha as palavras solicitadas para conferir sua recuperação.",
                  )}
                </p>
                {setup.challenge_indices.map((index, i) => (
                  <Field
                    key={index}
                    label={t("Palavra {number}", { number: index + 1 })}
                    value={answers[i]}
                    autoComplete="off"
                    spellCheck={false}
                    required
                    onChange={(e) =>
                      setAnswers((old) =>
                        old.map((v, j) => (i === j ? e.target.value : v)),
                      )
                    }
                  />
                ))}
              </form>
            ) : mode === "pin" && setup ? (
              <form id="wallet-setup" onSubmit={complete}>
                <h1>{t("Proteja sua carteira")}</h1>
                <p className="muted">
                  {t(
                    "Escolha um PIN de 6 dígitos para desbloquear sua carteira.",
                  )}
                </p>
                <PinField
                  label={t("Criar PIN")}
                  required
                  value={pin}
                  onValueChange={setPin}
                  disabled={busy}
                  invalid={!!error}
                />
                <PinField
                  label={t("Confirmar PIN")}
                  required
                  value={confirm}
                  onValueChange={setConfirm}
                  disabled={busy}
                  invalid={!!error}
                />
              </form>
            ) : null}
          </div>
        </FlowStep>
        {mode !== "welcome" && (
          <div className="setup-actions">
            {mode === "backup" ? (
              <Button
                key="backup-confirm"
                type="button"
                className="primary"
                onClick={() => setMode("verify")}
              >
                {t("Anotei minha frase")}
              </Button>
            ) : (
              <Button
                key="create-wallet"
                type="submit"
                form="wallet-setup"
                className="primary"
                disabled={busy}
              >
                {t(mode === "verify" ? "Continuar" : "Concluir criação")}
              </Button>
            )}
            {mode === "pin" && (
              <Button
                disabled={busy}
                onClick={() => {
                  setPin("");
                  setConfirm("");
                  setError("");
                  setMode("verify");
                }}
              >
                {t("Voltar")}
              </Button>
            )}
            <Button
              disabled={busy}
              onClick={() => {
                setSetup(null);
                setAnswers([]);
                setPin("");
                setConfirm("");
                setMode("welcome");
              }}
            >
              {t("Cancelar criação")}
            </Button>
          </div>
        )}
        {network === "Testnet" && (
          <p className="small muted">
            {t("Ativos de teste não possuem valor monetário.")}
          </p>
        )}
      </section>
    </main>
  );
}
