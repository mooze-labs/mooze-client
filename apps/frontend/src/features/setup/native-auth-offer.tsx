import { useRef, useState } from "react";
import type { DesktopClient } from "../../core/client";
import type { NativeAuthStatusDto } from "../../core/desktop.generated";
import { useT } from "../../i18n/messages";
import { Button, ErrorNotice } from "../../ui";
import {
  nativeAuthLabel,
  nativeAuthError,
} from "../session/native-auth-controller";
export function NativeAuthOffer({
  client,
  status,
  onDone,
}: {
  client: DesktopClient;
  status: NativeAuthStatusDto;
  onDone: (status: NativeAuthStatusDto) => void;
}) {
  const t = useT();
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState("");
  const pending = useRef(false);
  async function choose(enable: boolean) {
    if (pending.current) return;
    pending.current = true;
    setBusy(true);
    setError("");
    try {
      onDone(await client.completeNativeAuthOffer(enable));
    } catch (e) {
      setError(nativeAuthError(e));
    } finally {
      pending.current = false;
      setBusy(false);
    }
  }
  const name = nativeAuthLabel(status);
  return (
    <main className="onboarding">
      <section className="card unlock-card">
        <p className="eyebrow">{t("ACESSO À CARTEIRA")}</p>
        <h1>{t("Desbloquear com {method}", { method: name })}</h1>
        <p className="muted">
          {t(
            "Acesse sua carteira com a autenticação deste computador. Você poderá usar o PIN da carteira quando precisar.",
          )}
        </p>
        <ErrorNotice>{error && t(error)}</ErrorNotice>
        <Button
          className="primary wide"
          disabled={busy}
          onClick={() => void choose(true)}
        >
          {busy
            ? t("Aguardando autenticação…")
            : t("Ativar {method}", { method: name })}
        </Button>
        <Button
          className="wide"
          disabled={busy}
          onClick={() => void choose(false)}
        >
          {t("Agora não")}
        </Button>
      </section>
    </main>
  );
}
