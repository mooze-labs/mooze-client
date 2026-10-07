import { Check } from "lucide-react";
import { useT } from "../../i18n/messages";
export function SetupProgress({
  step,
  importing = false,
}: {
  step: number;
  importing?: boolean;
}) {
  const t = useT();
  const labels = importing
    ? ["Carteira", "Recuperação", "PIN", "Preparação"]
    : ["Carteira", "Recuperação", "Confirmação", "PIN", "Preparação"];
  return (
    <ol
      className="setup-progress"
      aria-label={t(importing ? "Importar carteira" : "Criar carteira")}
    >
      {labels.map((label, index) => (
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
