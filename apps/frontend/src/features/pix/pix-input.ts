/** Presentation only; document validity remains enforced by the Rust core. */
export const taxIdDigits = (value: string) => value.replace(/[.\s/-]/g, "");
export function formatTaxId(value: string): string {
  const digits = taxIdDigits(value);
  if (!/^\d*$/.test(digits) || digits.length > 14) return value;
  return digits.length <= 11
    ? digits
        .replace(/^(\d{3})(\d)/, "$1.$2")
        .replace(/^(\d{3}\.\d{3})(\d)/, "$1.$2")
        .replace(/(\.\d{3})(\d{1,2})$/, "$1-$2")
    : digits.replace(
        /^(\d{2})(\d{3})(\d{3})(\d{4})(\d{0,2})$/,
        (_, a, b, c, d, e) => `${a}.${b}.${c}/${d}${e ? `-${e}` : ""}`,
      );
}
export function formatBrlInput(value: string): string {
  // Keep invalid and incomplete input editable; never round money as it is typed.
  if (!/^(?:\d+|\d{1,3}(?:\.\d{3})+),\d{0,2}$/.test(value)) return value;
  const [whole, fraction] = value.split(",");
  return `${whole.replaceAll(".", "").replace(/\B(?=(\d{3})+(?!\d))/g, ".")},${fraction}`;
}
