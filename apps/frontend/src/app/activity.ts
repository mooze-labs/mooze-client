export const activityEvents = [
  "keydown",
  "pointerdown",
  "pointermove",
  "wheel",
] as const;
export function isWalletActivity(
  event: Pick<Event, "type" | "isTrusted">,
  focused: boolean,
) {
  return (
    focused &&
    event.isTrusted &&
    activityEvents.some((type) => type === event.type)
  );
}
