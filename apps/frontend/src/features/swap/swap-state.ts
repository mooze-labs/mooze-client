import type { SwapStateDto } from "../../core/desktop.generated";
export function canConfirm(
  state: SwapStateDto | undefined,
  now: number,
  busy: boolean,
): boolean {
  return (
    !busy &&
    state?.phase === "Review" &&
    !!state.review &&
    now < state.review.expires_at_ms
  );
}
