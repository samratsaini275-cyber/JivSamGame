// Procedural vector renderer for the New Carthage map. No bitmap assets —
// everything is paths + emoji glyphs, so it stays crisp at any DPI/zoom.
import { Camera } from "./camera";
import {
  WORLD, DISTRICTS, DistrictDef, PLOTS, PlotDef, LANDMARKS, FRONTS,
  MAP_COPY, PALETTE, SHIPMENT_ROUTES,
} from "../theme/content";
import { HUSTLES } from "../engine/data";
import { Game } from "../engine/game";
import { money, abbreviate } from "../ui/format";
import { unitCost } from "../engine/formulas";
import { racketIcon, frontIcon } from "../theme/icons";

// Pre-rasterized medallion plates for building faces (emoji as fallback).
const iconImages = new Map<string, HTMLImageElement>();
function plotIconImage(def: PlotDef): HTMLImageElement | null {
  if (typeof Image === "undefined") return null;
  const key = `${def.kind}:${def.ref}`;
  let img = iconImages.get(key);
  if (img) return img.complete && img.naturalWidth > 0 ? img : null;
  const uri = def.kind === "racket"
    ? racketIcon(def.ref as number)
    : def.kind === "front"
      ? frontIcon(def.ref as string)
      : null;
  if (!uri) return null;
  img = new Image();
  img.src = uri;
  iconImages.set(key, img);
  return img.complete && img.naturalWidth > 0 ? img : null;
}

export interface PlotVisual {
  def: PlotDef;
  w: number;
  h: number;
  /** world-space bounding box for hit tests */
  x0: number; y0: number; x1: number; y1: number;
}

export function plotVisual(def: PlotDef): PlotVisual {
  const s = def.size ?? 1;
  const w = 96 * s;
  const h = 74 * s;
  return { def, w, h, x0: def.x - w / 2, y0: def.y - h, x1: def.x + w / 2, y1: def.y + 14 };
}

export const PLOT_VISUALS: PlotVisual[] = PLOTS.map(plotVisual);

// ---------------------------------------------------------------------------
// FX entities (cosmetic only, driven by economy events)
// ---------------------------------------------------------------------------

interface Bill { x: number; y: number; vy: number; age: number; life: number; text: string }
interface Truck { fromX: number; fromY: number; toX: number; toY: number; t: number; dur: number }

const MAX_BILLS = 40;
const MAX_TRUCKS = 2;

export class MapFX {
  bills: Bill[] = [];
  trucks: Truck[] = [];
  private truckTimer = 4;

  spawnPayout(plotID: string, amount: number): void {
    if (this.bills.length >= MAX_BILLS) return;
    const v = PLOT_VISUALS.find((p) => p.def.id === plotID);
    if (!v) return;
    this.bills.push({
      x: v.def.x + (Math.random() - 0.5) * v.w * 0.5,
      y: v.y0 + 8,
      vy: -26 - Math.random() * 14,
      age: 0,
      life: 1.4,
      text: `+${abbreviate(amount)}`,
    });
  }

  tick(dt: number, game: Game): void {
    for (const b of this.bills) { b.age += dt; b.y += b.vy * dt; }
    this.bills = this.bills.filter((b) => b.age < b.life);

    for (const t of this.trucks) t.t += dt / t.dur;
    this.trucks = this.trucks.filter((t) => t.t < 1);

    this.truckTimer -= dt;
    if (this.truckTimer <= 0 && this.trucks.length < MAX_TRUCKS) {
      this.truckTimer = 6 + Math.random() * 6;
      const owned = PLOT_VISUALS.filter((p) =>
        p.def.kind === "racket" &&
        game.districtUnlocked(p.def.district) &&
        game.state.hustles[p.def.ref as number]?.unitsOwned > 0);
      if (owned.length >= 2) {
        const a = owned[Math.floor(Math.random() * owned.length)];
        let b = owned[Math.floor(Math.random() * owned.length)];
        if (b === a) b = owned[(owned.indexOf(a) + 1) % owned.length];
        this.trucks.push({
          fromX: a.def.x, fromY: a.def.y + 20,
          toX: b.def.x, toY: b.def.y + 20,
          t: 0, dur: 5 + Math.random() * 3,
        });
      }
    }
  }
}

