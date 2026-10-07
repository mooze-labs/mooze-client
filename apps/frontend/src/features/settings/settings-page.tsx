import { PageHeader } from "../../ui/page-header";
import { useState } from "react";
import {
  Link,
  useSearchParams,
  useBlocker,
  useBeforeUnload,
} from "react-router-dom";
import { useT } from "../../i18n/messages";
import { Button, Modal } from "../../ui";
import { DisplayPage } from "./display-page";
import { SecurityPage } from "./security-page";
import { NetworkPage } from "./network-page";
import { AboutPage } from "./about-page";
const sections = [
  ["general", "Geral"],
  ["security", "Segurança"],
  ["network", "Rede"],
  ["about", "Sobre"],
] as const;
export function SettingsPage() {
  const t = useT();
  const [params] = useSearchParams();
  const section = params.get("section") ?? "general";
  const [dirty, setDirty] = useState(false);
  const [draftKey, setDraftKey] = useState(0);
  const blocker = useBlocker(
    ({ currentLocation, nextLocation }) =>
      dirty &&
      (currentLocation.pathname !== nextLocation.pathname ||
        currentLocation.search !== nextLocation.search),
  );
  useBeforeUnload((event) => {
    if (dirty) {
      event.preventDefault();
      event.returnValue = "";
    }
  });
  return (
    <div className="settings-page">
      <PageHeader title={t("Ajustes")} />
      <nav className="settings-tabs" aria-label={t("Ajustes")}>
        {sections.map(([key, label]) => (
          <Link
            key={key}
            className={section === key ? "selected" : ""}
            aria-current={section === key ? "page" : undefined}
            to={`/settings?section=${key}`}
          >
            {t(label)}
          </Link>
        ))}
      </nav>
      <div hidden={section !== "network"}>
        <NetworkPage key={draftKey} onDirtyChange={setDirty} />
      </div>
      {section === "security" ? (
        <SecurityPage />
      ) : section === "about" ? (
        <AboutPage />
      ) : section !== "network" ? (
        <DisplayPage />
      ) : null}
      <Modal
        title={t("Descartar alterações?")}
        description={t("As alterações de rede ainda não foram salvas.")}
        open={blocker.state === "blocked"}
        onOpenChange={(open) => {
          if (!open && blocker.state === "blocked") blocker.reset();
        }}
      >
        <div className="actions">
          <Button
            onClick={() => blocker.state === "blocked" && blocker.reset()}
          >
            {t("Continuar editando")}
          </Button>
          <Button
            className="danger"
            onClick={() => {
              setDirty(false);
              setDraftKey((v) => v + 1);
              if (blocker.state === "blocked") blocker.proceed();
            }}
          >
            {t("Descartar alterações")}
          </Button>
        </div>
      </Modal>
    </div>
  );
}
