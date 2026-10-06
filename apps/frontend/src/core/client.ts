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
  removeWallet(pin: string): Promise<void>;
  diagnostics(): Promise<unknown>;
  exportDiagnostics(): Promise<boolean>;
  testNode(chain: Chain, endpoint: string): Promise<string>;
  saveNode(
    chain: Chain,
    endpoint: string | null,
    publicFallback: boolean,
  ): Promise<import("./desktop.generated").DesktopSettingsDto>;
  saveDisplay(
    locale: string,
    bitcoinUnit: string,
    privacy: boolean,
  ): Promise<import("./desktop.generated").DesktopSettingsDto>;
  parsePaymentRequest(
    input: string,
  ): Promise<import("./desktop.generated").ParsedPaymentDto>;
  receiveRequest(
    asset: import("../../../../crates/mooze-app/generated/types").AssetKeyDto,
    amountUnits: string | null,
    description: string | null,
  ): Promise<import("./desktop.generated").ReceiveRequestDto>;
  feeOptions(
    asset: import("../../../../crates/mooze-app/generated/types").AssetKeyDto,
  ): Promise<import("./desktop.generated").FeeOptionsDto>;
  beginSetup(
    extended: boolean,
  ): Promise<import("./desktop.generated").SetupDto>;
  cancelSetup(setupId: string): Promise<void>;
  completeSetup(
    setupId: string,
    answers: string[],
    pin: string,
  ): Promise<Session>;
  revealRecoveryPhrase(pin: string): Promise<string[]>;
  changePin(currentPin: string, newPin: string): Promise<void>;
  recordActivity(generation: number): Promise<void>;
  settings(): Promise<import("./desktop.generated").DesktopSettingsDto>;
  setLockMinutes(
    minutes: number,
  ): Promise<import("./desktop.generated").DesktopSettingsDto>;
  holdings(): Promise<import("./desktop.generated").HoldingsSnapshotDto>;
  approvedAssets(): Promise<
    import("../../../../crates/mooze-app/generated/types").AssetMetadataDto[]
  >;
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