// ---------------------------------------------------------------------------
// Scene
// ---------------------------------------------------------------------------

const WATER = "#152b30";
const WATER_LINE = "rgba(120, 180, 175, 0.16)";
const ROAD = "rgba(20, 16, 12, 0.35)";
const LOCKED_LAND = "#4a4436";

/** 0 (noon) → 1 (midnight). ~4 minute full cycle. */
export function nightFactor(now: number): number {
  const t = (now / 1000 / 240) % 1;
  return (Math.sin(t * Math.PI * 2 - Math.PI / 2) + 1) / 2;
}

export function drawScene(
  ctx: CanvasRenderingContext2D,
  cam: Camera,
  viewW: number,
  viewH: number,
  dpr: number,
  game: Game,
  fx: MapFX,
  now: number,
  reducedMotion: boolean,
): void {
  const night = reducedMotion ? 0.25 : nightFactor(now);

  // The harbor: a lit sea, deep at the horizon, warm brass glimmer up top.
  ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
  const sea = ctx.createLinearGradient(0, 0, 0, viewH);
  sea.addColorStop(0, "#1a3339");
  sea.addColorStop(0.45, "#132a30");
  sea.addColorStop(1, "#0c1c22");
  ctx.fillStyle = sea;
  ctx.fillRect(0, 0, viewW, viewH);
  // brass light reflecting off the top of the water
  const glim = ctx.createRadialGradient(viewW * 0.5, -viewH * 0.15, 0, viewW * 0.5, -viewH * 0.15, viewH * 0.9);
  glim.addColorStop(0, "rgba(212, 169, 67, 0.14)");
  glim.addColorStop(1, "transparent");
  ctx.fillStyle = glim;
  ctx.fillRect(0, 0, viewW, viewH);

  // world transform
  ctx.setTransform(
    dpr * cam.zoom, 0, 0, dpr * cam.zoom,
    dpr * (viewW / 2 - cam.x * cam.zoom),
    dpr * (viewH / 2 - cam.y * cam.zoom),
  );

  // Visible world bounds for culling (generous margin for signs/labels).
  const halfW = viewW / 2 / cam.zoom;
  const halfH = viewH / 2 / cam.zoom;
  const vx0 = cam.x - halfW - 80, vx1 = cam.x + halfW + 80;
  const vy0 = cam.y - halfH - 80, vy1 = cam.y + halfH + 80;

  drawWaterLines(ctx, now, reducedMotion);
  // engraved chart label in the open water
  ctx.save();
  ctx.textAlign = "center";
  ctx.font = "24px Limelight, serif";
  ctx.fillStyle = "rgba(140, 185, 178, 0.22)";
  ctx.fillText("NEW  CARTHAGE  HARBOR", 1000, 1365);
  ctx.font = "13px Limelight, serif";
  ctx.fillText("EST. 1926", 1000, 1385);
  ctx.restore();
  drawBridges(ctx);
  for (const d of DISTRICTS) {
    const r = d.rect;
    if (r.x + r.w < vx0 || r.x > vx1 || r.y + r.h < vy0 || r.y > vy1) continue;
    drawDistrict(ctx, d, game.districtUnlocked(d.id), game, night);
  }
  drawCompass(ctx);

  // plots (culled to the viewport)
  for (const v of PLOT_VISUALS) {
    if (v.x1 < vx0 || v.x0 > vx1 || v.y1 < vy0 || v.y0 > vy1) continue;
    const unlocked = game.districtUnlocked(v.def.district);
    drawPlot(ctx, v, game, unlocked, now, night);
  }

  // trucks
  ctx.save();
  for (const t of fx.trucks) {
    // L-shaped path: horizontal leg then vertical leg
    const half = 0.5;
    let x: number, y: number;
    if (t.t < half) {
      const k = t.t / half;
      x = t.fromX + (t.toX - t.fromX) * k;
      y = t.fromY;
    } else {
      const k = (t.t - half) / half;
      x = t.toX;
      y = t.fromY + (t.toY - t.fromY) * k;
    }
    ctx.fillStyle = "#20242e";
    ctx.strokeStyle = PALETTE.goldDeep;
    ctx.lineWidth = 1.5;
    ctx.beginPath();
    ctx.roundRect(x - 13, y - 7, 26, 14, 3);
    ctx.fill();
    ctx.stroke();
    ctx.fillStyle = "#101318";
    ctx.fillRect(x + 4, y - 5, 7, 10);
  }
  ctx.restore();

  drawActiveShipment(ctx, game, now);

  // cash bills
  ctx.textAlign = "center";
  for (const b of fx.bills) {
    const a = 1 - b.age / b.life;
    ctx.globalAlpha = Math.min(1, a * 1.6);
    ctx.font = "700 15px 'Barlow Condensed', sans-serif";
    ctx.fillStyle = "#c9de9d";
    ctx.strokeStyle = "rgba(0,0,0,0.55)";
    ctx.lineWidth = 2.5;
    ctx.strokeText(b.text, b.x, b.y);
    ctx.fillText(b.text, b.x, b.y);
  }
  ctx.globalAlpha = 1;

  // day/night tint over the whole world
  ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
  if (night > 0.02) {
    ctx.fillStyle = `rgba(10, 14, 34, ${0.32 * night})`;
    ctx.fillRect(0, 0, viewW, viewH);
  }
}

