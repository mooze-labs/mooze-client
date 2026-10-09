import { SwitchField } from "../ui/switch-field";
import { useT } from "../i18n/messages";
import { ErrorNotice } from "../ui";
import { analytics } from "./runtime";
import { useAnalyticsState } from "./react";

export function AnalyticsSetting() {
  const t = useT();
  const state = useAnalyticsState();
  if (!state.available) return null;
  return (
    <div className="section-gap">
      <SwitchField
        label={t("Compartilhar dados de uso (opcional)")}
        checked={state.enabled}
        disabled={state.busy}
        onCheckedChange={(value) => void analytics.setEnabled(value)}
      />
      <p className="muted">
        {t(
          "Ajude a melhorar o Mooze enviando ao PostHog telas visitadas e resultados de ações, com um identificador aleatório. Não enviamos sua frase, PIN, endereços, saldos ou valores. Sem gravação de tela. Você pode desativar a qualquer momento nos Ajustes.",
        )}
      </p>
      <ErrorNotice>
        {state.error
          ? t(
              "Não foi possível atualizar a preferência de dados de uso. Tente novamente.",
            )
          : ""}
      </ErrorNotice>
    </div>
  );
}
