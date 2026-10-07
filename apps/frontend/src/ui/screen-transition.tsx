import { useLayoutEffect, type ReactNode } from "react";
import { useLocation } from "react-router-dom";
import { useAnimate } from "motion/react-mini";
import { useReducedMotion } from "motion/react";

/** Animate navigation without remounting pages or delaying the next screen. */
export function ScreenTransition({ children }: { children: ReactNode }) {
  const { pathname } = useLocation();
  const [scope, animate] = useAnimate<HTMLDivElement>();
  const reducedMotion = useReducedMotion();

  useLayoutEffect(() => {
    if (reducedMotion || document.hidden || !scope.current?.animate) return;
    const animation = animate(
      scope.current,
      { opacity: [0, 1], transform: ["translateY(6px)", "translateY(0px)"] },
      { duration: 0.18, ease: [0.22, 1, 0.36, 1] },
    );
    const handleVisibility = () => {
      if (document.hidden) animation.cancel();
    };
    document.addEventListener("visibilitychange", handleVisibility);
    return () => {
      document.removeEventListener("visibilitychange", handleVisibility);
      animation.cancel();
    };
  }, [pathname, reducedMotion, animate, scope]);

  return <div ref={scope}>{children}</div>;
}
