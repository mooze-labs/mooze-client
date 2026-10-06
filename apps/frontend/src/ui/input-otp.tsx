// Adapted from shadcn/ui (MIT); see SHADCN-LICENSE.md.
import { useContext, type ComponentProps } from "react";
import { OTPInput, OTPInputContext } from "input-otp";
import { cn } from "./utils";
export function InputOTP({
  containerClassName,
  ...props
}: ComponentProps<typeof OTPInput>) {
  return (
    <OTPInput
      data-slot="input-otp"
      containerClassName={cn("pin-input", containerClassName)}
      spellCheck={false}
      {...props}
    />
  );
}
export function InputOTPGroup({ className, ...props }: ComponentProps<"div">) {
  return (
    <div
      data-slot="input-otp-group"
      className={cn("pin-slots", className)}
      {...props}
    />
  );
}
// Never render the PIN character into a visual slot, even briefly.
export function InputOTPSlot({
  index,
  ...props
}: ComponentProps<"div"> & { index: number }) {
  const { char, isActive, hasFakeCaret } =
    useContext(OTPInputContext)?.slots[index] ?? {};
  return (
    <div
      data-slot="input-otp-slot"
      data-active={!!isActive}
      data-filled={!!char}
      {...props}
    >
      {char ? "•" : hasFakeCaret ? <span className="pin-caret" /> : null}
    </div>
  );
}
