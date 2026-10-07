import { expect, it, vi } from "vitest";
import { fakeClient } from "../../testing/client";
import { NativeAuthController } from "./native-auth-controller";
const available = {
  kind: "touch_id",
  availability: "available",
  enabled: true,
  setup_offer_pending: false,
} as const;
it("automatically prompts only once per locked generation, including remount/focus churn", async () => {
  const client = fakeClient();
  vi.mocked(client.nativeAuthStatus).mockResolvedValue(available);
  vi.mocked(client.unlockNative).mockRejectedValue({
    code: "native_cancelled",
  });
  const controller = new NativeAuthController(client);
  await controller.enter(7, false);
  expect(client.unlockNative).not.toHaveBeenCalled();
  await controller.enter(7, true);
  await controller.enter(7, true);
  expect(client.unlockNative).toHaveBeenCalledTimes(1);
  expect(controller.getSnapshot().mode).toBe("native");
  expect(controller.getSnapshot().error).toBe("");
  await controller.retry(7);
  expect(client.unlockNative).toHaveBeenCalledTimes(2);
});
it("PIN selection invalidates late success and waits for backend acknowledgement", async () => {
  const client = fakeClient();
  vi.mocked(client.nativeAuthStatus).mockResolvedValue(available);
  let resolve!: (s: any) => void;
  let acknowledge!: () => void;
  vi.mocked(client.unlockNative).mockImplementation(
    () =>
      new Promise((r) => {
        resolve = r;
      }),
  );
  vi.mocked(client.cancelNativeAuth).mockImplementation(
    () =>
      new Promise((r) => {
        acknowledge = r;
      }),
  );
  const controller = new NativeAuthController(client);
  const opening = controller.enter(2, true);
  await vi.waitFor(() => expect(client.unlockNative).toHaveBeenCalledOnce());
  const pin = controller.usePin(2);
  expect(controller.getSnapshot().mode).toBe("switching");
  resolve({ status: "unlocked", generation: 3, retry_after_ms: 0 });
  await opening;
  expect(controller.getSnapshot().session).toBeNull();
  acknowledge();
  await pin;
  expect(controller.getSnapshot().mode).toBe("pin");
});
it("unsupported devices and capability failures retain PIN", async () => {
  const client = fakeClient();
  const controller = new NativeAuthController(client);
  await controller.enter(1, true);
  expect(controller.getSnapshot().mode).toBe("pin");
  expect(client.unlockNative).not.toHaveBeenCalled();
  vi.mocked(client.nativeAuthStatus).mockRejectedValue(
    new Error("storage unavailable"),
  );
  await controller.enter(2, true);
  expect(controller.getSnapshot().mode).toBe("pin");
});
it("capability loss during native verification falls back without another automatic prompt", async () => {
  const client = fakeClient();
  vi.mocked(client.nativeAuthStatus).mockResolvedValue(available);
  vi.mocked(client.unlockNative).mockRejectedValue({
    code: "native_unavailable",
  });
  const controller = new NativeAuthController(client);
  await controller.enter(1, true);
  expect(controller.getSnapshot().mode).toBe("pin");
  await controller.enter(1, true);
  expect(client.unlockNative).toHaveBeenCalledOnce();
});
it("does not automatically prompt if focus is lost during the capability probe", async () => {
  const client = fakeClient();
  let resolve!: (s: typeof available) => void;
  vi.mocked(client.nativeAuthStatus).mockImplementation(
    () =>
      new Promise((r) => {
        resolve = r;
      }),
  );
  const controller = new NativeAuthController(client);
  const entering = controller.enter(4, true);
  const background = controller.enter(4, false);
  resolve(available);
  await Promise.all([entering, background]);
  expect(client.unlockNative).not.toHaveBeenCalled();
});