/** The in-flight shipment vehicle: gold-trimmed, unmistakably yours. */
function drawActiveShipment(ctx: CanvasRenderingContext2D, game: Game, now: number): void {
  const sh = game.state.activeShipment;
  if (!sh) return;
  const route = SHIPMENT_ROUTES.find((r) => r.id === sh.routeID);
  if (!route) return;
  const from = PLOT_VISUALS.find((p) => p.def.id === route.fromPlot);
  const to = PLOT_VISUALS.find((p) => p.def.id === route.toPlot);
  if (!from || !to) return;

  // Freeze at the checkpoint while the player decides.
  const clock = sh.checkpointAt > 0 && !sh.checkpointResolved && now >= sh.checkpointAt
    ? sh.checkpointAt
    : Math.min(now, sh.arrivesAt);
  const p = Math.min(1, Math.max(0, (clock - sh.departedAt) / (sh.arrivesAt - sh.departedAt)));

  let x: number, y: number;
  if (route.vehicle === "boat") {
    // Boats swing out into the water on a shallow arc.
    const midX = (from.def.x + to.def.x) / 2;
    const midY = Math.max(from.def.y, to.def.y) + 120;
    const t = p;
    x = (1 - t) * (1 - t) * from.def.x + 2 * (1 - t) * t * midX + t * t * to.def.x;
    y = (1 - t) * (1 - t) * (from.def.y + 20) + 2 * (1 - t) * t * midY + t * t * (to.def.y + 20);
  } else if (p < 0.5) {
    x = from.def.x + (to.def.x - from.def.x) * (p / 0.5);
    y = from.def.y + 20;
  } else {
    x = to.def.x;
    y = from.def.y + 20 + (to.def.y - from.def.y) * ((p - 0.5) / 0.5);
  }

  ctx.save();
  if (route.vehicle === "boat") {
    ctx.fillStyle = "#1c2130";
    ctx.strokeStyle = PALETTE.gold;
    ctx.lineWidth = 2;
    ctx.beginPath();
    ctx.moveTo(x - 18, y - 4);
    ctx.lineTo(x + 18, y - 4);
    ctx.lineTo(x + 10, y + 8);
    ctx.lineTo(x - 10, y + 8);
    ctx.closePath();
    ctx.fill();
    ctx.stroke();
    ctx.fillStyle = PALETTE.paper;
    ctx.fillRect(x - 3, y - 16, 5, 12);
    // wake
    ctx.strokeStyle = "rgba(232, 220, 195, 0.3)";
    ctx.lineWidth = 1.5;
    ctx.beginPath();
    ctx.moveTo(x - 22, y + 10);
    ctx.lineTo(x - 34, y + 13);
    ctx.moveTo(x - 22, y + 4);
    ctx.lineTo(x - 32, y + 4);
    ctx.stroke();
  } else {
    ctx.fillStyle = "#1c2130";
    ctx.strokeStyle = PALETTE.gold;
    ctx.lineWidth = 2;
    ctx.beginPath();
    ctx.roundRect(x - 15, y - 9, 30, 17, 4);
    ctx.fill();
    ctx.stroke();
    ctx.fillStyle = PALETTE.goldDeep;
    ctx.fillRect(x + 5, y - 6, 8, 11);
    ctx.fillStyle = "#0a0c11";
    ctx.beginPath();
    ctx.arc(x - 8, y + 9, 3.5, 0, Math.PI * 2);
    ctx.arc(x + 8, y + 9, 3.5, 0, Math.PI * 2);
    ctx.fill();
  }
  // cargo tag
  ctx.textAlign = "center";
  ctx.font = "900 9px 'Barlow Condensed', sans-serif";
  ctx.fillStyle = PALETTE.gold;
  ctx.fillText(route.emoji + " " + route.name.toUpperCase(), x, y - 20);
  ctx.restore();
}

