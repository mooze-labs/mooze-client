import { useId } from "react";
import { REGEXP_ONLY_DIGITS } from "input-otp";
import { InputOTP, InputOTPGroup, InputOTPSlot } from "./input-otp";
type PinFieldProps = {
  label: string;
  value: string;
  onValueChange: (value: string) => void;
  disabled?: boolean;
  required?: boolean;
  invalid?: boolean;
  help?: string;
  autoFocus?: boolean;
};
export function PinField({
  label,
  value,
  onValueChange,
  disabled,
  required,
  invalid,
  help,
  autoFocus,
}: PinFieldProps) {
  const id = useId();
  return (
    <div className="field pin-field">
      <label htmlFor={id}>{label}</label>
      <InputOTP
        id={id}
        type="password"
        inputMode="numeric"
        autoComplete="off"
        maxLength={6}
        minLength={6}
        pattern={REGEXP_ONLY_DIGITS}
        value={value}
        onChange={onValueChange}
        disabled={disabled}
        required={required}
        autoFocus={autoFocus}
        aria-invalid={invalid || undefined}
        aria-describedby={help ? `${id}-help` : undefined}
        pushPasswordManagerStrategy="none"
        pasteTransformer={(text) => text}
      >
        <InputOTPGroup aria-hidden="true">
          {Array.from({ length: 6 }, (_, index) => (
            <InputOTPSlot
              key={index}
              index={index}
              aria-invalid={invalid || undefined}
            />
          ))}
        </InputOTPGroup>
      </InputOTP>
      {help && <small id={`${id}-help`}>{help}</small>}
    </div>
  );
}
