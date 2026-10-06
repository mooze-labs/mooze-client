// Adapted from shadcn/ui (MIT); see SHADCN-LICENSE.md.
import type { ComponentProps } from "react";
import { Input as InputPrimitive } from "@base-ui/react/input";
import { cn } from "./utils";
export function Input({ className, type, ...props }: ComponentProps<"input">) {
  return (
    <InputPrimitive
      type={type}
      data-slot="input"
      className={cn("ui-input", className)}
      {...props}
    />
  );
}
