// Adapted from shadcn/ui (MIT); see SHADCN-LICENSE.md.
import { Checkbox as CheckboxPrimitive } from "@base-ui/react/checkbox";
import { Check } from "lucide-react";
import { cn } from "./utils";
export function Checkbox({
  className,
  ...props
}: CheckboxPrimitive.Root.Props) {
  return (
    <CheckboxPrimitive.Root
      data-slot="checkbox"
      className={cn("ui-checkbox", className)}
      {...props}
    >
      <CheckboxPrimitive.Indicator className="checkbox-indicator">
        <Check size={14} aria-hidden="true" />
      </CheckboxPrimitive.Indicator>
    </CheckboxPrimitive.Root>
  );
}
