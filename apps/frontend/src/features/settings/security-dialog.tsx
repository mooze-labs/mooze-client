import { PinField } from "../../ui/pin-field";
import { useState, type FormEvent } from "react";
import { useT } from "../../i18n/messages";
import { useWalletClient } from "../../app/client-context";
import { errorText } from "../../core/client";
import { Button, ErrorNotice, Modal } from "../../ui";
export function SecurityDialog({
  kind,
  open,
  onOpenChange,
}: {
  kind: "pin" | "recovery";
  open: boolean;
  onOpenChange: (open: boolean) => void;
}) {
  return open ? (
    <SecurityDialogContent key={kind} kind={kind} onOpenChange={onOpenChange} />
  ) : null;
}
function SecurityDialogContent({
  kind,
  onOpenChange,
}: {
  kind: "pin" | "recovery";
  onOpenChange: (open: boolean) => void;
}) {
  const t = useT();
  const client = useWalletClient();
  const [pin, setPin] = useState("");
  const [recoveryPin, setRecoveryPin] = useState("");
  const [newPin, setNewPin] = useState("");
  const [confirm, setConfirm] = useState("");
  const [words, setWords] = useState<string[]>([]);
  const [error, setError] = useState("");
  const [busy, setBusy] = useState(false);
  const [message, setMessage] = useState("");
  async function reveal(e: FormEvent) {
    e.preventDefault();
    setBusy(true);
    setError("");
    try {
      setWords(await client.revealRecoveryPhrase(recoveryPin));
    } catch (e) {
      setError(errorText(e));
    } finally {
      setRecoveryPin("");
      setBusy(false);
    }
  }
  async function change(e: FormEvent) {
    e.preventDefault();
    if (newPin !== confirm) {
      setError(t("Os PINs não coincidem."));
      return;
    }
    setBusy(true);
    setError("");
    try {
      await client.changePin(pin, newPin);
      setMessage(t("PIN alterado."));
    } catch (e) {
      setError(errorText(e));
    } finally {
      setPin("");
      setNewPin("");
      setConfirm("");
      setBusy(false);
    }
  }
  return (
    <Modal
      open
      title={t(kind === "pin" ? "Alterar PIN" : "Frase de recuperação")}
      onOpenChange={(value) => {
        if (!busy) onOpenChange(value);
      }}
    >
      <ErrorNotice>{error}</ErrorNotice>
      {kind === "recovery" ? (
        <div>
          {" "}
          {words.length ? (
            <>
              <ol className="seed-grid">
                {words.map((w, i) => (
                  <li key={i}>{w}</li>
                ))}
              </ol>
              <Button onClick={() => setWords([])}>{t("Ocultar frase")}</Button>
            </>
          ) : (
            <form onSubmit={reveal}>
              <p>
                {t(
                  "Confirme seu PIN para visualizar sua frase. Não compartilhe estas palavras.",
                )}
              </p>
              <PinField
                label={t("PIN para recuperação")}
                required
                value={recoveryPin}
                onValueChange={setRecoveryPin}
                disabled={busy}
                invalid={!!error}
              />
              <Button type="submit" disabled={busy}>
                {t("Ver frase de recuperação")}
              </Button>
            </form>
          )}
        </div>
      ) : (
        <div>
          {" "}
          <form onSubmit={change}>
            <PinField
              label={t("PIN atual")}
              required
              value={pin}
              onValueChange={setPin}
              disabled={busy}
              invalid={!!error}
            />
            <PinField
              label={t("Novo PIN")}
              required
              value={newPin}
              onValueChange={setNewPin}
              disabled={busy}
              invalid={!!error}
            />
            <PinField
              label={t("Confirmar novo PIN")}
              required
              value={confirm}
              onValueChange={setConfirm}
              disabled={busy}
              invalid={!!error}
            />
            <Button type="submit" disabled={busy}>
              {t("Salvar PIN")}
            </Button>
            <p role="status">{message}</p>
          </form>
        </div>
      )}
      <Button disabled={busy} onClick={() => onOpenChange(false)}>
        {t("Cancelar")}
      </Button>
    </Modal>
  );
}
