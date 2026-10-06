import { useId, type ReactNode } from "react";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "./select";
import { cn } from "./utils";
type SelectOption = { value: string; label: ReactNode; disabled?: boolean };
export function SelectField({
  label,
  value,
  items,
  onValueChange,
  disabled,
  className,
}: {
  label: string;
  value: string | number;
  items: SelectOption[];
  onValueChange: (value: string) => void;
  disabled?: boolean;
  className?: string;
}) {
  const id = useId();
  return (
    <div className={cn("field", className)}>
      <label id={`${id}-label`} htmlFor={id}>
        {label}
      </label>
      <Select
        items={items}
        value={String(value)}
        disabled={disabled}
        onValueChange={(next) => {
          if (next !== null) onValueChange(next);
        }}
      >
        <SelectTrigger id={id} aria-labelledby={`${id}-label`}>
          <SelectValue />
        </SelectTrigger>
        <SelectContent>
          {items.map((item) => (
            <SelectItem
              key={item.value}
              value={item.value}
              disabled={item.disabled}
            >
              {item.label}
            </SelectItem>
          ))}
        </SelectContent>
      </Select>
    </div>
  );
}