function drawWaterLines(ctx: CanvasRenderingContext2D, now: number, reduced: boolean): void {
  const phase = reduced ? 0 : (now / 1200) % (Math.PI * 2);
  ctx.strokeStyle = WATER_LINE;
  ctx.lineWidth = 2;
  for (let i = 0; i < 7; i++) {
    const y = 240 + i * 170;
    ctx.beginPath();
    for (let x = 0; x <= WORLD.w; x += 40) {
      const yy = y + Math.sin(x / 130 + phase + i) * 6;
      x === 0 ? ctx.moveTo(x, yy) : ctx.lineTo(x, yy);
    }
    ctx.stroke();
  }
}

function drawBridges(ctx: CanvasRenderingContext2D): void {
  ctx.strokeStyle = "#3a332a";
  ctx.lineWidth = 26;
  ctx.lineCap = "round";
  // downtown → islands bridge
  ctx.beginPath();
  ctx.moveTo(1240, 860);
  ctx.lineTo(1500, 1000);
  ctx.stroke();
  ctx.strokeStyle = PALETTE.goldDeep;
  ctx.lineWidth = 2;
  ctx.setLineDash([14, 10]);
  ctx.beginPath();
  ctx.moveTo(1240, 860);
  ctx.lineTo(1500, 1000);
  ctx.stroke();
  ctx.setLineDash([]);
  ctx.lineCap = "butt";
}

