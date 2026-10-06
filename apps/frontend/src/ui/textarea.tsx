// Adapted from shadcn/ui (MIT); see SHADCN-LICENSE.md.
import type { ComponentProps } from "react";
import { cn } from "./utils";
export function Textarea({ className, ...props }: ComponentProps<"textarea">) {
  return (
    <textarea
      data-slot="textarea"
      className={cn("ui-textarea", className)}
      {...props}
    />
  );
}
