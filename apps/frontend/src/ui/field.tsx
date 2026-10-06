import { Input } from "./input";
import { useId, type ComponentProps } from "react";
export function Field({
  label,
  help,
  ...props
}: ComponentProps<"input"> & { label: string; help?: string }) {
  const id = useId();
  return (
    <div className="field">
      <label htmlFor={id}>{label}</label>
      <Input
        id={id}
        aria-describedby={help ? `${id}-help` : undefined}
        {...props}
      />
      {help && <small id={`${id}-help`}>{help}</small>}
    </div>
  );
}
