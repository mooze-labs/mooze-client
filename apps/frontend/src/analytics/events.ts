/** Application-owned vocabulary. Never accept DTOs, URLs or free-form errors. */
export const screens = [
  "wallet",
  "assets",
  "asset",
  "activity",
  "send",
  "send_review",
  "receive",
  "swap",
  "pix",
  "settings",
  "account",
  "onboarding",
] as const;
export type Screen = (typeof screens)[number];
export type Chain = "bitcoin" | "liquid";
export type SwapType = "liquid" | "peg_in" | "peg_out";
export type PixStatus =
  "pending" | "processing" | "completed" | "failed" | "expired" | "refunded";
export type AnalyticsEvent =
  | {
      name:
        | "pix_request_started"
        | "pix_request_created"
        | "pix_request_failed"
        | "pix_code_copied";
      properties: Record<string, never>;
    }
  | { name: "pix_deposit_status_changed"; properties: { status: PixStatus } }
  | {
      name:
        | "swap_review_opened"
        | "swap_started"
        | "swap_submission_succeeded"
        | "swap_failed";
      properties: { swap_type: SwapType };
    }
  | { name: "screen_viewed"; properties: { screen_name: Screen } }
  | {
      name: "onboarding_completed";
      properties: { method: "create" | "import" };
    }
  | {
      name: "send_started" | "send_submission_succeeded";
      properties: { chain: Chain };
    }
  | {
      name: "send_failed";
      properties: { chain: Chain; error_code: "rejected" | "unknown" };
    };

export function sanitizeEvent(
  name: string,
  properties: Record<string, unknown>,
): AnalyticsEvent | null {
  if (
    name === "pix_request_started" ||
    name === "pix_request_created" ||
    name === "pix_request_failed" ||
    name === "pix_code_copied"
  )
    return { name, properties: {} };
  if (name === "pix_deposit_status_changed") {
    const status = properties.status;
    if (
      status === "pending" ||
      status === "processing" ||
      status === "completed" ||
      status === "failed" ||
      status === "expired" ||
      status === "refunded"
    )
      return { name, properties: { status } };
    return null;
  }
  if (
    name === "swap_review_opened" ||
    name === "swap_started" ||
    name === "swap_submission_succeeded" ||
    name === "swap_failed"
  ) {
    const type = properties.swap_type;
    return type === "liquid" || type === "peg_in" || type === "peg_out"
      ? { name, properties: { swap_type: type } }
      : null;
  }
  if (
    name === "screen_viewed" &&
    screens.includes(properties.screen_name as Screen)
  )
    return {
      name,
      properties: { screen_name: properties.screen_name as Screen },
    };
  if (
    name === "onboarding_completed" &&
    (properties.method === "create" || properties.method === "import")
  )
    return {
      name,
      properties: { method: properties.method as "create" | "import" },
    };
  const chain = properties.chain;
  if (chain !== "bitcoin" && chain !== "liquid") return null;
  if (name === "send_started" || name === "send_submission_succeeded")
    return { name, properties: { chain } };
  if (
    name === "send_failed" &&
    (properties.error_code === "rejected" ||
      properties.error_code === "unknown")
  )
    return { name, properties: { chain, error_code: properties.error_code } };
  return null;
}

export function screenForPath(location: string): Screen | null {
  const path = location.split(/[?#]/, 1)[0];
  const routes: Record<string, Screen> = {
    "/": "wallet",
    "/assets": "assets",
    "/history": "activity",
    "/send": "send",
    "/receive": "receive",
    "/swap": "swap",
    "/pix": "pix",
    "/settings": "settings",
    "/account": "account",
  };
  if (/^\/assets\/(Bitcoin|Liquid)\/[^/]+$/.test(path)) return "asset";
  return routes[path] ?? null;
}