function drawDistrict(
  ctx: CanvasRenderingContext2D,
  d: DistrictDef,
  unlocked: boolean,
  game: Game,
  night: number,
): void {
  const { x, y, w, h } = d.rect;

  // Coastline glow — the land catches the harbor light at its edge.
  ctx.save();
  ctx.shadowColor = unlocked ? "rgba(0, 0, 0, 0.55)" : "rgba(0, 0, 0, 0.4)";
  ctx.shadowBlur = 28;
  ctx.shadowOffsetY = 10;
  ctx.fillStyle = unlocked ? d.tint : LOCKED_LAND;
  ctx.beginPath();
  ctx.roundRect(x, y, w, h, 26);
  ctx.fill();
  ctx.restore();

  // Parchment shading on the land: warm top light, cool at the water's edge.
  const land = ctx.createLinearGradient(x, y, x, y + h);
  if (unlocked) {
    land.addColorStop(0, "rgba(255, 240, 205, 0.14)");
    land.addColorStop(0.5, "rgba(0, 0, 0, 0)");
    land.addColorStop(1, "rgba(10, 20, 24, 0.28)");
  } else {
    land.addColorStop(0, "rgba(255, 240, 205, 0.05)");
    land.addColorStop(1, "rgba(10, 20, 24, 0.35)");
  }
  ctx.fillStyle = land;
  ctx.beginPath();
  ctx.roundRect(x, y, w, h, 26);
  ctx.fill();

  // City blocks: a road grid with subtly shaded block interiors.
  if (unlocked) {
    ctx.save();
    ctx.beginPath();
    ctx.roundRect(x + 6, y + 6, w - 12, h - 12, 20);
    ctx.clip();
    const cols = 3, rows = 3;
    const cw = w / cols, ch = h / rows;
    ctx.fillStyle = "rgba(0, 0, 0, 0.08)";
    for (let r = 0; r < rows; r++) {
      for (let c = 0; c < cols; c++) {
        if ((r + c) % 2 === 0) ctx.fillRect(x + c * cw, y + r * ch, cw, ch);
      }
    }
    ctx.strokeStyle = ROAD;
    ctx.lineWidth = 9;
    ctx.beginPath();
    for (let c = 1; c < cols; c++) { ctx.moveTo(x + c * cw, y); ctx.lineTo(x + c * cw, y + h); }
    for (let r = 1; r < rows; r++) { ctx.moveTo(x, y + r * ch); ctx.lineTo(x + w, y + r * ch); }
    ctx.stroke();
    // road centre-lines
    ctx.strokeStyle = "rgba(224, 200, 150, 0.14)";
    ctx.lineWidth = 1;
    ctx.setLineDash([8, 10]);
    ctx.stroke();
    ctx.setLineDash([]);
    ctx.restore();
  }

  // deco double keyline border
  ctx.strokeStyle = unlocked ? "rgba(224, 182, 79, 0.6)" : "rgba(232, 220, 195, 0.2)";
  ctx.lineWidth = 3;
  ctx.beginPath();
  ctx.roundRect(x, y, w, h, 26);
  ctx.stroke();
  ctx.strokeStyle = unlocked ? "rgba(42, 32, 24, 0.55)" : "rgba(0, 0, 0, 0.35)";
  ctx.lineWidth = 1;
  ctx.beginPath();
  ctx.roundRect(x + 7, y + 7, w - 14, h - 14, 20);
  ctx.stroke();

  if (unlocked) {
    // Engraved name plate riveted to the district's top edge.
    const label = d.name.toUpperCase();
    ctx.font = "15px Limelight, serif";
    const pw = Math.max(ctx.measureText(label).width + 34, 120);
    const px = x + w / 2 - pw / 2, py = y - 15, ph = 28;
    ctx.fillStyle = "rgba(14, 18, 24, 0.94)";
    ctx.beginPath();
    ctx.roundRect(px, py, pw, ph, 5);
    ctx.fill();
    ctx.strokeStyle = "rgba(212, 169, 67, 0.65)";
    ctx.lineWidth = 1.5;
    ctx.stroke();
    ctx.fillStyle = PALETTE.gold;
    ctx.fillText("◆", px + 13, py + 19);
    ctx.fillText("◆", px + pw - 13, py + 19);
    ctx.fillStyle = "#efe4c8";
    ctx.fillText(label, x + w / 2, py + 19);
  } else {
    // sepia silhouette + ribbon
    ctx.fillStyle = "rgba(232, 220, 195, 0.5)";
    ctx.fillText(d.name.toUpperCase(), x + w / 2, y + h / 2 - 26);
    ctx.font = "700 12px 'Barlow Condensed', sans-serif";
    ctx.fillStyle = "rgba(232, 220, 195, 0.4)";
    ctx.fillText(MAP_COPY.locked("", d.respectLevel).replace(" — ", ""), x + w / 2, y + h / 2 - 6);
    // ribbon
    const rw = 150, rh = 26;
    ctx.fillStyle = PALETTE.heatRed;
    ctx.save();
    ctx.translate(x + w / 2, y + h / 2 + 26);
    ctx.rotate(-0.05);
    ctx.fillRect(-rw / 2, -rh / 2, rw, rh);
    ctx.fillStyle = PALETTE.paper;
    ctx.font = "700 12px 'Barlow Condensed', sans-serif";
    ctx.fillText(`${MAP_COPY.forSale} · ${money(d.price)}`, 0, 4);
    ctx.restore();
  }
}

