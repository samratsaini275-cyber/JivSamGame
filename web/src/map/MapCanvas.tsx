// The pannable/zoomable city map. Canvas for the scene; DOM handles panels.
import { useEffect, useRef } from "react";
import { Camera } from "./camera";
import { MapFX, drawScene, hitTest, PLOT_VISUALS } from "./render";
import { game } from "../engine/game";
import { PLOTS } from "../theme/content";

export type MapSelection =
  | { type: "plot"; id: string }
  | { type: "district"; id: string };

interface Props {
  onSelect: (sel: MapSelection | null) => void;
}

export function MapCanvas({ onSelect }: Props) {
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const camRef = useRef(new Camera());

  useEffect(() => {
    const canvas = canvasRef.current!;
    const ctx = canvas.getContext("2d")!;
    const cam = camRef.current;
    const fx = new MapFX();
    const reducedMotion = window.matchMedia("(prefers-reduced-motion: reduce)").matches;

    let raf = 0;
    let lastT = performance.now();
    let viewW = 0, viewH = 0, dpr = Math.min(window.devicePixelRatio || 1, 2);

    const resize = () => {
      const rect = canvas.parentElement!.getBoundingClientRect();
      viewW = rect.width;
      viewH = rect.height;
      canvas.width = Math.round(viewW * dpr);
      canvas.height = Math.round(viewH * dpr);
      canvas.style.width = `${viewW}px`;
      canvas.style.height = `${viewH}px`;
      cam.setViewport(viewW, viewH);
    };
    resize();
    const ro = new ResizeObserver(resize);
    ro.observe(canvas.parentElement!);

    // payout events → floating bills on the producing building
    const offEvent = game.onEvent((e) => {
      if (e.kind !== "payout") return;
      const plot = PLOTS.find((p) => p.kind === "racket" && p.ref === e.hustleIndex);
      if (plot) fx.spawnPayout(plot.id, e.amount);
    });

    const loop = (t: number) => {
      const dt = Math.min((t - lastT) / 1000, 0.1);
      lastT = t;
      cam.tick(dt);
      fx.tick(dt, game);
      drawScene(ctx, cam, viewW, viewH, dpr, game, fx, t, reducedMotion);
      raf = requestAnimationFrame(loop);
    };
    raf = requestAnimationFrame(loop);

    // ---- input ----
    const pointers = new Map<number, { x: number; y: number }>();
    let pinchDist = 0;
    let downAt = 0;
    let downPos = { x: 0, y: 0 };
    let moved = false;
    let lastTapAt = 0;
    let lastTapPos = { x: 0, y: 0 };

    const pos = (e: PointerEvent) => {
      const r = canvas.getBoundingClientRect();
      return { x: e.clientX - r.left, y: e.clientY - r.top };
    };

    const onDown = (e: PointerEvent) => {
      canvas.setPointerCapture(e.pointerId);
      const p = pos(e);
      pointers.set(e.pointerId, p);
      cam.stopMomentum();
      if (pointers.size === 1) {
        downAt = performance.now();
        downPos = p;
        moved = false;
      } else if (pointers.size === 2) {
        const [a, b] = [...pointers.values()];
        pinchDist = Math.hypot(a.x - b.x, a.y - b.y);
      }
    };

    const onMove = (e: PointerEvent) => {
      if (!pointers.has(e.pointerId)) return;
      const p = pos(e);
      const prev = pointers.get(e.pointerId)!;
      pointers.set(e.pointerId, p);

      if (pointers.size === 1) {
        if (Math.hypot(p.x - downPos.x, p.y - downPos.y) > 8) moved = true;
        cam.panBy(p.x - prev.x, p.y - prev.y);
      } else if (pointers.size === 2) {
        const [a, b] = [...pointers.values()];
        const d = Math.hypot(a.x - b.x, a.y - b.y);
        if (pinchDist > 0) {
          cam.zoomAt((a.x + b.x) / 2, (a.y + b.y) / 2, d / pinchDist);
        }
        pinchDist = d;
        moved = true;
      }
    };

    const onUp = (e: PointerEvent) => {
      const p = pointers.get(e.pointerId);
      pointers.delete(e.pointerId);
      pinchDist = 0;
      if (!p || pointers.size > 0) return;

      const quick = performance.now() - downAt < 350;
      if (!moved && quick) {
        const now = performance.now();
        const isDouble =
          now - lastTapAt < 350 &&
          Math.hypot(p.x - lastTapPos.x, p.y - lastTapPos.y) < 30;
        lastTapAt = now;
        lastTapPos = p;
        if (isDouble) {
          cam.toggleZoom(p.x, p.y);
          return;
        }
        const w = cam.screenToWorld(p.x, p.y);
        const hit = hitTest(w.x, w.y, game);
        if (hit?.type === "plot") {
          const v = PLOT_VISUALS.find((pv) => pv.def.id === hit.id)!;
          cam.flyTo(v.def.x, v.def.y + 40, Math.max(cam.zoom, cam.districtZoom * 0.9));
        }
        onSelect(hit);
      }
    };

    const onWheel = (e: WheelEvent) => {
      e.preventDefault();
      const r = canvas.getBoundingClientRect();
      cam.zoomAt(e.clientX - r.left, e.clientY - r.top, e.deltaY < 0 ? 1.12 : 0.89);
    };

    canvas.addEventListener("pointerdown", onDown);
    canvas.addEventListener("pointermove", onMove);
    canvas.addEventListener("pointerup", onUp);
    canvas.addEventListener("pointercancel", onUp);
    canvas.addEventListener("wheel", onWheel, { passive: false });

    return () => {
      cancelAnimationFrame(raf);
      ro.disconnect();
      offEvent();
      canvas.removeEventListener("pointerdown", onDown);
      canvas.removeEventListener("pointermove", onMove);
      canvas.removeEventListener("pointerup", onUp);
      canvas.removeEventListener("pointercancel", onUp);
      canvas.removeEventListener("wheel", onWheel);
    };
  }, []);

  return (
    <div className="map-wrap">
      <canvas ref={canvasRef} className="map-canvas" />
    </div>
  );
}
