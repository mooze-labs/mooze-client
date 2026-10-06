import { Check } from "lucide-react";
import { useT } from "../../i18n/messages";
export function SetupProgress({ step }: { step: 0 | 1 | 2 }) {
  const t = useT();
  return (
    <ol className="setup-progress" aria-label={t("Criar carteira")}>
      {["Carteira", "Recuperação", "Confirmação"].map((label, index) => (
        <li
          key={label}
          aria-current={index === step ? "step" : undefined}
          data-complete={index < step}
        >
          <span className="step-marker" aria-hidden="true">
            {index < step ? <Check size={14} /> : index + 1}
          </span>
          <span>{t(label)}</span>
        </li>
      ))}
    </ol>
  );
}
