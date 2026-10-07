import { useState, useEffect, useId, useRef } from "react";
import type { DesktopClient } from "../../core/client";
import { Button, Field } from "../../ui";
import { Textarea } from "../../ui/textarea";
import { useT } from "../../i18n/messages";
import { normalizeWords, validWordCount } from "./setup-state";
export function ImportPhrase({
  client,
  words,
  onChange,
  busy,
}: {
  client: DesktopClient;
  words: string[];
  onChange: (words: string[]) => void;
  busy: boolean;
}) {
  const t = useT();
  const [text, setText] = useState("");
  const [dictionary, setDictionary] = useState<string[]>([]);
  const suggestionsId = useId();
  const textarea = useRef<HTMLTextAreaElement>(null);
  const firstWord = useRef<HTMLInputElement>(null);
  const numbered = words.length > 0;
  const previousEditor = useRef(numbered);
  useEffect(() => {
    if (previousEditor.current === numbered) return;
    previousEditor.current = numbered;
    (numbered ? firstWord.current : textarea.current)?.focus();
  }, [numbered]);
  useEffect(() => {
    let active = true;
    void client
      .recoveryWords()
      .then((words) => {
        if (active) setDictionary(words);
      })
      .catch(() => {});
    return () => {
      active = false;
    };
  }, [client]);
  return (
    <>
      <datalist id={suggestionsId}>
        {dictionary.map((word) => (
          <option key={word} value={word} />
        ))}
      </datalist>
      <h1>{t("Importar carteira")}</h1>
      <p>
        {t(
          "Digite ou cole sua frase de recuperação. Confira a ordem antes de continuar.",
        )}
      </p>
      <p className="small muted">
        {t(
          "Use palavras em inglês. Carteiras com uma senha adicional à frase não são compatíveis.",
        )}
      </p>
      {words.length === 0 ? (
        <>
          <label className="field">
            <span>{t("Frase de recuperação")}</span>
            <Textarea
              ref={textarea}
              aria-label={t("Frase de recuperação")}
              autoComplete="off"
              autoCapitalize="none"
              spellCheck={false}
              value={text}
              onChange={(e) => setText(e.target.value)}
              rows={4}
              disabled={busy}
            />
          </label>
          <Button
            disabled={busy || !text.trim()}
            onClick={() => {
              onChange(normalizeWords(text));
              setText("");
            }}
          >
            {t("Organizar palavras")}
          </Button>
          <p className="small muted">
            {t("Cole com Ctrl+V ou ⌘V. A frase é verificada neste computador.")}
          </p>
        </>
      ) : (
        <>
          <p role="status">{t("{count} palavras", { count: words.length })}</p>
          {!validWordCount(words.length) && (
            <p className="small">
              {t("Use uma frase de 12, 15, 18, 21 ou 24 palavras.")}
            </p>
          )}
          <div className="import-word-grid">
            {words.map((word, index) => (
              <Field
                key={index}
                ref={index === 0 ? firstWord : undefined}
                label={t("Palavra {number}", { number: index + 1 })}
                value={word}
                list={suggestionsId}
                autoComplete="off"
                autoCapitalize="none"
                spellCheck={false}
                disabled={busy}
                required
                onChange={(e) =>
                  onChange(
                    words.map((old, i) =>
                      i === index ? e.target.value.trim().toLowerCase() : old,
                    ),
                  )
                }
              />
            ))}
          </div>
          <Button
            disabled={busy}
            onClick={() => {
              setText(words.join(" "));
              onChange([]);
            }}
          >
            {t("Editar frase completa")}
          </Button>
        </>
      )}
    </>
  );
}
