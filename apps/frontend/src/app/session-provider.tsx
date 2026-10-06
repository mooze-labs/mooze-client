import {createContext, useContext, useCallback, useEffect, useRef, useState, type ReactNode, type MutableRefObject} from "react";
import {useQuery, useQueryClient} from "@tanstack/react-query";
import {errorText, type Session} from "../core/client";
import {useWalletClient} from "./client-context";
type SessionContext = {session: Session | null; current: MutableRefObject<Session | null>; startupError: string; update: (session: Session) => void; setStartupError: (error: string) => void};
const Context = createContext<SessionContext | null>(null);
export function SessionProvider({children}: {children: ReactNode}) {
  const client = useWalletClient();
  const qc = useQueryClient();
  const [session, setSession] = useState<Session | null>(null);
  const [startupError, setStartupError] = useState("");
  const current = useRef<Session | null>(null);
  const update = useCallback(
    (s: Session) => {
      if (current.current && s.generation < current.current.generation) return;
      current.current = s;
      setSession(s);
      if (s.status !== "unlocked") {
        void qc.cancelQueries({ queryKey: ["wallet"] });
        qc.removeQueries({ queryKey: ["wallet"] });
      }
    },
    [qc],
  );
  useEffect(() => {
    let disposed = false;
    let unlisten: (() => void) | undefined;
    void (async () => {
      try {
        unlisten = await client.subscribe((e) => {
          if (disposed) return;
          if (e.type === "session") {
            update(e.data);
          } else if (
            current.current?.status === "unlocked" &&
            e.generation === current.current.generation
          ) {
            void qc.invalidateQueries({ queryKey: ["wallet", e.generation] });
          }
        });
        if (disposed) {
          unlisten();
          return;
        }
        const s = await client.sessionStatus();
        if (!disposed) update(s);
      } catch (e) {
        if (!disposed) setStartupError(errorText(e));
      }
    })();
    return () => {
      disposed = true;
      unlisten?.();
    };
  }, [client, qc, update]);
  return <Context.Provider value={{session,current,startupError,update,setStartupError}}>{children}</Context.Provider>;
}
export function useWalletSession() {
  const value = useContext(Context);
  if (!value) throw new Error("SessionProvider is required");
  return value;
}
export function useWalletSnapshot() {
 const client = useWalletClient();
 const {session,current} = useWalletSession();
 return useQuery({
   queryKey: ["wallet", session?.generation, "snapshot"],
   queryFn: async () => {
     const generation = current.current?.generation;
     const data = await client.snapshot();
     if (current.current?.status !== "unlocked" || current.current.generation !== generation || data.generation !== generation)
       throw new Error("Sessão alterada.");
     return data;
   },
   enabled: session?.status === "unlocked",
 });
}
