import { useState, type FormEvent } from "react";
import { PinField } from "../../ui/pin-field";
import { ErrorNotice } from "../../ui";
import { useT } from "../../i18n/messages";
export function SetupPin({ onSubmit }: { onSubmit: (pin: string) => void }) {
  const t = useT();
  const [pin, setPin] = useState("");
  const [confirm, setConfirm] = useState("");
  const [error, setError] = useState("");
  function submit(event: FormEvent) {
    event.preventDefault();
    if (!/^\d{6}$/.test(pin)) {
      setError("Use um PIN de 6 dígitos.");
      return;
    }
    if (pin !== confirm) {
      setError("Os PINs não coincidem.");
      return;
    }
    const value = pin;
    setPin("");
    setConfirm("");
    setError("");
    onSubmit(value);
  }
  return (
    <form id="wallet-setup" onSubmit={submit}>
      <h1>{t("Proteja sua carteira")}</h1>
      <p>{t("Escolha um PIN de 6 dígitos para desbloquear sua carteira.")}</p>
      <p className="small muted">
        {t(
          "Este PIN protege o acesso neste computador. Sua frase de recuperação permite restaurar a carteira em outro dispositivo.",
        )}
      </p>
      <PinField
        label={t("Criar PIN")}
        required
        value={pin}
        onValueChange={setPin}
        invalid={!!error}
      />
      <PinField
        label={t("Confirmar PIN")}
        required
        value={confirm}
        onValueChange={setConfirm}
        invalid={!!error}
      />
      <ErrorNotice>{error}</ErrorNotice>
    </form>
  );
}
