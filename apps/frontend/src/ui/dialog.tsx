import { useLayoutEffect, useRef, type ReactNode } from "react";
import { useAnimate } from "motion/react-mini";
import { useReducedMotion } from "motion/react";
import { Dialog } from "@base-ui/react/dialog";

// Mount inside the portal so animation starts only once both surfaces exist.
// The unanimated DOM remains visible if an animation is interrupted.
function DrawerContent({
  children,
  className,
  backdropClassName,
}: {
  children: ReactNode;
  className: string;
  backdropClassName: string;
}) {
  const [scope, animate] = useAnimate<HTMLDivElement>();
  const backdrop = useRef<HTMLDivElement>(null);
  const reducedMotion = useReducedMotion();
  useLayoutEffect(() => {
    if (
      reducedMotion ||
      document.hidden ||
      !scope.current?.animate ||
      !backdrop.current
    )
      return;
    const panelAnimation = animate(
      scope.current,
      {
        transform: ["translateX(100%)", "translateX(0%)"],
        opacity: [0.6, 1],
      },
      { duration: 0.28, ease: [0.22, 1, 0.36, 1] },
    );
    const backdropAnimation = animate(
      backdrop.current,
      { opacity: [0, 1] },
      { duration: 0.2 },
    );
    const cancel = () => {
      panelAnimation.cancel();
      backdropAnimation.cancel();
    };
    const handleVisibility = () => {
      if (document.hidden) cancel();
    };
    document.addEventListener("visibilitychange", handleVisibility);
    return () => {
      document.removeEventListener("visibilitychange", handleVisibility);
      cancel();
    };
  }, [animate, reducedMotion, scope]);
  return (
    <>
      <Dialog.Backdrop
        ref={backdrop}
        className={`backdrop ${backdropClassName}`}
      />
      <Dialog.Popup ref={scope} className={className}>
        {children}
      </Dialog.Popup>
    </>
  );
}

export function Modal({
  title,
  description,
  children,
  className = "modal",
  open,
  onOpenChange,
  headerActions,
  backdropClassName = "",
  presentation = "modal",
}: {
  title: string;
  description?: string;
  className?: string;
  children: ReactNode;
  open: boolean;
  onOpenChange: (v: boolean) => void;
  headerActions?: ReactNode;
  backdropClassName?: string;
  presentation?: "modal" | "drawer";
}) {
  const content = (
    <>
      {headerActions ? (
        <div className="dialog-heading">
          <Dialog.Title>{title}</Dialog.Title>
          {headerActions}
        </div>
      ) : (
        <Dialog.Title>{title}</Dialog.Title>
      )}
      {description && <Dialog.Description>{description}</Dialog.Description>}
      {children}
    </>
  );
  return (
    <Dialog.Root open={open} onOpenChange={onOpenChange}>
      <Dialog.Portal>
        {presentation === "drawer" ? (
          <DrawerContent
            className={className}
            backdropClassName={backdropClassName}
          >
            {content}
          </DrawerContent>
        ) : (
          <>
            <Dialog.Backdrop className={`backdrop ${backdropClassName}`} />
            <Dialog.Popup className={className}>{content}</Dialog.Popup>
          </>
        )}
      </Dialog.Portal>
    </Dialog.Root>
  );
}
