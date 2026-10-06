import { SelectField } from "../../ui/select-field";
import { SecurityDialog } from "./security-dialog";
import { useT } from "../../i18n/messages";
import { useState, type FormEvent } from "react";
import { useQuery, useQueryClient } from "@tanstack/react-query";
import { useWalletClient } from "../../app/client-context";
import { useWalletSession } from "../../app/session-provider";
import { Button, Field, ErrorNotice } from "../../ui";
import { errorText } from "../../core/client";
export function SecurityPage() {
  const t = useT();
  const client = useWalletClient();
  const { session } = useWalletSession();
  const qc = useQueryClient();
  const settings = useQuery({
    queryKey: ["wallet", session?.generation, "settings"],
    queryFn: () => client.settings(),
  });
  const [dialog, setDialog] = useState<"pin" | "recovery" | null>(null);
  const [error, setError] = useState("");
  const [busy, setBusy] = useState(false);
  return (
    <>
      <section className="card">
        <h1>{t("Segurança e recuperação")}</h1>
        <ErrorNotice>
          {error || (settings.error ? errorText(settings.error) : "")}
        </ErrorNotice>
        <SelectField
          label={t("Bloqueio automático")}
          value={settings.data?.lock_minutes ?? 1}
          disabled={busy || !settings.data}
          onValueChange={(value) => {
            setBusy(true);
            void client
              .setLockMinutes(Number(value))
              .then((s) =>
                qc.setQueryData(["wallet", session?.generation, "settings"], s),
              )
              .catch((value) => setError(errorText(value)))
              .finally(() => setBusy(false));
          }}
          items={[
            ...([1, 5, 15, 30, 60].map((m) => ({
              value: String(m),
              label: <>{t("{minutes} min", { minutes: m })}</>,
            })) ?? []),
          ]}
        />
        <p className="muted">
          {t(
            "Aplica-se à inatividade e ao tempo em segundo plano. A sincronização continua com a carteira bloqueada.",
          )}
        </p>
        <Button
          onClick={() =>
            void client.lock().catch((e) => setError(errorText(e)))
          }
        >
          {t("Bloquear agora")}
        </Button>
      </section>
      <section className="settings-row">
        <div>
          <h2>{t("Frase de recuperação")}</h2>
          <p className="muted">
            {t(
              "Confirme seu PIN para visualizar sua frase. Não compartilhe estas palavras.",
            )}
          </p>
        </div>
        <Button onClick={() => setDialog("recovery")}>
          {t("Ver frase de recuperação")}
        </Button>
      </section>
      <section className="settings-row">
        <h2>{t("Alterar PIN")}</h2>
        <Button onClick={() => setDialog("pin")}>{t("Alterar PIN")}</Button>
      </section>
      <SecurityDialog
        kind={dialog ?? "pin"}
        open={dialog !== null}
        onOpenChange={(open) => {
          if (!open) setDialog(null);
        }}
      />
    </>
  );
}
