import { createContext, useContext, type ReactNode } from "react";
import type { DesktopClient } from "../core/client";
const Context = createContext<DesktopClient | null>(null);
export function WalletClientProvider({client, children}: {client: DesktopClient; children: ReactNode}) {
  return <Context.Provider value={client}>{children}</Context.Provider>;
}
export function useWalletClient(): DesktopClient {
  const client = useContext(Context);
  if (!client) throw new Error("WalletClientProvider is required");
  return client;
}
