import { useT } from "../../i18n/messages";
import { useState } from "react";
import { useWalletClient } from "../../app/client-context";
import { Button, ErrorNotice } from "../../ui";
import { errorText } from "../../core/client";
import { RemoveWalletDialog } from "./remove-wallet-dialog";
export function AboutPage() {
  const t = useT();
  const client = useWalletClient();
  const [busy, setBusy] = useState(false);
  const [message, setMessage] = useState("");
  const [error, setError] = useState("");
  async function exportReport() {
    setBusy(true);
    setError("");
    setMessage("");
    try {
      const saved = await client.exportDiagnostics();
      setMessage(
        saved ? t("Diagnóstico exportado.") : t("Exportação cancelada."),
      );
    } catch (e) {
      setError(errorText(e));
    } finally {
      setBusy(false);
    }
  }
  return (
    <section className="card section-gap">
      <h2>{t("Sobre e diagnóstico")}</h2>
      <p>{t("Mooze · Bitcoin e Liquid")}</p>
      <p className="muted">
        {t(
          "O diagnóstico contém a versão do aplicativo, plataforma e estado de sincronização. Não inclui frase, PIN, endereços, saldos ou IDs de transações.",
        )}
      </p>
      <ErrorNotice>{error}</ErrorNotice>
      <Button disabled={busy} onClick={() => void exportReport()}>
        {busy ? "Exportando…" : t("Exportar diagnóstico")}
      </Button>
      <p role="status">{message}</p>
      <h3>{t("Dados locais")}</h3>
      <RemoveWalletDialog />
    </section>
  );
}
