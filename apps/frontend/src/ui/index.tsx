import { useId, type ComponentProps, type ReactNode } from "react";
import { Button as PrimitiveButton } from "@base-ui/react/button";
import { Dialog } from "@base-ui/react/dialog";
export function Button({
  className = "",
  ...props
}: ComponentProps<typeof PrimitiveButton>) {
  return <PrimitiveButton className={`button ${className}`} {...props} />;
}
export function Field({
  label,
  help,
  ...props
}: ComponentProps<"input"> & { label: string; help?: string }) {
  const id = useId();
  return (
    <div className="field">
      <label htmlFor={id}>{label}</label>
      <input
        id={id}
        aria-describedby={help ? `${id}-help` : undefined}
        {...props}
      />
      {help && <small id={`${id}-help`}>{help}</small>}
    </div>
  );
}
export function ErrorNotice({ children }: { children: ReactNode }) {
  return children ? (
    <div className="alert error" role="alert">
      {children}
    </div>
  ) : null;
}
export function Modal({
  title,
  children,
  open,
  onOpenChange,
}: {
  title: string;
  children: ReactNode;
  open: boolean;
  onOpenChange: (v: boolean) => void;
}) {
  return (
    <Dialog.Root open={open} onOpenChange={onOpenChange}>
      <Dialog.Portal>
        <Dialog.Backdrop className="backdrop" />
        <Dialog.Popup className="modal">
          <Dialog.Title>{title}</Dialog.Title>
          <Dialog.Description>
            Confira os detalhes antes de continuar.
          </Dialog.Description>
          {children}
        </Dialog.Popup>
      </Dialog.Portal>
    </Dialog.Root>
  );
}
