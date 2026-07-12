// The "expensive" layer — a warm key light, edge vignette, and fine film grain
// laid over the whole phone so every screen reads as one lit, cinematic scene.
// Pure CSS/SVG, no assets, pointer-events: none, and it honors reduced-motion.

export function Atmosphere() {
  return (
    <div className="atmosphere" aria-hidden>
      <div className="atmo-key" />
      <div className="atmo-vignette" />
      <div className="atmo-grain" />
    </div>
  );
}
