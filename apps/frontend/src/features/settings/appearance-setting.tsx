import { SelectField } from "../../ui/select-field";
import { useTheme } from "../../theme/theme-provider";
import { parseThemePreference } from "../../theme/model";
import { useT } from "../../i18n/messages";
export function AppearanceSetting() {
  const { preference, setPreference, persistenceError } = useTheme();
  const t = useT();
  return (
    <>
      <SelectField
        label={t("Aparência")}
        value={preference}
        onValueChange={(value) => setPreference(parseThemePreference(value))}
        items={[
          { value: "system", label: t("Sistema") },
          { value: "light", label: t("Claro") },
          { value: "dark", label: t("Escuro") },
        ]}
      />
      {persistenceError && (
        <p role="status" className="muted">
          {t(
            "Não foi possível salvar a aparência. A alteração vale apenas para esta sessão.",
          )}
        </p>
      )}
    </>
  );
}
