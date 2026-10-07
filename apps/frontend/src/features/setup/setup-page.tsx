import { useEffect, useReducer, useRef, useState } from "react";
import { FlowStep } from "../../ui/flow-step";
import { useNow } from "../../ui/use-now";
import { useNetwork, networkLabel } from "../../core/network";
import { useT } from "../../i18n/messages";
import { Button, Field, ErrorNotice } from "../../ui";
import { errorText, type DesktopClient, type Session } from "../../core/client";
import { SetupProgress } from "./setup-progress";
import { ImportPhrase } from "./import-phrase";
import { SetupPin } from "./setup-pin";
import { SetupTerms } from "./setup-terms";
import {
  backupMatches,
  setupReducer,
  validWordCount,
  type SetupAction,
} from "./setup-state";

export function SetupPage({
  client,
  onSession,
}: {
  client: DesktopClient;
  onSession: (session: Session) => void;
}) {
  const t = useT();
  const network = useNetwork();
  const [state, dispatch] = useReducer(setupReducer, { step: "welcome" });
  const [termsAccepted, setTermsAccepted] = useState(false);
  const [extended, setExtended] = useState(false);
  const [error, setError] = useState("");
  const [busy, setBusy] = useState(false);
  const active = useRef(true);
  const submitting = useRef(false);
  const candidate =
    "draft" in state && state.draft.kind === "create"
      ? state.draft.setup
      : null;
  const now = useNow(!!candidate);
  const inFlight = state.step === "preparing" || state.step === "recover";
  const remaining = candidate ? Math.max(0, candidate.expires_at_ms - now) : 0;
  const importing =
    state.step === "import" ||
    ("draft" in state && state.draft.kind === "import");
  useEffect(() => {
    active.current = true;
    return () => {
      active.current = false;
    };
  }, []);
  useEffect(() => {
    if (!candidate) return;
    return () => {
      void client.cancelSetup(candidate.setup_id).catch(() => {});
    };
  }, [candidate, client]);
  useEffect(() => {
    // A submission owns its outcome; expiration must not replace an in-flight
    // operation with a new wallet. Reconcile the host status first.
    if (candidate && remaining === 0 && !inFlight) dispatch({ type: "expire" });
  }, [candidate, remaining, inFlight]);
  function move(action: SetupAction) {
    if (
      (action.type === "create" || action.type === "import") &&
      !termsAccepted
    )
      return;
    setError("");
    dispatch(action);
  }
  async function run(action: () => Promise<void>) {
    if (submitting.current) return;
    submitting.current = true;
    setBusy(true);
    setError("");
    try {
      await action();
    } catch (e) {
      if (active.current) setError(errorText(e));
    } finally {
      submitting.current = false;
      if (active.current) setBusy(false);
    }
  }
  async function begin() {
    await run(async () => {
      const setup = await client.beginSetup(extended);
      if (!active.current) {
        await client.cancelSetup(setup.setup_id);
        return;
      }
      dispatch({ type: "generated", setup });
    });
  }
  async function validateImport() {
    if (state.step !== "import") return;
    await run(async () => {
      try {
        await client.validateRecoveryPhrase(state.words.join(" "));
        if (active.current) dispatch({ type: "continue" });
      } catch (e) {
        if (!active.current) return;
        const failure = e as { code?: string; details?: string };
        setError(
          failure?.code === "invalid_recovery_words"
            ? t("Confira as palavras nas posições: {positions}.", {
                positions: failure.details ?? "",
              })
            : failure?.code === "invalid_checksum"
              ? t(
                  "As palavras não formam uma frase válida. Confira a ordem e o conteúdo.",
                )
              : failure?.code === "invalid_word_count"
                ? t("Use uma frase de 12, 15, 18, 21 ou 24 palavras.")
                : errorText(e),
        );
      }
    });
  }
  async function reconcile(message: string, expired = false) {
    try {
      const session = await client.sessionStatus();
      if (!active.current) return;
      if (session.status !== "empty") {
        dispatch({ type: "cancel" });
        onSession(session);
      } else {
        dispatch({ type: expired ? "expire" : "retry" });
        setError(message);
      }
    } catch {
      if (!active.current) return;
      dispatch({ type: "recover" });
      setError(
        t(
          "Não foi possível confirmar se a carteira foi salva. Verifique o estado antes de tentar novamente.",
        ),
      );
    }
  }
  async function complete(pin: string) {
    if (state.step !== "pin") return;
    const draft = state.draft;
    await run(async () => {
      dispatch({ type: "prepare" });
      try {
        const session =
          draft.kind === "create"
            ? await client.completeSetup(
                draft.setup.setup_id,
                draft.answers,
                pin,
              )
            : await client.importWallet(draft.words.join(" "), pin);
        if (!active.current) return;
        dispatch({ type: "cancel" });
        onSession(session);
      } catch (e) {
        await reconcile(
          errorText(e),
          (e as { code?: string } | null)?.code === "setup_expired",
        );
      }
    });
  }
  const progressStep =
    state.step === "welcome" ||
    state.step === "configure" ||
    state.step === "expired"
      ? 0
      : state.step === "backup" || state.step === "import"
        ? 1
        : state.step === "verify"
          ? 2
          : state.step === "pin"
            ? importing
              ? 2
              : 3
            : importing
              ? 3
              : 4;
  return (
    <main className="onboarding setup-onboarding">
      <div className="wordmark">
        {t("mooze")}
        <span>●</span>
      </div>
      {networkLabel(network) && (
        <span className="network-badge">{networkLabel(network)}</span>
      )}
      <section
        className="card import-card setup-card"
        data-step={state.step}
        aria-busy={busy}
      >
        <SetupProgress step={progressStep} importing={importing} />
        <ErrorNotice>{state.step === "expired" ? "" : error}</ErrorNotice>
        {candidate && remaining > 0 && remaining <= 120_000 && !inFlight && (
          <p className="notice" role="status">
            {t(
              "Esta frase expira em {seconds}s. Ao reiniciar, uma nova frase será gerada.",
              { seconds: Math.ceil(remaining / 1000) },
            )}
          </p>
        )}
        <FlowStep step={state.step}>
          <div key={state.step} className="flow-step">
            {state.step === "welcome" && (
              <>
                <h1>{t("Como você quer começar?")}</h1>
                <p>
                  {t(
                    "Crie uma carteira sob seu controle ou recupere uma carteira existente com sua frase.",
                  )}
                </p>
                <div className="setup-context">
                  <strong>{t("Suas chaves, sua carteira")}</strong>
                  <p>
                    {t(
                      "A frase de recuperação é seu backup. O PIN protege o acesso neste computador.",
                    )}
                  </p>
                </div>
                <SetupTerms
                  accepted={termsAccepted}
                  onAcceptedChange={setTermsAccepted}
                />
                <div className="setup-actions">
                  <Button
                    className="primary"
                    disabled={!termsAccepted}
                    onClick={() => move({ type: "create" })}
                  >
                    {t("Criar carteira")}
                  </Button>
                  <Button
                    disabled={!termsAccepted}
                    onClick={() => move({ type: "import" })}
                  >
                    {t("Importar carteira")}
                  </Button>
                </div>
              </>
            )}
            {state.step === "configure" && (
              <>
                <h1>{t("Prepare sua recuperação")}</h1>
                <p>
                  {t(
                    "Escolha o tamanho da frase e tenha onde anotá-la antes de continuar.",
                  )}
                </p>
                <fieldset className="phrase-options">
                  <legend>{t("Frase de recuperação")}</legend>
                  {[false, true].map((value) => (
                    <label
                      key={String(value)}
                      className="phrase-option"
                      data-selected={extended === value}
                    >
                      <input
                        type="radio"
                        name="phrase-length"
                        checked={extended === value}
                        disabled={busy}
                        onChange={() => setExtended(value)}
                      />
                      <span>
                        <strong>
                          {t(value ? "24 palavras" : "12 palavras")}
                        </strong>
                        <small>
                          {t(
                            value
                              ? "Uma frase mais longa para guardar e conferir."
                              : "Mais simples de anotar e recuperar.",
                          )}
                        </small>
                      </span>
                    </label>
                  ))}
                </fieldset>
                <p className="small muted">
                  {t(
                    "Nunca compartilhe sua frase. Quem a possui pode acessar sua carteira.",
                  )}
                </p>
                <div className="setup-actions">
                  <Button
                    className="primary"
                    disabled={busy}
                    onClick={() => void begin()}
                  >
                    {t(busy ? "Gerando frase…" : "Gerar frase")}
                  </Button>
                  <Button
                    disabled={busy}
                    onClick={() => move({ type: "back" })}
                  >
                    {t("Voltar")}
                  </Button>
                </div>
              </>
            )}
            {state.step === "backup" && (
              <>
                <h1>{t("Guarde sua frase")}</h1>
                <p>
                  {t(
                    "Anote as palavras na ordem indicada. Elas permitem recuperar sua carteira.",
                  )}
                </p>
                {state.revealed ? (
                  <ol className="seed-grid">
                    {state.draft.setup.words.map((word, i) => (
                      <li key={i}>{word}</li>
                    ))}
                  </ol>
                ) : (
                  <div className="setup-context">
                    <p>
                      {t(
                        "Confira se ninguém está vendo sua tela. Guarde a frase em um lugar privado e seguro.",
                      )}
                    </p>
                    <Button
                      className="primary"
                      onClick={() => move({ type: "reveal" })}
                    >
                      {t("Revelar frase")}
                    </Button>
                  </div>
                )}
                {state.revealed && (
                  <div className="setup-actions">
                    <Button
                      className="primary"
                      onClick={() => move({ type: "continue" })}
                    >
                      {t("Anotei minha frase")}
                    </Button>
                  </div>
                )}
              </>
            )}
            {state.step === "verify" && (
              <form
                id="wallet-setup"
                onSubmit={(event) => {
                  event.preventDefault();
                  if (!backupMatches(state.draft)) {
                    setError(t("Confira as palavras na ordem indicada."));
                    return;
                  }
                  move({ type: "continue" });
                }}
              >
                <h1>{t("Confirme sua recuperação")}</h1>
                <p>
                  {t(
                    "Preencha as palavras solicitadas para conferir sua recuperação.",
                  )}
                </p>
                {state.draft.setup.challenge_indices.map((index, i) => (
                  <Field
                    key={index}
                    label={t("Palavra {number}", { number: index + 1 })}
                    value={state.draft.answers[i]}
                    autoComplete="off"
                    autoCapitalize="none"
                    spellCheck={false}
                    required
                    onChange={(e) =>
                      move({ type: "answer", index: i, value: e.target.value })
                    }
                  />
                ))}
                <div className="setup-actions">
                  <Button type="submit" className="primary">
                    {t("Continuar")}
                  </Button>
                  <Button onClick={() => move({ type: "back" })}>
                    {t("Rever minha frase")}
                  </Button>
                </div>
              </form>
            )}
            {state.step === "import" && (
              <>
                <ImportPhrase
                  client={client}
                  words={state.words}
                  busy={busy}
                  onChange={(words) => move({ type: "words", words })}
                />
                <div className="setup-actions">
                  <Button
                    className="primary"
                    disabled={
                      busy ||
                      !validWordCount(state.words.length) ||
                      state.words.some((word) => !word || /\s/.test(word))
                    }
                    onClick={() => void validateImport()}
                  >
                    {t(busy ? "Verificando frase…" : "Continuar")}
                  </Button>
                  <Button
                    disabled={busy}
                    onClick={() => move({ type: "back" })}
                  >
                    {t("Voltar")}
                  </Button>
                </div>
              </>
            )}
            {state.step === "pin" && (
              <>
                <SetupPin onSubmit={(pin) => void complete(pin)} />
                <div className="setup-actions">
                  <Button
                    form="wallet-setup"
                    type="submit"
                    className="primary"
                    disabled={busy}
                  >
                    {t(importing ? "Importar e continuar" : "Concluir criação")}
                  </Button>
                  <Button
                    disabled={busy}
                    onClick={() => move({ type: "back" })}
                  >
                    {t("Voltar")}
                  </Button>
                </div>
              </>
            )}
            {state.step === "preparing" && (
              <>
                <h1>{t("Preparando sua carteira")}</h1>
                <p role="status">
                  {t("Salvando sua carteira e iniciando os serviços…")}
                </p>
                <p className="muted">
                  {t(
                    "Seus saldos e histórico serão atualizados durante a sincronização. Mantenha o aplicativo aberto.",
                  )}
                </p>
              </>
            )}
            {state.step === "recover" && (
              <>
                <h1>{t("Verifique o estado da carteira")}</h1>
                <Button
                  className="primary"
                  disabled={busy}
                  onClick={() =>
                    void run(() => reconcile(t("Tente novamente com seu PIN.")))
                  }
                >
                  {t("Verificar estado")}
                </Button>
              </>
            )}
            {state.step === "expired" && (
              <>
                <h1>{t("Sua criação expirou")}</h1>
                <div className="alert error" role="alert">
                  {t(
                    "A criação expirou. Ao reiniciar, anote a nova frase; a anterior não será usada.",
                  )}
                </div>
                <Button
                  className="primary"
                  onClick={() => move({ type: "create" })}
                >
                  {t("Começar novamente")}
                </Button>
              </>
            )}
          </div>
        </FlowStep>
        {candidate && !inFlight && (
          <Button
            className="ghost setup-cancel"
            disabled={busy}
            onClick={() => move({ type: "cancel" })}
          >
            {t("Cancelar criação")}
          </Button>
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
