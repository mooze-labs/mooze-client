import {useT} from "../i18n/messages";
import { createContext, useContext, type ReactNode } from "react";
export const PrivacyContext = createContext(false);
export function SensitiveValue({
  children,
  hidden,
  className = "mono",
}: {
  children: ReactNode;
  hidden?: boolean;
  className?: string;
}) {
 const t=useT();
  const privacy = useContext(PrivacyContext);
  return (hidden ?? privacy) ? (
    <span className={className} aria-label={t("Valor oculto")}>
      ••••••
    </span>
  ) : (
    <span className={className}>{children}</span>
  );
}
