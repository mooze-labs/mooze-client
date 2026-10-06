import { Checkbox } from "../../ui/checkbox";
import { PinField } from "../../ui/pin-field";
import { useT } from "../../i18n/messages";
import { useState, type FormEvent } from "react";
import { useWalletClient } from "../../app/client-context";
import { useWalletSession } from "../../app/session-provider";
import { Button, ErrorNotice, Modal } from "../../ui";
import { errorText } from "../../core/client";
export function RemoveWalletDialog() {
  const t = useT();
  const client = useWalletClient();
  const [open, setOpen] = useState(false);
  const [pin, setPin] = useState("");
  const [confirmed, setConfirmed] = useState(false);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState("");
  async function remove(e: FormEvent) {
    e.preventDefault();
    if (!confirmed || busy) return;
    setBusy(true);
    setError("");
    try {
      await client.removeWallet(pin);
    } catch (e) {
      setError(errorText(e));
    } finally {
      setPin("");
      setBusy(false);
    }
  }
  return (
    <>
      <Button
        className="danger"
        onClick={() => {
          setOpen(true);
          setError("");
        }}
      >
        {t("Remover carteira local")}
      </Button>
      <Modal
        title={t("Remover carteira deste computador?")}
        open={open}
        onOpenChange={(value) => {
          if (!busy) {
            setOpen(value);
            setPin("");
            setConfirmed(false);
          }
        }}
      >
        <form onSubmit={remove}>
          <p>
            {t(
              "Você precisará da frase de recuperação para acessar seus fundos novamente. Guarde uma cópia antes de continuar.",
            )}
          </p>
          <p>
            {t(
              "Esta ação apaga os dados locais e o acompanhamento de envios pendentes ou incertos. Ela não cancela transações na rede.",
            )}
          </p>
          <ErrorNotice>{error}</ErrorNotice>
          <label className="checkbox-row">
            <Checkbox
              checked={confirmed}
              onCheckedChange={setConfirmed}
              disabled={busy}
            />
            {t("Tenho minha frase de recuperação e entendo a remoção local.")}
          </label>
          <PinField
            label={t("Confirme seu PIN")}
            required
            value={pin}
            disabled={busy}
            onValueChange={setPin}
            invalid={!!error}
          />
          <div className="actions">
            <Button
              disabled={busy}
              onClick={() => {
                setOpen(false);
                setPin("");
                setConfirmed(false);
              }}
            >
              {t("Cancelar")}
            </Button>
            <Button
              className="danger"
              type="submit"
              disabled={busy || !confirmed || pin.length !== 6}
            >
              {busy ? "Removendo…" : t("Remover dados locais")}
            </Button>
          </div>
        </form>
      </Modal>
    </>
  );
}
export function RemovalPending() {
  const t = useT();
  const client = useWalletClient();
  const { update } = useWalletSession();
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState("");
  async function retry() {
    setBusy(true);
    setError("");
    try {
      await client.removeWallet("");
      update(await client.sessionStatus());
    } catch (e) {
      setError(errorText(e));
    } finally {
      setBusy(false);
    }
  }
  return (
    <main className="onboarding">
      <section className="card import-card">
        <h1>{t("Concluir remoção local")}</h1>
        <p>
          {t(
            "A remoção foi autorizada. A carteira permanece bloqueada até que a limpeza termine. Se houver uma falha de armazenamento, tente novamente.",
          )}
        </p>
        <ErrorNotice>{error}</ErrorNotice>
        <Button disabled={busy} onClick={() => void retry()}>
          {busy ? t("Concluindo limpeza…") : t("Concluir limpeza")}
        </Button>
      </section>
    </main>
  );
}
