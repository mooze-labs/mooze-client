import { useId, useState } from "react";
import { Button, Modal } from "../../ui";
import { Checkbox } from "../../ui/checkbox";
import { useT } from "../../i18n/messages";

// Pre-release placeholder. Replace this content with approved desktop terms
// and remove the provisional labels before releasing the desktop application.
const placeholderParagraphs = [
  "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.",
  "Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.",
  "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Integer posuere erat a ante venenatis dapibus posuere velit aliquet. Donec ullamcorper nulla non metus auctor fringilla. Maecenas faucibus mollis interdum.",
];

export function SetupTerms({
  accepted,
  onAcceptedChange,
}: {
  accepted: boolean;
  onAcceptedChange: (accepted: boolean) => void;
}) {
  const t = useT();
  const [open, setOpen] = useState(false);
  const id = useId();
  return (
    <div className="setup-terms">
      <Button className="ghost" onClick={() => setOpen(true)}>
        {t("Ler termos e condições")}
      </Button>
      <p className="small muted" id={`${id}-notice`}>
        {t(
          "Termos provisórios com Lorem Ipsum, apenas para testes antes do lançamento.",
        )}
      </p>
      <div className="setup-terms-acceptance">
        <Checkbox
          id={id}
          checked={accepted}
          onCheckedChange={onAcceptedChange}
          aria-describedby={`${id}-notice`}
        />
        <label htmlFor={id}>
          {t("Li e aceito os termos e condições provisórios.")}
        </label>
      </div>
      <Modal
        title={t("Termos e condições — versão provisória")}
        description={t(
          "Conteúdo provisório para testes. Estes não são os termos finais e serão substituídos antes do lançamento.",
        )}
        open={open}
        onOpenChange={setOpen}
        className="modal setup-terms-dialog"
      >
        <div
          className="setup-terms-body"
          tabIndex={0}
          role="region"
          aria-label={t("Texto provisório dos termos")}
        >
          {placeholderParagraphs.map((paragraph, index) => (
            <p lang="la" key={index}>
              {paragraph}
            </p>
          ))}
        </div>
        <Button onClick={() => setOpen(false)}>{t("Fechar")}</Button>
      </Modal>
    </div>
  );
}