function drawCompass(ctx: CanvasRenderingContext2D): void {
  const cx = 90, cy = 120, r = 34;
  ctx.strokeStyle = "rgba(232, 220, 195, 0.4)";
  ctx.lineWidth = 2;
  ctx.beginPath();
  ctx.arc(cx, cy, r, 0, Math.PI * 2);
  ctx.stroke();
  ctx.beginPath();
  ctx.moveTo(cx, cy - r + 6);
  ctx.lineTo(cx + 7, cy + 7);
  ctx.lineTo(cx, cy + r - 6);
  ctx.lineTo(cx - 7, cy + 7);
  ctx.closePath();
  ctx.fillStyle = "rgba(224, 182, 79, 0.55)";
  ctx.fill();
  ctx.font = "12px Limelight, serif";
  ctx.fillStyle = "rgba(232, 220, 195, 0.55)";
  ctx.textAlign = "center";
  ctx.fillText("N", cx, cy - r - 8);
}

function drawPlot(
  ctx: CanvasRenderingContext2D,
  v: PlotVisual,
  game: Game,
  districtUnlocked: boolean,
  now: number,
  night: number,
): void {
  const { def, w, h } = v;
  const x = def.x - w / 2;
  const y = def.y - h;

  // Hidden: dark silhouette only.
  if (!districtUnlocked) {
    ctx.fillStyle = "rgba(20, 18, 14, 0.5)";
    ctx.beginPath();
    ctx.roundRect(x, y + h * 0.25, w, h * 0.75, 6);
    ctx.fill();
    return;
  }

  const state = plotState(def, game);
  const owned = state === "owned";

  // Ground shadow so the building sits on the land, not floats.
  ctx.save();
  ctx.fillStyle = "rgba(0, 0, 0, 0.32)";
  ctx.beginPath();
  ctx.ellipse(def.x, y + h * 0.99, w * 0.52, h * 0.12, 0, 0, Math.PI * 2);
  ctx.fill();
  ctx.restore();

  // Owned buildings throw a warm pool of lamplight onto the street.
  if (owned) {
    ctx.save();
    const halo = ctx.createRadialGradient(def.x, y + h * 0.5, 2, def.x, y + h * 0.5, w * 0.95);
    halo.addColorStop(0, "rgba(255, 205, 120, 0.16)");
    halo.addColorStop(1, "transparent");
    ctx.fillStyle = halo;
    ctx.fillRect(def.x - w, y - h * 0.3, w * 2, h * 1.8);
    ctx.restore();
  }

  // base body, lit down its face
  const bodyGrad = ctx.createLinearGradient(x, y, x + w, y);
  if (owned) { bodyGrad.addColorStop(0, "#453d55"); bodyGrad.addColorStop(1, "#2c2739"); }
  else if (state === "for_sale") { bodyGrad.addColorStop(0, "#443f34"); bodyGrad.addColorStop(1, "#302c24"); }
  else { bodyGrad.addColorStop(0, "#38332f"); bodyGrad.addColorStop(1, "#252220"); }
  ctx.fillStyle = bodyGrad;
  ctx.beginPath();
  ctx.roundRect(x, y + h * 0.22, w, h * 0.78, 6);
  ctx.fill();
  ctx.strokeStyle = owned ? "rgba(224, 182, 79, 0.7)" : "rgba(0,0,0,0.4)";
  ctx.lineWidth = 2;
  ctx.stroke();

  // roof, catching top light
  const roofGrad = ctx.createLinearGradient(x, y, x, y + h * 0.25);
  if (owned) { roofGrad.addColorStop(0, "#332b44"); roofGrad.addColorStop(1, "#1e1a29"); }
  else { roofGrad.addColorStop(0, "#2c2925"); roofGrad.addColorStop(1, "#1c1a17"); }
  ctx.fillStyle = roofGrad;
  ctx.beginPath();
  ctx.moveTo(x - 4, y + h * 0.25);
  ctx.lineTo(x + w * 0.5, y);
  ctx.lineTo(x + w + 4, y + h * 0.25);
  ctx.closePath();
  ctx.fill();

  // windows (lit when owned; brighter at night; light flicker)
  const lit = state === "owned";
  const flick = lit ? 0.75 + 0.25 * Math.sin(now / 300 + def.x) : 0;
  const winAlpha = lit ? 0.35 + 0.55 * Math.max(night, 0.25) * flick : 0.12;
  ctx.fillStyle = `rgba(255, 214, 120, ${winAlpha})`;
  const rows = 2, cols = 3;
  for (let r = 0; r < rows; r++) {
    for (let c = 0; c < cols; c++) {
      ctx.fillRect(
        x + w * (0.16 + c * 0.26), y + h * (0.36 + r * 0.26),
        w * 0.14, h * 0.16,
      );
    }
  }

  // face plate: brass medallion, emoji as fallback while it rasterizes
  const plate = plotIconImage(def);
  ctx.globalAlpha = state === "for_sale" ? 0.8 : 1;
  if (plate) {
    const ps = 34 * (def.size ?? 1);
    ctx.drawImage(plate, def.x - ps / 2, y - h * 0.12 - ps / 2, ps, ps);
  } else {
    ctx.textAlign = "center";
    ctx.font = `${Math.round(26 * (def.size ?? 1))}px sans-serif`;
    ctx.fillText(plotEmoji(def), def.x, y + h * 0.2);
  }
  ctx.globalAlpha = 1;

  // name + status
  ctx.font = "700 11px 'Barlow Condensed', sans-serif";
  ctx.fillStyle = "rgba(232, 220, 195, 0.85)";
  ctx.fillText(plotName(def), def.x, def.y + 13);

  if (state === "raided") {
    // boards
    ctx.strokeStyle = "#5a4a33";
    ctx.lineWidth = 7;
    ctx.beginPath();
    ctx.moveTo(x + 6, y + h * 0.3);
    ctx.lineTo(x + w - 6, y + h * 0.9);
    ctx.moveTo(x + w - 6, y + h * 0.3);
    ctx.lineTo(x + 6, y + h * 0.9);
    ctx.stroke();
    // police tape
    ctx.save();
    ctx.translate(def.x, y + h * 0.6);
    ctx.rotate(-0.08);
    ctx.fillStyle = "#d9b23b";
    ctx.fillRect(-w / 2 - 8, -7, w + 16, 14);
    ctx.fillStyle = "#17130c";
    ctx.font = "900 8px 'Barlow Condensed', sans-serif";
    ctx.fillText("POLICE LINE · DO NOT CROSS", 0, 3);
    ctx.restore();
  }

  if (state === "for_sale") {
    const price = plotPrice(def, game);
    const afford = price !== null && plotAffordable(def, game);
    const pulse = afford ? 0.75 + 0.25 * Math.sin(now / 260) : 0.9;
    // FOR SALE sign
    ctx.save();
    ctx.translate(def.x, y - 10);
    ctx.rotate(-0.06);
    ctx.fillStyle = `rgba(232, 220, 195, ${pulse})`;
    ctx.fillRect(-34, -12, 68, 20);
    ctx.strokeStyle = afford ? PALETTE.gold : "rgba(42,32,24,0.7)";
    ctx.lineWidth = afford ? 2.5 : 1.5;
    ctx.strokeRect(-34, -12, 68, 20);
    ctx.fillStyle = "#2a2018";
    ctx.font = "900 9px 'Barlow Condensed', sans-serif";
    ctx.fillText(MAP_COPY.forSale, 0, -2);
    ctx.font = "700 8px 'Barlow Condensed', sans-serif";
    ctx.fillText(price === null ? "" : money(price), 0, 7);
    ctx.restore();
  } else if (state === "owned") {
    const badge = plotBadge(def, game);
    if (badge) {
      ctx.fillStyle = "rgba(16, 19, 26, 0.85)";
      const bw = ctx.measureText(badge).width + 14;
      ctx.beginPath();
      ctx.roundRect(def.x - bw / 2, y - 18, bw, 15, 7);
      ctx.fill();
      ctx.strokeStyle = "rgba(224, 182, 79, 0.5)";
      ctx.lineWidth = 1;
      ctx.stroke();
      ctx.fillStyle = PALETTE.gold;
      ctx.font = "700 9.5px 'Barlow Condensed', sans-serif";
      ctx.fillText(badge, def.x, y - 7);
    }
  }
}

