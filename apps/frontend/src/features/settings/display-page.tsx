import { AnalyticsSetting } from "../../analytics/analytics-setting";
import { AppearanceSetting } from "./appearance-setting";
import { SelectField } from "../../ui/select-field";
import { SwitchField } from "../../ui/switch-field";
import { useT } from "../../i18n/messages";
import { useState } from "react";
import { usePreferences, type Preferences } from "../../i18n/preferences";
import { ErrorNotice } from "../../ui";
import { errorText } from "../../core/client";
export function DisplayPage() {
  const t = useT();
  const { preferences, save } = usePreferences();
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState("");
  async function update(next: Preferences) {
    setBusy(true);
    setError("");
    try {
      await save(next);
    } catch (e) {
      setError(errorText(e));
    } finally {
      setBusy(false);
    }
  }
  return (
    <section className="card section-gap display-settings">
      <h2>{t("Exibição")}</h2>
      <ErrorNotice>{error}</ErrorNotice>
      <AppearanceSetting />
      <AnalyticsSetting />
      <SelectField
        label={t("Idioma")}
        disabled={busy}
        value={preferences.locale}
        onValueChange={(value) =>
          void update({
            ...preferences,
            locale: value as Preferences["locale"],
          })
        }
        items={[
          { value: "pt-BR", label: <>{t("Português (Brasil)")}</> },
          { value: "en", label: <>{t("English")}</> },
          { value: "es", label: <>{t("Español")}</> },
        ]}
      />
      <SelectField
        label={t("Unidade Bitcoin")}
        disabled={busy}
        value={preferences.bitcoinUnit}
        onValueChange={(value) =>
          void update({
            ...preferences,
            bitcoinUnit: value as Preferences["bitcoinUnit"],
          })
        }
        items={[
          { value: "BTC", label: <>{t("BTC / L-BTC")}</> },
          { value: "sat", label: <>{t("sat")}</> },
        ]}
      />
      <p className="muted">
        {t(
          "A unidade selecionada se aplica a BTC e L-BTC. Ativos não listados usam unidades brutas.",
        )}
      </p>
      <SwitchField
        label={t("Ocultar valores")}
        disabled={busy}
        checked={preferences.privacy}
        onCheckedChange={(privacy) => void update({ ...preferences, privacy })}
      />
    </section>
  );
}
