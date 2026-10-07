import { NativeAuthOffer } from "../features/setup/native-auth-offer";
import { useT } from "../i18n/messages";
import { activityEvents, isWalletActivity } from "./activity";
import {
  createContext,
  useContext,
  useCallback,
  useEffect,
  useRef,
  useState,
  type ReactNode,
  type MutableRefObject,
} from "react";
import { useQuery, useQueryClient } from "@tanstack/react-query";
import { errorText, type Session } from "../core/client";
import { useWalletClient } from "./client-context";
type SessionContext = {
  session: Session | null;
  current: MutableRefObject<Session | null>;
  startupError: string;
  update: (session: Session) => void;
  setStartupError: (error: string) => void;
};
const Context = createContext<SessionContext | null>(null);
export function SessionProvider({ children }: { children: ReactNode }) {
  const client = useWalletClient();
  const t = useT();
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
            if (e.type === "swap")
              qc.setQueryData(["wallet", e.generation, "swap"], e.data);
            else
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
  useEffect(() => {
    if (session?.status !== "unlocked") return;
    const record = (event: Event) => {
      if (isWalletActivity(event, document.hasFocus()))
        void client.recordActivity(session.generation).catch(() => {});
    };
    for (const type of activityEvents)
      window.addEventListener(type, record, { passive: true });
    return () => {
      for (const type of activityEvents)
        window.removeEventListener(type, record);
    };
  }, [client, session?.status, session?.generation]);
  const nativeKey = ["wallet", session?.generation, "native-auth"];
  const native = useQuery({
    queryKey: nativeKey,
    queryFn: () => client.nativeAuthStatus(),
    enabled: session?.status === "unlocked",
    retry: false,
    staleTime: Infinity,
  });
  useEffect(() => {
    if (
      session?.status !== "unlocked" ||
      !native.data?.setup_offer_pending ||
      native.data.availability === "available"
    )
      return;
    const generation = session.generation;
    void client
      .completeNativeAuthOffer(false)
      .then((status) => {
        if (
          current.current?.generation === generation &&
          current.current.status === "unlocked"
        )
          qc.setQueryData(["wallet", generation, "native-auth"], status);
      })
      .catch(() => {});
  }, [client, qc, session?.generation, session?.status, native.data]);
  const content =
    session?.status === "unlocked" && native.isPending ? (
      <main className="onboarding">
        <p role="status">{t("Verificando autenticação…")}</p>
      </main>
    ) : session?.status === "unlocked" &&
      native.data?.setup_offer_pending &&
      native.data.availability === "available" ? (
      <NativeAuthOffer
        key={session.generation}
        client={client}
        status={native.data}
        onDone={(status) => {
          if (
            current.current?.generation === session.generation &&
            current.current.status === "unlocked"
          )
            qc.setQueryData(nativeKey, status);
        }}
      />
    ) : (
      children
    );
  return (
    <Context.Provider
      value={{ session, current, startupError, update, setStartupError }}
    >
      {content}
    </Context.Provider>
  );
}
export function useWalletSession() {
  const value = useContext(Context);
  if (!value) throw new Error("SessionProvider is required");
  return value;
}
export function useWalletSnapshot() {
  const client = useWalletClient();
  const { session, current } = useWalletSession();
  return useQuery({
    queryKey: ["wallet", session?.generation, "snapshot"],
    queryFn: async () => {
      const generation = current.current?.generation;
      const data = await client.snapshot();
      if (
        current.current?.status !== "unlocked" ||
        current.current.generation !== generation ||
        data.generation !== generation
      )
        throw new Error("Sessão alterada.");
      return data;
    },
    enabled: session?.status === "unlocked",
  });
}

export function useWalletHoldings() {
  const client = useWalletClient();
  const { session, current } = useWalletSession();
  return useQuery({
    queryKey: ["wallet", session?.generation, "holdings"],
    enabled: session?.status === "unlocked",
    queryFn: async () => {
      const generation = current.current?.generation;
      const data = await client.holdings();
      if (
        current.current?.status !== "unlocked" ||
        current.current.generation !== generation ||
        data.generation !== generation
      )
        throw new Error("Sessão alterada.");
      return data;
    },
  });
}
