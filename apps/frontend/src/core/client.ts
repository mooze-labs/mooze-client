import type {
  ReceiveAddressDto,
  BroadcastResultDto,
  AppEvent,
} from "../../../../crates/mooze-app/generated/types";
export type {
  WalletChain as Chain,
  SessionDto as Session,
  HostInfoDto as HostInfo,
  ReviewRequestDto as ReviewRequest,
  SendReviewDto as Review,
  DesktopSnapshotDto as Snapshot,
} from "./desktop.generated";
import type {
  WalletChain as Chain,
  SessionDto as Session,
  HostInfoDto as HostInfo,
  ReviewRequestDto as ReviewRequest,
  SendReviewDto as Review,
  DesktopSnapshotDto as Snapshot,
} from "./desktop.generated";
export type DesktopEvent =
  | { type: "session"; data: Session }
  | { type: "core"; generation: number; data: AppEvent }
  | { type: "submission"; generation: number };
export interface DesktopClient {
  hostInfo(): Promise<HostInfo>;
  sessionStatus(): Promise<Session>;
  importWallet(mnemonic: string, pin: string): Promise<Session>;
  unlock(pin: string): Promise<Session>;
  lock(): Promise<Session>;
  snapshot(): Promise<Snapshot>;
  refresh(): Promise<void>;
  receiveAddress(chain: Chain): Promise<ReceiveAddressDto>;
  reviewSend(request: ReviewRequest): Promise<Review>;
  acknowledgeSubmission(): Promise<void>;
  confirmSend(reviewId: string): Promise<BroadcastResultDto>;
  subscribe(handler: (event: DesktopEvent) => void): Promise<() => void>;
}
export function errorText(e: unknown): string {
  if (e && typeof e === "object" && "message" in e) return String(e.message);
  return "Não foi possível concluir a operação. Verifique a conexão.";
}
