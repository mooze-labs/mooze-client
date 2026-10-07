import { createContext, useContext } from "react";
/** Populated only from the native host's immutable build configuration. */
export const NetworkContext = createContext<string>("");
export const useNetwork = () => useContext(NetworkContext);
export function NetworkLabel() {
  return <>{useNetwork()}</>;
}
