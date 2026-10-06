import { useEffect, useRef, useState } from "react";
import { Check, Copy } from "lucide-react";
import { Button } from "./button";
import { useT } from "../i18n/messages";
export function CopyButton({
  value,
  label,
  className,
}: {
  value: string;
  label: string;
  className?: string;
}) {
  const t = useT();
  const [status, setStatus] = useState<"idle" | "copied" | "error">("idle");
  const [busy, setBusy] = useState(false);
  const generation = useRef(0);
  useEffect(() => {
    generation.current++;
    setStatus("idle");
    setBusy(false);
    return () => {
      generation.current++;
    };
  }, [value]);
  useEffect(() => {
    if (status !== "copied") return;
    const timer = setTimeout(() => setStatus("idle"), 2000);
    return () => clearTimeout(timer);
  }, [status]);
  async function copy() {
    if (busy) return;
    const current = generation.current;
    setBusy(true);
    setStatus("idle");
    try {
      await navigator.clipboard.writeText(value);
      if (current === generation.current) setStatus("copied");
    } catch {
      if (current === generation.current) setStatus("error");
    } finally {
      if (current === generation.current) setBusy(false);
    }
  }
  return (
    <span className="copy-control">
      <Button
        className={className}
        disabled={busy}
        onClick={() => void copy()}
        aria-label={label}
        data-copied={status === "copied"}
      >
        {status === "copied" ? (
          <Check size={16} aria-hidden="true" />
        ) : (
          <Copy size={16} aria-hidden="true" />
        )}
        {label}
      </Button>
      <span className="copy-feedback" role="status">
        {status === "copied"
          ? t("Copiado")
          : status === "error"
            ? t("Não foi possível copiar. Selecione o texto.")
            : ""}
      </span>
    </span>
  );
}
