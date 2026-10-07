import { createContext, useContext } from "react";
/** Populated only from the native host's immutable build configuration. */
export const NetworkContext = createContext<string>("");
export const useNetwork = () => useContext(NetworkContext);
/** Only non-production environments need a visible qualifier. */
export const networkLabel = (network?: string) =>
  network === "Mainnet" ? "" : (network ?? "");
export const useNetworkLabel = () => networkLabel(useNetwork());
export function NetworkLabel() {
  return <>{useNetworkLabel()}</>;
}
