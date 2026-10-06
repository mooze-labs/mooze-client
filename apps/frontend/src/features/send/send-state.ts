import type { Review } from "../../core/client";
export type SendState =
  | { phase: "editing" | "preparing" }
  | { phase: "reviewing" | "submitting"; review: Review }
  | { phase: "submitted"; txid: string }
  | { phase: "failed" | "uncertain"; message: string };
export type SendEvent =
  | { type: "edit" | "prepare" | "confirm" }
  | { type: "reviewed"; review: Review }
  | { type: "submitted"; txid: string }
  | { type: "failed" | "uncertain"; message: string };
export function reduceSend(state: SendState, event: SendEvent): SendState {
  switch (event.type) {
    case "edit":
      return state.phase === "submitting" || state.phase === "uncertain"
        ? state
        : { phase: "editing" };
    case "prepare":
      return { phase: "preparing" };
    case "reviewed":
      return { phase: "reviewing", review: event.review };
    case "confirm":
      return state.phase === "reviewing"
        ? { phase: "submitting", review: state.review }
        : state;
    case "submitted":
      return { phase: "submitted", txid: event.txid };
    case "failed":
    case "uncertain":
      return { phase: event.type, message: event.message };
  }
}