export type PlotState = "hidden" | "for_sale" | "owned" | "raided" | "civic";

export function plotState(def: PlotDef, game: Game): PlotState {
  if (def.kind === "precinct" || def.kind === "landmark") return "civic";
  if (def.kind === "racket") {
    const i = def.ref as number;
    if (game.isRaided(i)) return "raided";
    return game.state.hustles[i].unitsOwned > 0 ? "owned" : "for_sale";
  }
  return game.frontLevel(def.ref as string) > 0 ? "owned" : "for_sale";
}

export function plotName(def: PlotDef): string {
  if (def.kind === "racket") return HUSTLES[def.ref as number].name;
  if (def.kind === "front") return FRONTS.find((f) => f.id === def.ref)!.name;
  return LANDMARKS[def.ref as string].name;
}

export function plotEmoji(def: PlotDef): string {
  if (def.kind === "racket") return HUSTLES[def.ref as number].emoji;
  if (def.kind === "front") return FRONTS.find((f) => f.id === def.ref)!.emoji;
  return LANDMARKS[def.ref as string].emoji;
}

function plotPrice(def: PlotDef, game: Game): number | null {
  if (def.kind === "racket") return unitCost(HUSTLES[def.ref as number].baseCost, 0);
  if (def.kind === "front") return FRONTS.find((f) => f.id === def.ref)!.price;
  return null;
}

