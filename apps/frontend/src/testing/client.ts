import { vi } from "vitest";
import type { DesktopClient } from "../core/client";
export function fakeClient(): DesktopClient {
  return {
    hostInfo: vi.fn(),
    sessionStatus: vi.fn(),
    importWallet: vi.fn(),
    unlock: vi.fn(),
    lock: vi.fn(),
    snapshot: vi.fn(),
    refresh: vi.fn(),
    receiveAddress: vi.fn(),
    reviewSend: vi.fn(),
    acknowledgeSubmission: vi.fn(),
    confirmSend: vi.fn(),
    subscribe: vi.fn(),
  };
}
