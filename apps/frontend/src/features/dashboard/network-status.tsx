import { Popover } from "@base-ui/react/popover";
import { useState } from "react";
import { useWalletHoldings } from "../../app/session-provider";
import { useWalletClient } from "../../app/client-context";
import { usePreferences } from "../../i18n/preferences";
import { useT } from "../../i18n/messages";
import { Button, ErrorNotice } from "../../ui";
import { errorText } from "../../core/client";
export function NetworkStatus({ compact = false }: { compact?: boolean }) {
  const query = useWalletHoldings();
  const client = useWalletClient();
  const t = useT();
  const { preferences } = usePreferences();
  const [error, setError] = useState("");
  const ready =
    query.data?.chains.length === 2 &&
    query.data.chains.every((c) => c.phase === "ready");
  const failed = query.data?.chains.some((c) => c.phase === "error");
  const label = query.isFetching
    ? t("Atualizando…")
    : ready
      ? t("Redes sincronizadas")
      : failed
        ? t("Falha de conexão")
        : t("Aguardando sincronização");
  return (
    <Popover.Root>
      <Popover.Trigger
        className="network-trigger"
        aria-label={label}
        title={compact ? label : undefined}
      >
        <span
          className={`status-dot ${ready ? "ready" : failed ? "failed" : "waiting"}`}
        />
        <span className="sidebar-label">{label}</span>
      </Popover.Trigger>
      <Popover.Portal>
        <Popover.Positioner side="right" sideOffset={12}>
          <Popover.Popup className="network-popover">
            <Popover.Title>{t("Estado das redes")}</Popover.Title>
            {["Bitcoin", "Liquid"].map((chain) => {
              const state = query.data?.chains.find((c) => c.chain === chain);
              return (
                <div className="network-state" key={chain}>
                  <strong>{chain}</strong>
                  <p>
                    {state?.phase === "ready"
                      ? t("Sincronizado")
                      : state?.phase === "error"
                        ? t("Falha de conexão")
                        : t("Sincronizando…")}
                  </p>
                  <small className="muted">
                    {state?.last_success_at_ms != null
                      ? t("Última sincronização: {date}", {
                          date: new Date(
                            state.last_success_at_ms,
                          ).toLocaleString(preferences.locale),
                        })
                      : t("Aguardando a primeira sincronização")}
                  </small>
                </div>
              );
            })}
            <ErrorNotice>{error}</ErrorNotice>
            <Button
              disabled={query.isFetching}
              onClick={() =>
                void client
                  .refresh()
                  .then(() => setError(""))
                  .catch((e) => setError(errorText(e)))
              }
            >
              {t("Atualizar")}
            </Button>
          </Popover.Popup>
        </Popover.Positioner>
      </Popover.Portal>
    </Popover.Root>
  );
}
