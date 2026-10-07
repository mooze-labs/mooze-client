import { useEffect, useRef, type ReactNode } from "react";

/** Keep this boundary mounted while replacing steps so keyboard users keep their place. */
export function FlowStep({
  step,
  className,
  children,
}: {
  step: string;
  className?: string;
  children: ReactNode;
}) {
  const element = useRef<HTMLDivElement>(null);
  const previous = useRef(step);
  useEffect(() => {
    if (previous.current === step) return;
    previous.current = step;
    const heading = element.current?.querySelector<HTMLElement>("h1, h2");
    if (heading) {
      heading.tabIndex = -1;
      heading.focus();
    }
  }, [step]);
  return (
    <div ref={element} className={className}>
      {children}
    </div>
  );
}
