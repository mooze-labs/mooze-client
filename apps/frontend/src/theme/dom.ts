import type {ResolvedTheme} from './model';
export const SYSTEM_THEME_QUERY = '(prefers-color-scheme: dark)';
export function systemTheme(): ResolvedTheme {
  return window.matchMedia?.(SYSTEM_THEME_QUERY).matches ? 'dark' : 'light';
}
export function applyTheme(root: HTMLElement, theme: ResolvedTheme): void {
  root.dataset.theme = theme;
  root.style.colorScheme = theme;
}
