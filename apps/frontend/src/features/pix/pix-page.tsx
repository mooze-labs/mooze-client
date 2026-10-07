import { QrCode, RefreshCw } from "lucide-react";
import { LoadingRows } from "../../ui/loading-rows";
import { formatTaxId, taxIdDigits, formatBrlInput } from "./pix-input";
import { useState } from "react";
import { useQuery, useQueryClient } from "@tanstack/react-query";
import { useWalletClient } from "../../app/client-context";
import { useWalletSession } from "../../app/session-provider";
import { useT } from "../../i18n/messages";
import { Button, Field, ErrorNotice } from "../../ui";
import { AssetMark } from "../../ui/asset-mark";
import { SelectField } from "../../ui/select-field";
import { SensitiveValue } from "../../ui/sensitive-value";
import { errorText } from "../../core/client";
import type { PixDepositViewDto } from "../../core/desktop.generated";
import { parseBrlCents, depositStage, formatBrlCents } from "./pix-state";
import { PixPayment, statusLabels } from "./pix-payment";
export function PixPage() {
  const t = useT();
  const client = useWalletClient();
  const { session } = useWalletSession();
  const qc = useQueryClient();
  const prefix = ["wallet", session?.generation];
  const host = useQuery({
    queryKey: ["host"],
    queryFn: () => client.hostInfo(),
  });
  const enabled = host.data?.pix_enabled === true;
  const backend = useQuery({
    queryKey: [...prefix, "backend"],
    queryFn: () => client.backendStatus(),
    enabled,
    retry: false,
  });
  const history = useQuery({
    queryKey: [...prefix, "pix"],
    queryFn: () => client.pixHistory(),
    enabled,
    refetchInterval: 30_000,
    retry: false,
  });
  const catalog = useQuery({
    queryKey: [...prefix, "approvedAssets"],
    queryFn: () => client.approvedAssets(),
    enabled,
  });
  const assets =
    catalog.data?.filter(
      (a) => a.key.chain === "Liquid" && a.approved && a.ticker !== "USDT",
    ) ?? [];
  const [asset, setAsset] = useState("");
  const selected =
    assets.find((a) => a.key.asset_id === asset)?.key.asset_id ||
    assets.find((a) => a.ticker === "DEPIX")?.key.asset_id ||
    assets[0]?.key.asset_id ||
    "";
  const [amount, setAmount] = useState("");
  const [tax, setTax] = useState("");
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState("");
  const [deposit, setDeposit] = useState<PixDepositViewDto | null>(null);
  const current =
    history.data?.deposits.find((d) => d.deposit_id === deposit?.deposit_id) ??
    deposit;
  const cents = parseBrlCents(amount);
  const [touched, setTouched] = useState({ amount: false, tax: false });
  const taxValid = /^\d{11}$|^\d{14}$/.test(taxIdDigits(tax));
  const unavailable =
    backend.data?.state !== "Ready"
      ? t("Conecte ao backend para usar Pix.")
      : history.data?.creation_uncertain
        ? t("Confira a solicitação anterior no histórico antes de continuar.")
        : current
          ? t(
              "Sua solicitação está aberta ao lado. Para começar outra, escolha Nova solicitação.",
            )
          : !cents || !taxValid
            ? t("Informe o valor e o CPF ou CNPJ completo do pagador.")
            : !selected
              ? t("Aguardando ativos disponíveis.")
              : "";
  async function create() {
    if (busy || !cents || !taxValid || !selected) return;
    setBusy(true);
    setError("");
    try {
      setDeposit(
        await client.pixCreate({
          amount_in_cents: cents,
          asset_id: selected,
          tax_id_number: taxIdDigits(tax),
        }),
      );
      await qc.invalidateQueries({ queryKey: [...prefix, "pix"] });
    } catch (e) {
      setError(errorText(e));
      await history.refetch();
    } finally {
      setBusy(false);
    }
  }
  if (host.isPending) return <p>{t("Carregando…")}</p>;
  if (!enabled)
    return (
      <section>
        <h1>Pix</h1>
        <p>{t("Pix está disponível apenas na mainnet.")}</p>
        <ErrorNotice>{host.error ? errorText(host.error) : ""}</ErrorNotice>
      </section>
    );
  return (
    <section className="flow-page">
      <div className="page-heading">
        <h1>{t("Receber com Pix")}</h1>
        <Button
          className="ghost"
          disabled={history.isFetching}
          onClick={() => void history.refetch()}
        >
          <RefreshCw size={15} aria-hidden="true" />
          {t(history.isFetching ? "Atualizando…" : "Atualizar")}
        </Button>
      </div>
      <p className="muted">
        {t("Pague em reais e receba ativos na sua carteira Liquid.")}
      </p>
      <ErrorNotice>
        {error ||
          (history.error ? errorText(history.error) : "") ||
          (catalog.error ? errorText(catalog.error) : "")}
      </ErrorNotice>
      {backend.data?.state !== "Ready" && (
        <p className="notice">{t("Conecte ao backend para usar Pix.")}</p>
      )}
      {history.data?.creation_uncertain && (
        <div className="notice">
          <p>
            {t(
              "Uma solicitação pode ter sido criada. Confira seu histórico antes de criar outra.",
            )}
          </p>
          <Button
            disabled={busy}
            onClick={() => {
              setBusy(true);
              void client
                .pixAcknowledgeUncertain()
                .then(() => history.refetch())
                .catch((e) => setError(errorText(e)))
                .finally(() => setBusy(false));
            }}
          >
            {t("Conferi o histórico; permitir nova solicitação")}
          </Button>
        </div>
      )}
      <div className="service-columns">
        <form
          className="card pix-form"
          onSubmit={(e) => {
            e.preventDefault();
            void create();
          }}
        >
          <h2>{t("Novo Pix")}</h2>
          <Field
            label={t("Valor em reais")}
            inputMode="decimal"
            value={amount}
            placeholder="0,00"
            required
            autoComplete="off"
            aria-invalid={touched.amount && !!amount && !cents}
            help={
              touched.amount && !!amount && !cents
                ? t(
                    "Informe um valor maior que zero, com até duas casas decimais.",
                  )
                : t("Valor em BRL · R$")
            }
            onBlur={() => setTouched((old) => ({ ...old, amount: true }))}
            onChange={(e) => setAmount(formatBrlInput(e.target.value))}
            disabled={busy}
          />
          <SelectField
            label={t("Ativo a receber")}
            value={selected}
            items={assets.map((a) => ({
              value: a.key.asset_id!,
              label: (
                <span className="swap-asset-label">
                  <AssetMark metadata={a} />
                  <span>{a.ticker || a.key.asset_id}</span>
                </span>
              ),
            }))}
            onValueChange={setAsset}
            disabled={busy}
          />
          <Field
            label={t("CPF ou CNPJ do pagador")}
            required
            value={tax}
            inputMode="numeric"
            autoComplete="off"
            aria-invalid={touched.tax && !!tax && !taxValid}
            help={
              touched.tax && !!tax && !taxValid
                ? t("Use 11 dígitos para CPF ou 14 para CNPJ.")
                : t("Documento de quem fará o pagamento.")
            }
            onBlur={() => setTouched((old) => ({ ...old, tax: true }))}
            onChange={(e) => setTax(formatTaxId(e.target.value))}
            disabled={busy}
          />
          <p className="muted small">
            {t("Taxas e limites são definidos pelo serviço Pix.")}
          </p>
          <div className="flow-actions">
            <Button
              className="primary"
              aria-describedby="pix-availability"
              type="submit"
              disabled={
                busy ||
                !cents ||
                !taxValid ||
                !selected ||
                backend.data?.state !== "Ready" ||
                !!history.data?.creation_uncertain ||
                !!current
              }
            >
              {t(busy ? "Criando…" : "Criar Pix")}
            </Button>
            {current && (
              <Button
                type="button"
                className="ghost"
                onClick={() => setDeposit(null)}
              >
                {t("Nova solicitação")}
              </Button>
            )}
          </div>
          <p id="pix-availability" className="form-guidance muted small">
            {unavailable}
          </p>
        </form>
        {current ? (
          <PixPayment key={current.deposit_id} deposit={current} />
        ) : (
          <div className="pix-placeholder">
            <span className="receipt-symbol" aria-hidden="true">
              <QrCode size={28} />
            </span>
            <h2>{t("Seu Pix começa aqui")}</h2>
            <p className="muted">
              {t(
                "Preencha os dados para gerar um QR code. Depois, acompanhe o pagamento e a entrega dos ativos neste espaço.",
              )}
            </p>
          </div>
        )}
      </div>
      <section className="card">
        <h2>{t("Histórico Pix")}</h2>
        {history.isPending ? (
          <LoadingRows label={t("Carregando…")} rows={2} />
        ) : !history.data?.deposits.length ? (
          <p className="muted">{t("Nenhuma solicitação Pix ainda.")}</p>
        ) : (
          <div className="service-history">
            {history.data.deposits.map((d) => (
              <Button
                className="ghost service-history-row"
                key={d.deposit_id}
                onClick={() => setDeposit(d)}
              >
                <span>{new Date(d.created_at_ms).toLocaleDateString()}</span>
                <SensitiveValue>
                  {formatBrlCents(d.amount_in_cents)}
                </SensitiveValue>
                <span
                  className="status-label"
                  data-stage={depositStage(d.status)}
                >
                  {t(statusLabels[depositStage(d.status)])}
                </span>
              </Button>
            ))}
          </div>
        )}
      </section>
    </section>
  );
}
