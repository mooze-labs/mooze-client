import { useState } from "react";
import type { ChainStateDto } from "../../core/desktop.generated";
import { errorText } from "../../core/client";
import { useT } from "../../i18n/messages";
import { Button, ErrorNotice } from "../../ui";
export function FirstSyncNotice({
  chains,
  retry,
}: {
  chains: ChainStateDto[];
  retry: () => Promise<void>;
}) {
  const t = useT();
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState("");
  if (
    ["Bitcoin", "Liquid"].every((name) =>
      chains.some(
        (chain) => chain.chain === name && chain.last_success_at_ms !== null,
      ),
    )
  )
    return null;
  const failed = chains.some((chain) => chain.phase === "error");
  return (
    <section
      className="notice first-sync-notice"
      aria-label={t("Primeira sincronização")}
    >
      <div role="status" aria-live="polite" aria-atomic="true">
        <p>
          {t(
            "Sua carteira está salva. Estamos buscando seus saldos e histórico.",
          )}
        </p>
        <ul>
          {["Bitcoin", "Liquid"].map((name) => {
            const chain = chains.find((chain) => chain.chain === name);
            return (
              <li key={name}>
                <strong>{name}</strong>
                <span>
                  {t(
                    chain?.phase === "error"
                      ? "Falha de conexão"
                      : chain?.last_success_at_ms != null
                        ? "Sincronizado"
                        : "Sincronizando…",
                  )}
                </span>
              </li>
            );
          })}
        </ul>
      </div>
      <ErrorNotice>{error}</ErrorNotice>
      {failed && (
        <Button
          disabled={busy}
          onClick={() => {
            if (busy) return;
            setBusy(true);
            setError("");
            void retry()
              .catch((e) => setError(errorText(e)))
              .finally(() => setBusy(false));
          }}
        >
          {t(busy ? "Atualizando…" : "Tentar novamente")}
        </Button>
      )}
    </section>
  );
}
