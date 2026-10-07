import { useQuery } from "@tanstack/react-query";
import { useWalletClient } from "../../app/client-context";
import { useWalletSession } from "../../app/session-provider";
import { Button, ErrorNotice } from "../../ui";
import { useT } from "../../i18n/messages";
import { errorText } from "../../core/client";
export function BackendStatus() {
  const t = useT();
  const client = useWalletClient();
  const { session } = useWalletSession();
  const state = useQuery({
    queryKey: ["wallet", session?.generation, "backend"],
    queryFn: () => client.backendStatus(),
    retry: false,
  });
  if (state.data?.state === "Disabled") return null;
  return (
    <div className="service-status">
      <span className="small muted">
        {t(
          state.isPending
            ? "Conectando ao Mooze…"
            : state.data?.state === "Ready"
              ? "Conectado ao Mooze"
              : "Backend indisponível. Sua carteira continua disponível.",
        )}
      </span>
      <ErrorNotice>{state.error ? errorText(state.error) : ""}</ErrorNotice>
      {state.data?.retryable && (
        <Button
          className="ghost"
          disabled={state.isFetching}
          onClick={() =>
            void client
              .backendRetry()
              .then(() => state.refetch())
              .catch(() => state.refetch())
          }
        >
          {t("Reconectar")}
        </Button>
      )}
    </div>
  );
}
