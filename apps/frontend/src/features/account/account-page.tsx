import { useQuery } from "@tanstack/react-query";
import { Award } from "lucide-react";
import { useWalletClient } from "../../app/client-context";
import { useWalletSession } from "../../app/session-provider";
import { usePreferences } from "../../i18n/preferences";
import { useT } from "../../i18n/messages";
import { Button } from "../../ui";
import { PageHeader } from "../../ui/page-header";
const tierNames: Record<string, string> = {
  bronze: "Bronze",
  silver: "Prata",
  gold: "Ouro",
  diamond: "Diamante",
};
export function AccountPage() {
  const t = useT();
  const client = useWalletClient();
  const { session } = useWalletSession();
  const { preferences } = usePreferences();
  const query = useQuery({
    queryKey: ["wallet", session?.generation, "account-level"],
    queryFn: () => client.accountLevel(),
    enabled: session?.status === "unlocked",
    staleTime: 60_000,
    retry: false,
  });
  const money = (value: number) =>
    new Intl.NumberFormat(preferences.locale, {
      style: "currency",
      currency: "BRL",
    }).format(value);
  const name = (key: string) => t(tierNames[key] ?? key);
  const data = query.data;
  return (
    <section className="flow-page account-page">
      <PageHeader
        title={t("Nível da conta")}
        description={t("Seu nível e seus limites para receber com Pix.")}
        actions={
          <Button
            disabled={query.isFetching}
            onClick={() => void query.refetch()}
          >
            {t("Atualizar")}
          </Button>
        }
      />
      {data && (
        <p className="account-id">
          <span className="muted">{t("ID da conta")}</span>
          <code>{data.user_id}</code>
        </p>
      )}
      {query.isPending && (
        <p role="status">{t("Carregando nível da conta…")}</p>
      )}
      {query.isError && (
        <p className="notice" role="status">
          {t(
            data
              ? "Não foi possível atualizar. Os limites abaixo podem estar desatualizados."
              : "Não foi possível carregar seu nível. Tente novamente.",
          )}
        </p>
      )}
      {data && (
        <>
          <section className="card account-level-summary">
            <span className="account-level-icon" aria-hidden="true">
              <Award size={28} />
            </span>
            <div>
              <p className="eyebrow">{t("Nível atual")}</p>
              <h2>{name(data.current_level)}</h2>
            </div>
            <div className="account-progress">
              {data.next_level ? (
                <>
                  <div className="card-top">
                    <span>
                      {t("Próximo nível")}: {name(data.next_level)}
                    </span>
                    <span>
                      {new Intl.NumberFormat(preferences.locale, {
                        style: "percent",
                        maximumFractionDigits: 0,
                      }).format(data.progress)}
                    </span>
                  </div>
                  <progress
                    aria-label={t("Progresso do nível")}
                    max={1}
                    value={data.progress}
                  />
                </>
              ) : (
                <p>{t("Você está no nível mais alto.")}</p>
              )}
              <p className="muted small">
                {t("O nível e a progressão são definidos pelo serviço Mooze.")}
              </p>
            </div>
          </section>
          <section className="section-gap">
            <h2>{t("Todos os níveis")}</h2>
            <div className="account-tiers">
              {data.tiers.map((tier) => (
                <article
                  className="card"
                  key={tier.key}
                  data-current={tier.key === data.current_level}
                >
                  <div className="card-top">
                    <h3>{name(tier.key)}</h3>
                    {tier.key === data.current_level && (
                      <span className="muted small">{t("Atual")}</span>
                    )}
                  </div>
                  <p className="muted small">{t("Faixa por transação")}</p>
                  <p>
                    {money(tier.minimum_brl)} – {money(tier.maximum_brl)}
                  </p>
                </article>
              ))}
            </div>
          </section>
        </>
      )}
    </section>
  );
}
