import { useRef, useState, type FormEvent } from "react";
import { useQuery, useQueryClient } from "@tanstack/react-query";
import { useWalletClient } from "../../app/client-context";
import { useWalletSession } from "../../app/session-provider";
import { errorText } from "../../core/client";
import { useT } from "../../i18n/messages";
import { Button, ErrorNotice, Modal } from "../../ui";
import { PinField } from "../../ui/pin-field";
import {
  nativeAuthError,
  nativeAuthLabel,
} from "../session/native-auth-controller";
export function NativeAuthSetting() {
  const client = useWalletClient();
  const { session } = useWalletSession();
  const qc = useQueryClient();
  const t = useT();
  const queryKey = ["wallet", session?.generation, "native-auth"];
  const status = useQuery({
    queryKey,
    queryFn: () => client.nativeAuthStatus(),
  });
  const [open, setOpen] = useState(false);
  const [pin, setPin] = useState("");
  const [error, setError] = useState("");
  const [busy, setBusy] = useState(false);
  const pending = useRef(false);
  const name = nativeAuthLabel(status.data ?? null);
  async function submit(e: FormEvent) {
    e.preventDefault();
    if (pending.current || !status.data) return;
    if (!/^\d{6}$/.test(pin)) {
      setError(t("Use um PIN de 6 dígitos."));
      return;
    }
    pending.current = true;
    setBusy(true);
    setError("");
    const value = pin;
    setPin("");
    try {
      const result = await client.setNativeAuthEnabled(
        !status.data.enabled,
        value,
      );
      qc.setQueryData(queryKey, result);
      setOpen(false);
    } catch (e) {
      const code = (e as { code?: string })?.code;
      setError(
        code?.startsWith("native_") ? t(nativeAuthError(e)) : errorText(e),
      );
    } finally {
      pending.current = false;
      setBusy(false);
    }
  }
  async function close() {
    if (busy) {
      try {
        await client.cancelNativeAuth();
      } catch (e) {
        setError(errorText(e));
        return;
      }
    }
    setOpen(false);
    setPin("");
    setError("");
  }
  if (status.data?.kind === "unsupported") return null;
  return (
    <section className="settings-row">
      <div>
        <h2>{status.data ? name : t("Autenticação do dispositivo")}</h2>
        <p className="muted">
          {t("O PIN da carteira continua disponível como alternativa.")}
        </p>
        {status.data && status.data.availability !== "available" && (
          <p>
            {t(
              "Autenticação do dispositivo indisponível. Use o PIN da carteira.",
            )}
          </p>
        )}
        <ErrorNotice>{status.error && errorText(status.error)}</ErrorNotice>
      </div>
      <Button
        disabled={
          !status.data ||
          (!status.data.enabled && status.data.availability !== "available")
        }
        onClick={() => {
          setPin("");
          setError("");
          setOpen(true);
        }}
      >
        {status.data?.enabled
          ? t("Desativar {method}", { method: name })
          : t("Ativar {method}", { method: name })}
      </Button>
      <Modal
        title={t("Autenticação do dispositivo")}
        open={open}
        onOpenChange={(value) => {
          if (!value) void close();
        }}
      >
        <form onSubmit={submit}>
          <p>{t("Confirme o PIN da carteira para alterar esta opção.")}</p>
          <PinField
            label={t("PIN da carteira")}
            value={pin}
            onValueChange={setPin}
            disabled={busy}
            required
          />
          <ErrorNotice>{error}</ErrorNotice>
          <Button type="submit" className="primary" disabled={busy}>
            {busy ? t("Aguardando autenticação…") : t("Confirmar autenticação")}
          </Button>
          <Button type="button" onClick={() => void close()}>
            {t("Cancelar")}
          </Button>
        </form>
      </Modal>
    </section>
  );
}
