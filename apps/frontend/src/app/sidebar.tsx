import { useState, type ReactNode, type ReactElement } from "react";
import { NavLink } from "react-router-dom";
import { Tooltip } from "@base-ui/react/tooltip";
import {
  Wallet,
  QrCode,
  ArrowLeftRight,
  Clock,
  UserRound,
  Settings,
  PanelLeftClose,
  PanelLeftOpen,
} from "lucide-react";
import { useT } from "../i18n/messages";
import { Button } from "../ui";

const storageKey = "mooze.sidebar";
const links = [
  ["/", "Carteira", Wallet],
  ["/pix", "Pix", QrCode],
  ["/swap", "Trocar", ArrowLeftRight],
  ["/history", "Atividade", Clock],
  ["/account", "Conta", UserRound],
  ["/settings", "Ajustes", Settings],
] as const;
function initialCompact() {
  try {
    const saved = localStorage.getItem(storageKey);
    if (saved === "compact" || saved === "expanded") return saved === "compact";
  } catch {
    /* The layout remains usable without browser storage. */
  }
  return window.matchMedia?.("(max-width: 1100px)").matches ?? false;
}
export function SidebarHint({
  label,
  children,
  enabled = true,
}: {
  label: string;
  children: ReactElement;
  enabled?: boolean;
}) {
  return (
    <Tooltip.Root>
      <Tooltip.Trigger render={children} disabled={!enabled} delay={250} />
      <Tooltip.Portal>
        <Tooltip.Positioner side="right" sideOffset={10}>
          <Tooltip.Popup className="sidebar-tooltip">{label}</Tooltip.Popup>
        </Tooltip.Positioner>
      </Tooltip.Portal>
    </Tooltip.Root>
  );
}
export function SidebarLayout({
  children,
  footer,
}: {
  children: ReactNode;
  footer: (compact: boolean) => ReactNode;
}) {
  const t = useT();
  const [compact, setCompact] = useState(initialCompact);
  const toggleLabel = t(
    compact ? "Expandir barra lateral" : "Recolher barra lateral",
  );
  function toggle() {
    const next = !compact;
    setCompact(next);
    try {
      localStorage.setItem(storageKey, next ? "compact" : "expanded");
    } catch {
      /* Persistence is optional. */
    }
  }
  return (
    <Tooltip.Provider>
      <div className="shell" data-sidebar={compact ? "compact" : "expanded"}>
        <aside aria-label={t("Navegação principal")}>
          <div className="sidebar-heading">
            <div className="wordmark" aria-label="mooze">
              <span className="sidebar-brand" aria-hidden="true">
                {compact ? "m" : "mooze"}
              </span>
              <span aria-hidden="true">●</span>
            </div>
            <SidebarHint label={toggleLabel}>
              <Button
                className="ghost sidebar-toggle"
                aria-label={toggleLabel}
                aria-expanded={!compact}
                aria-controls="wallet-navigation"
                onClick={toggle}
              >
                {compact ? (
                  <PanelLeftOpen size={18} />
                ) : (
                  <PanelLeftClose size={18} />
                )}
              </Button>
            </SidebarHint>
          </div>
          <nav id="wallet-navigation" aria-label={t("Navegação principal")}>
            {links.map(([to, label, Icon]) => (
              <SidebarHint key={to} label={t(label)} enabled={compact}>
                <NavLink to={to} end={to === "/"} aria-label={t(label)}>
                  <Icon size={18} aria-hidden="true" />
                  <span className="sidebar-label">{t(label)}</span>
                </NavLink>
              </SidebarHint>
            ))}
          </nav>
          <footer>{footer(compact)}</footer>
        </aside>
        {children}
      </div>
    </Tooltip.Provider>
  );
}
