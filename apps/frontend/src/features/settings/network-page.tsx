import { Checkbox } from "../../ui/checkbox";
import { SelectField } from "../../ui/select-field";
import {
  reduceNetworkDraft,
  emptyNetworkDraft,
  isNetworkDirty,
} from "./network-draft";
import { useT } from "../../i18n/messages";
import { useEffect, useReducer, useState } from "react";
import { useQuery, useQueryClient } from "@tanstack/react-query";
import { useWalletClient } from "../../app/client-context";
import { useWalletSession } from "../../app/session-provider";
import { Button, Field, ErrorNotice } from "../../ui";
import { errorText, type Chain } from "../../core/client";
export function NetworkPage({
  onDirtyChange = () => {},
}: {
  onDirtyChange?: (dirty: boolean) => void;
}) {
  const t = useT();
  const client = useWalletClient();
  const { session } = useWalletSession();
  const qc = useQueryClient();
  const settings = useQuery({
    queryKey: ["wallet", session?.generation, "settings"],
    queryFn: () => client.settings(),
  });
  const [chain, setChain] = useState<Chain>("Bitcoin");
  const [draft, dispatch] = useReducer(reduceNetworkDraft, emptyNetworkDraft);
  const endpoint = draft.endpoints[chain];
  const fallback = draft.fallback;
  const setEndpoint = (value: string) =>
    dispatch({ type: "editEndpoint", chain, value });
  const setFallback = (value: boolean) =>
    dispatch({ type: "editFallback", value });
  const [busy, setBusy] = useState(false);
  const [message, setMessage] = useState("");
  const [error, setError] = useState("");
  useEffect(() => {
    if (settings.data) dispatch({ type: "loaded", settings: settings.data });
  }, [settings.data]);
  useEffect(() => {
    onDirtyChange(isNetworkDirty(draft));
  }, [draft, onDirtyChange]);
  async function run(save: boolean, restore = false) {
    if (busy) return;
    setBusy(true);
    setError("");
    setMessage("");
    try {
      if (save) {
        const saved = await client.saveNode(
          chain,
          restore ? null : endpoint,
          fallback,
        );
        dispatch({ type: "saved", chain, settings: saved });
        await qc.invalidateQueries({ queryKey: ["wallet"] });
        setMessage(t("Nó salvo. Sincronizando novamente."));
      } else {
        await client.testNode(chain, endpoint);
        setMessage(t("Conexão e rede de teste verificadas."));
      }
    } catch (e) {
      setError(errorText(e));
    } finally {
      setBusy(false);
    }
  }
  return (
    <section className="card section-gap">
      <h2>{t("Conexões de rede")}</h2>
      <p>
        {t(
          "Bitcoin testnet3 e Liquid testnet. O nó recebe as consultas públicas da carteira.",
        )}
      </p>
      <ErrorNotice>
        {error || (settings.error ? errorText(settings.error) : "")}
      </ErrorNotice>
      <SelectField
        label={t("Rede")}
        disabled={busy}
        value={chain}
        onValueChange={(value) => {
          setChain(value as Chain);
          setMessage("");
          setError("");
        }}
        items={[
          { value: "Bitcoin", label: <>{t("Bitcoin")}</> },
          { value: "Liquid", label: <>{t("Liquid")}</> },
        ]}
      />
      <Field
        label={t("Nó Electrum personalizado")}
        placeholder="ssl://host:port"
        value={endpoint}
        disabled={busy || !settings.data}
        onChange={(e) => {
          setEndpoint(e.target.value);
          setMessage("");
        }}
        help={t("Deixe vazio para usar os servidores padrão de testnet.")}
      />
      <label className="checkbox-row">
        <Checkbox
          checked={fallback}
          disabled={busy}
          onCheckedChange={setFallback}
        />
        {t(
          "Permitir servidores públicos se um nó personalizado falhar (ambas as redes)",
        )}
      </label>
      <p className="muted small">
        {t("Sem esta opção, consultas ficam restritas ao nó personalizado.")}
      </p>
      <div className="actions">
        <Button
          disabled={busy || !endpoint.trim()}
          onClick={() => void run(false)}
        >
          {t("Testar conexão")}
        </Button>
        <Button
          disabled={busy || !settings.data}
          onClick={() => void run(true)}
        >
          {t("Salvar e reconectar")}
        </Button>
        <Button
          disabled={busy || !settings.data}
          onClick={() => void run(true, true)}
        >
          {t("Restaurar padrão")}
        </Button>
      </div>
      <p role="status">{busy ? t("Verificando conexão…") : message}</p>
    </section>
  );
}
