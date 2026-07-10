// Idle-game money formatting: $4.20, $69.4K, $1.23M …

const SUFFIXES = ["", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc"];

export function money(value: number): string {
  return `$${abbreviate(value)}`;
}

export function abbreviate(value: number): string {
  if (!isFinite(value)) return "∞";
  const neg = value < 0 ? "-" : "";
  let v = Math.abs(value);
  if (v < 1000) {
    return neg + (v < 100 && v % 1 !== 0 ? v.toFixed(2) : Math.floor(v).toLocaleString());
  }
  let idx = 0;
  while (v >= 1000 && idx < SUFFIXES.length - 1) {
    v /= 1000;
    idx++;
  }
  const digits = v >= 100 ? 0 : v >= 10 ? 1 : 2;
  return `${neg}${v.toFixed(digits)}${SUFFIXES[idx]}`;
}

export function duration(seconds: number): string {
  if (seconds < 10) return `${seconds.toFixed(1)}s`;
  if (seconds < 60) return `${Math.round(seconds)}s`;
  const m = Math.floor(seconds / 60);
  const s = Math.round(seconds % 60);
  return `${m}m ${s}s`;
}
