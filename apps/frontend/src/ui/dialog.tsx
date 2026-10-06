import type { ReactNode } from "react";
import { Dialog } from "@base-ui/react/dialog";
export function Modal({
  title,
  description,
  children,
  className = "modal",
  open,
  onOpenChange,
}: {
  title: string;
  description?: string;
  className?: string;
  children: ReactNode;
  open: boolean;
  onOpenChange: (v: boolean) => void;
}) {
  return (
    <Dialog.Root open={open} onOpenChange={onOpenChange}>
      <Dialog.Portal>
        <Dialog.Backdrop className="backdrop" />
        <Dialog.Popup className={className}>
          <Dialog.Title>{title}</Dialog.Title>
          {description && (
            <Dialog.Description>{description}</Dialog.Description>
          )}
          {children}
        </Dialog.Popup>
      </Dialog.Portal>
    </Dialog.Root>
  );
}
