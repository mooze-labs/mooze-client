/** Indicative ratio for the core's eight-decimal Liquid quote amounts. */
export function quoteRate(send: string, receive: string): string | null {
  const source = BigInt(send);
  const destination = BigInt(receive);
  if (source <= 0n || destination <= 0n) return null;
  const scaled = (destination * 100000000n) / source;
  if (scaled === 0n) return "<0.00000001";
  const fraction = (scaled % 100000000n)
    .toString()
    .padStart(8, "0")
    .replace(/0+$/, "");
  return `${scaled / 100000000n}${fraction ? `.${fraction}` : ""}`;
}