function plotAffordable(def: PlotDef, game: Game): boolean {
  if (def.kind === "racket") {
    return game.state.cash >= unitCost(HUSTLES[def.ref as number].baseCost, 0);
  }
  if (def.kind === "front") {
    return game.canAffordFront(FRONTS.find((f) => f.id === def.ref)!);
  }
  return false;
}

function plotBadge(def: PlotDef, game: Game): string | null {
  if (def.kind === "racket") {
    const units = game.state.hustles[def.ref as number].unitsOwned;
    return `×${units.toLocaleString()}`;
  }
  if (def.kind === "front") {
    return `Lv ${game.frontLevel(def.ref as string)}`;
  }
  return null;
}

/** Topmost plot whose box contains the world point, or the locked district hit. */
export function hitTest(
  wx: number,
  wy: number,
  game: Game,
): { type: "plot"; id: string } | { type: "district"; id: string } | null {
  for (const v of PLOT_VISUALS) {
    if (wx >= v.x0 && wx <= v.x1 && wy >= v.y0 - 24 && wy <= v.y1) {
      if (!game.districtUnlocked(v.def.district)) break; // fall through to district
      return { type: "plot", id: v.def.id };
    }
  }
  for (const d of DISTRICTS) {
    const { x, y, w, h } = d.rect;
    if (wx >= x && wx <= x + w && wy >= y && wy <= y + h) {
      return { type: "district", id: d.id };
    }
  }
  return null;
}
