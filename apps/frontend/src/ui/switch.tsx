// Adapted from shadcn/ui (MIT); see SHADCN-LICENSE.md.
import { Switch as SwitchPrimitive } from "@base-ui/react/switch";
import { cn } from "./utils";
export function Switch({ className, ...props }: SwitchPrimitive.Root.Props) {
  return (
    <SwitchPrimitive.Root
      data-slot="switch"
      className={cn("ui-switch", className)}
      {...props}
    >
      <SwitchPrimitive.Thumb
        data-slot="switch-thumb"
        className="switch-thumb"
      />
    </SwitchPrimitive.Root>
  );
}
