// Floating cash pops, confetti bursts, and event toasts.
import { useEffect, useRef, useState } from "react";
import { GameEvent, game } from "../engine/game";
import { HUSTLES, tierName } from "../engine/data";
import { money } from "./format";
import { sfx } from "./sfx";
import { PRESS, FAMILY } from "../theme/content";

interface Pop { id: number; x: number; y: number; text: string }
interface Confetto { id: number; x: number; y: number; dx: number; dy: number; color: string; spin: number }

let nextID = 1;

/// Position of a hustle card relative to the phone shell, for anchoring particles.
function cardPoint(index: number): { x: number; y: number } | null {
  const card = document.querySelector(`[data-hustle-card="${index}"]`);
  const shell = document.querySelector(".phone");
  if (!card || !shell) return null;
  const c = card.getBoundingClientRect();
  const s = shell.getBoundingClientRect();
  return {
    x: c.left - s.left + c.width * (0.35 + Math.random() * 0.3),
    y: c.top - s.top + 24,
  };
}

const CONFETTI_COLORS = ["#e0b64f", "#e8dcc3", "#3d7a74", "#7ca163", "#c9a02c", "#b58ed0"];

export function EffectsLayer() {
  const [pops, setPops] = useState<Pop[]>([]);
  const [confetti, setConfetti] = useState<Confetto[]>([]);
  const [toast, setToast] = useState<{ id: number; title: string; sub: string } | null>(null);
  const toastTimer = useRef<number | undefined>(undefined);
  const lastPopAt = useRef<Record<number, number>>({});

  useEffect(() => {
    return game.onEvent((e: GameEvent) => {
      if (e.kind === "payout") {
        // Rate-limit per hustle so fast cycles don't flood the screen.
        const now = performance.now();
        if (now - (lastPopAt.current[e.hustleIndex] ?? 0) < 600) return;
        lastPopAt.current[e.hustleIndex] = now;
        const pt = cardPoint(e.hustleIndex);
        if (!pt) return;
        const pop = { id: nextID++, ...pt, text: `+${money(e.amount)}` };
        setPops((p) => [...p.slice(-14), pop]);
        window.setTimeout(() => setPops((p) => p.filter((x) => x.id !== pop.id)), 1100);
        return;
      }

      let origin = { x: 215, y: 180 };
      let title = "";
      let sub = "";
      if (e.kind === "milestone") {
        origin = cardPoint(e.hustleIndex) ?? origin;
        title = PRESS.milestoneToast(HUSTLES[e.hustleIndex].name, tierName(e.tier));
        sub = PRESS.milestoneSub;
        sfx.milestone();
      } else if (e.kind === "hypeWave") {
        title = PRESS.toastTitle;
        sub = PRESS.toastSub(Math.pow(2, e.tier));
        sfx.viral();
      } else if (e.kind === "rebranded") {
        title = FAMILY.toastTitle;
        sub = FAMILY.toastSub(e.clout.toLocaleString());
        sfx.rebrand();
      }

      const burst: Confetto[] = Array.from({ length: e.kind === "milestone" ? 26 : 44 }, () => ({
        id: nextID++,
        x: origin.x, y: origin.y,
        dx: (Math.random() - 0.5) * 260,
        dy: -40 - Math.random() * 220,
        color: CONFETTI_COLORS[Math.floor(Math.random() * CONFETTI_COLORS.length)],
        spin: (Math.random() - 0.5) * 720,
      }));
      setConfetti((c) => [...c.slice(-60), ...burst]);
      window.setTimeout(
        () => setConfetti((c) => c.filter((x) => !burst.some((b) => b.id === x.id))),
        1300,
      );

      const t = { id: nextID++, title, sub };
      setToast(t);
      window.clearTimeout(toastTimer.current);
      toastTimer.current = window.setTimeout(() => {
        setToast((cur) => (cur?.id === t.id ? null : cur));
      }, 2400);
    });
  }, []);

  return (
    <div className="fx-layer" aria-hidden>
      {pops.map((p) => (
        <div key={p.id} className="cash-pop" style={{ left: p.x, top: p.y }}>{p.text}</div>
      ))}
      {confetti.map((c) => (
        <div
          key={c.id}
          className="confetto"
          style={{
            left: c.x, top: c.y, background: c.color,
            ["--dx" as string]: `${c.dx}px`,
            ["--dy" as string]: `${c.dy}px`,
            ["--spin" as string]: `${c.spin}deg`,
          }}
        />
      ))}
      {toast && (
        <div className="toast" key={toast.id}>
          <div className="toast-title">{toast.title}</div>
          <div className="toast-sub">{toast.sub}</div>
        </div>
      )}
    </div>
  );
}
