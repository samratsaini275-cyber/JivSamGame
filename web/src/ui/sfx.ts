// Tiny WebAudio synth — no assets, everything generated. Fails silently.

let ctx: AudioContext | null = null;
let muted = localStorage.getItem("ce-muted") === "1";

export function isMuted(): boolean {
  return muted;
}

export function setMuted(m: boolean): void {
  muted = m;
  localStorage.setItem("ce-muted", m ? "1" : "0");
}

function ac(): AudioContext | null {
  if (muted) return null;
  try {
    if (!ctx) ctx = new AudioContext();
    if (ctx.state === "suspended") void ctx.resume();
    return ctx;
  } catch {
    return null;
  }
}

function tone(freq: number, start: number, dur: number, type: OscillatorType = "sine", peak = 0.08) {
  const c = ac();
  if (!c) return;
  const t = c.currentTime + start;
  const osc = c.createOscillator();
  const gain = c.createGain();
  osc.type = type;
  osc.frequency.value = freq;
  gain.gain.setValueAtTime(0.0001, t);
  gain.gain.exponentialRampToValueAtTime(peak, t + 0.012);
  gain.gain.exponentialRampToValueAtTime(0.0001, t + dur);
  osc.connect(gain).connect(c.destination);
  osc.start(t);
  osc.stop(t + dur + 0.05);
}

export const sfx = {
  /** Cha-ching: unit purchased. */
  buy() { tone(523, 0, 0.09, "triangle", 0.09); tone(784, 0.055, 0.13, "triangle", 0.09); },
  /** Soft tick: manual post started. */
  post() { tone(340, 0, 0.06, "triangle", 0.06); },
  /** Staff hired / big commit. */
  hire() { tone(392, 0, 0.1, "triangle", 0.08); tone(523, 0.07, 0.1, "triangle", 0.08); tone(659, 0.14, 0.16, "triangle", 0.09); },
  /** Milestone crossed: rising arp. */
  milestone() { [523, 659, 784].forEach((f, i) => tone(f, i * 0.09, 0.2, "sine", 0.1)); },
  /** Viral Moment: bigger arp. */
  viral() { [523, 659, 784, 1046].forEach((f, i) => tone(f, i * 0.08, 0.24, "sine", 0.11)); },
  /** Rebrand fanfare. */
  rebrand() { [392, 494, 587, 784].forEach((f, i) => tone(f, i * 0.12, 0.32, "sine", 0.11)); },
  /** Chat reply sent. */
  message() { tone(880, 0, 0.05, "sine", 0.06); tone(660, 0.045, 0.07, "sine", 0.05); },
  /** Raid: two-tone siren sweep. */
  siren() {
    for (let i = 0; i < 3; i++) {
      tone(690, i * 0.42, 0.24, "square", 0.05);
      tone(520, i * 0.42 + 0.21, 0.24, "square", 0.05);
    }
  },
  /** Investigation opened: low warning. */
  warning() { tone(220, 0, 0.25, "square", 0.05); tone(196, 0.22, 0.3, "square", 0.05); },
  // --- Casino ---
  /** A card dealt onto the felt: soft flick. */
  card() { tone(660, 0, 0.04, "triangle", 0.05); tone(440, 0.02, 0.05, "sine", 0.03); },
  /** Dealer hole card flipped. */
  flip() { tone(520, 0, 0.05, "triangle", 0.06); tone(720, 0.04, 0.06, "triangle", 0.05); },
  /** Chips pushed in on a bet. */
  chip() { tone(900, 0, 0.03, "sine", 0.05); tone(760, 0.03, 0.04, "sine", 0.04); tone(640, 0.06, 0.05, "sine", 0.03); },
  /** Blackjack — a bright fanfare. */
  blackjack() { [659, 831, 988, 1319].forEach((f, i) => tone(f, i * 0.09, 0.26, "sine", 0.11)); },
  /** Won a hand. */
  win() { [659, 988].forEach((f, i) => tone(f, i * 0.1, 0.22, "sine", 0.1)); },
  /** Lost a hand: soft descending. */
  lose() { tone(392, 0, 0.18, "sine", 0.07); tone(311, 0.16, 0.24, "sine", 0.07); },
  /** Push — a neutral tick. */
  push() { tone(523, 0, 0.12, "sine", 0.06); },
};
