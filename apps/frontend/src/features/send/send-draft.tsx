import { createContext, useState, type ReactNode } from "react";
export type SendDraft = {
  selected: string;
  destination: string;
  amount: string;
  rate: string;
};
export const SendDraftContext = createContext<{
  draft: SendDraft | null;
  save: (value: SendDraft | null) => void;
}>({ draft: null, save: () => {} });
export function SendDraftProvider({ children }: { children: ReactNode }) {
  const [draft, save] = useState<SendDraft | null>(null);
  return (
    <SendDraftContext.Provider value={{ draft, save }}>
      {children}
    </SendDraftContext.Provider>
  );
}
