import { useT } from "../i18n/messages";
import type { ReactNode } from "react";
export { Button } from "./button";
export { Field } from "./field";
export { Modal } from "./dialog";
export function ErrorNotice({ children }: { children: ReactNode }) {
  const t = useT();
  return children ? (
    <div className="alert error" role="alert">
      {typeof children === "string" ? t(children) : children}
    </div>
  ) : null;
}
