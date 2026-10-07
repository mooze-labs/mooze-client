import type { DesktopClient, Session } from "../../core/client";
import type { NativeAuthStatusDto } from "../../core/desktop.generated";
export type NativeAuthView = {
  generation: number;
  mode: "checking" | "native" | "prompting" | "switching" | "pin" | "opening";
  status: NativeAuthStatusDto | null;
  error: string;
  session: Session | null;
};
export function nativeAuthLabel(status: NativeAuthStatusDto | null) {
  return status?.kind === "touch_id" ? "Touch ID" : "Windows Hello";
}
export function nativeAuthError(error: unknown): string {
  const code = (error as { code?: string } | null)?.code;
  if (code === "native_cancelled") return "";
  if (code === "native_busy")
    return "Conclua a autenticação em andamento ou use o PIN da carteira.";
  if (code === "native_locked_out")
    return "Autenticação do dispositivo bloqueada. Use o PIN da carteira.";
  if (code === "native_unavailable" || code === "native_disabled")
    return "Autenticação do dispositivo indisponível. Use o PIN da carteira.";
  return "Não foi possível autenticar. Tente novamente ou use o PIN da carteira.";
}
/** Session-lifetime store: React remounts cannot reset automatic-prompt ownership. */
export class NativeAuthController {
  private value: NativeAuthView = {
    generation: -1,
    mode: "checking",
    status: null,
    error: "",
    session: null,
  };
  private listeners = new Set<() => void>();
  private automatic = false;
  private probing: Promise<void> | null = null;
  private epoch = 0;
  private foreground = false;
  constructor(
    private client: DesktopClient,
    private currentForeground?: () => boolean,
  ) {}
  getSnapshot = () => this.value;
  subscribe = (listener: () => void) => {
    this.listeners.add(listener);
    return () => {
      this.listeners.delete(listener);
    };
  };
  private publish(patch: Partial<NativeAuthView>) {
    this.value = { ...this.value, ...patch };
    this.listeners.forEach((l) => l());
  }
  async enter(generation: number, foreground: boolean): Promise<void> {
    this.foreground = foreground;
    if (this.value.generation !== generation) {
      this.epoch++;
      this.automatic = false;
      this.publish({
        generation,
        mode: "checking",
        status: null,
        error: "",
        session: null,
      });
      const epoch = this.epoch;
      this.probing = this.client
        .nativeAuthStatus()
        .then((status) => {
          if (epoch !== this.epoch) return;
          this.publish({
            status,
            mode:
              status.enabled && status.availability === "available"
                ? "native"
                : "pin",
          });
        })
        .catch(() => {
          if (epoch === this.epoch) this.publish({ mode: "pin" });
        });
    }
    await this.probing;
    if (
      this.value.generation !== generation ||
      !(this.currentForeground?.() ?? this.foreground) ||
      this.automatic ||
      this.value.mode !== "native"
    )
      return;
    this.automatic = true;
    await this.retry(generation);
  }
  async retry(generation: number): Promise<void> {
    if (
      this.value.generation !== generation ||
      !["native", "pin"].includes(this.value.mode)
    )
      return;
    const status = this.value.status;
    if (!status?.enabled || status.availability !== "available") return;
    this.automatic = true;
    const epoch = ++this.epoch;
    this.publish({ mode: "prompting", error: "", session: null });
    try {
      const session = await this.client.unlockNative();
      if (epoch === this.epoch) this.publish({ mode: "opening", session });
    } catch (error) {
      if (epoch !== this.epoch) return;
      const code = (error as { code?: string })?.code;
      this.publish({
        mode: [
          "native_unavailable",
          "native_locked_out",
          "native_disabled",
        ].includes(code ?? "")
          ? "pin"
          : "native",
        error: nativeAuthError(error),
      });
    }
  }
  async usePin(generation: number): Promise<void> {
    if (this.value.generation !== generation || this.value.mode === "switching")
      return;
    const epoch = ++this.epoch;
    this.automatic = true;
    this.publish({ mode: "switching", session: null, error: "" });
    try {
      await this.client.cancelNativeAuth();
      if (epoch === this.epoch) this.publish({ mode: "pin" });
    } catch (error) {
      if (epoch === this.epoch)
        this.publish({ mode: "native", error: nativeAuthError(error) });
    }
  }
}
// One controller per client connection, surviving lock-screen remounts without
// retaining abandoned clients. Backend generations remain authoritative.
const controllers = new WeakMap<DesktopClient, NativeAuthController>();
export function nativeAuthController(
  client: DesktopClient,
): NativeAuthController {
  let controller = controllers.get(client);
  if (!controller) {
    controller = new NativeAuthController(
      client,
      () => document.hasFocus() && document.visibilityState !== "hidden",
    );
    controllers.set(client, controller);
  }
  return controller;
}
