// Map camera: pan / pinch / momentum / clamping. Resolution-independent —
// all game coordinates are world units; zoom maps world→CSS pixels.
import { WORLD } from "../theme/content";

export const ZOOM_CITY = 0; // fit whole city
export const ZOOM_DISTRICT = 1; // street level

export class Camera {
  x = WORLD.w / 2; // world point at viewport center
  y = WORLD.h / 2;
  zoom = 0.3;
  minZoom = 0.25;
  maxZoom = 1.1;

  private vx = 0;
  private vy = 0;
  private viewW = 1;
  private viewH = 1;

  private initialized = false;

  setViewport(w: number, h: number): void {
    this.viewW = w;
    this.viewH = h;
    // City must always fit on the short axis at min zoom.
    this.minZoom = Math.max(w / WORLD.w, h / WORLD.h) * 0.92;
    if (!this.initialized) {
      this.initialized = true;
      this.zoom = this.minZoom; // open on the whole city
    }
    this.zoom = Math.max(this.zoom, this.minZoom);
    this.clamp();
  }

  get cityZoom(): number {
    return this.minZoom;
  }

  get districtZoom(): number {
    return Math.min(this.maxZoom, this.minZoom * 2.4);
  }

  screenToWorld(sx: number, sy: number): { x: number; y: number } {
    return {
      x: this.x + (sx - this.viewW / 2) / this.zoom,
      y: this.y + (sy - this.viewH / 2) / this.zoom,
    };
  }

  panBy(dxScreen: number, dyScreen: number): void {
    this.x -= dxScreen / this.zoom;
    this.y -= dyScreen / this.zoom;
    this.vx = -dxScreen / this.zoom;
    this.vy = -dyScreen / this.zoom;
    this.clamp();
  }

  /** Zoom keeping the given screen point fixed. */
  zoomAt(sx: number, sy: number, factor: number): void {
    const before = this.screenToWorld(sx, sy);
    this.zoom = Math.min(this.maxZoom, Math.max(this.minZoom, this.zoom * factor));
    const after = this.screenToWorld(sx, sy);
    this.x += before.x - after.x;
    this.y += before.y - after.y;
    this.clamp();
  }

  /** Double-tap: toggle city ↔ district zoom centered on the tap. */
  toggleZoom(sx: number, sy: number): void {
    const target = this.zoom > (this.cityZoom + this.districtZoom) / 2
      ? this.cityZoom
      : this.districtZoom;
    const world = this.screenToWorld(sx, sy);
    this.animTarget = { x: world.x, y: world.y, zoom: target };
  }

  flyTo(wx: number, wy: number, zoom = this.districtZoom): void {
    this.animTarget = { x: wx, y: wy, zoom };
  }

  private animTarget: { x: number; y: number; zoom: number } | null = null;

  stopMomentum(): void {
    this.vx = 0;
    this.vy = 0;
    this.animTarget = null;
  }

  /** Advance momentum / fly animations. Call once per frame. */
  tick(dt: number): boolean {
    let moving = false;
    if (this.animTarget) {
      const t = this.animTarget;
      const k = 1 - Math.pow(0.002, dt); // exponential ease
      this.x += (t.x - this.x) * k;
      this.y += (t.y - this.y) * k;
      this.zoom += (t.zoom - this.zoom) * k;
      if (Math.abs(t.zoom - this.zoom) < 0.002 &&
          Math.hypot(t.x - this.x, t.y - this.y) < 1.5) {
        this.animTarget = null;
      }
      moving = true;
    } else if (Math.abs(this.vx) > 2 || Math.abs(this.vy) > 2) {
      this.x += this.vx * dt * 8;
      this.y += this.vy * dt * 8;
      const decay = Math.pow(0.02, dt);
      this.vx *= decay;
      this.vy *= decay;
      moving = true;
    }
    this.clamp();
    return moving;
  }

  private clamp(): void {
    const halfW = this.viewW / 2 / this.zoom;
    const halfH = this.viewH / 2 / this.zoom;
    const pad = 60;
    this.x = Math.min(WORLD.w + pad - halfW, Math.max(halfW - pad, this.x));
    this.y = Math.min(WORLD.h + pad - halfH, Math.max(halfH - pad, this.y));
    // If the world is smaller than the viewport on an axis, center it.
    if (halfW * 2 > WORLD.w + pad * 2) this.x = WORLD.w / 2;
    if (halfH * 2 > WORLD.h + pad * 2) this.y = WORLD.h / 2;
  }
}
