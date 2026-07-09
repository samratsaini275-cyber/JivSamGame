import SwiftUI

/// One particle. Position advances in `ParticleField.step`; Canvas draws the result.
struct Particle {
    enum Kind {
        case cashPop(String) // floating "+$X" text
        case confetti
        case sparkle
    }

    let kind: Kind
    var position: CGPoint
    var velocity: CGVector
    var rotation: Double
    var spin: Double
    let color: Color
    let size: CGFloat
    let birth: TimeInterval
    let lifetime: TimeInterval

    func age(at now: TimeInterval) -> Double { (now - birth) / lifetime }
}

/// Lightweight particle pool shared through the environment. Views call `spawn…`;
/// the single `ParticleOverlay` at the root steps and renders everything.
final class ParticleField: ObservableObject {
    private(set) var particles: [Particle] = []
    private var lastStep: TimeInterval = 0

    func spawnCashPop(_ text: String, at point: CGPoint, color: Color = Theme.moneyGreen) {
        let now = Date.timeIntervalSinceReferenceDate
        particles.append(Particle(
            kind: .cashPop(text), position: point,
            velocity: CGVector(dx: Double.random(in: -6...6), dy: Double.random(in: -55 ... -40)),
            rotation: 0, spin: 0, color: color, size: 12, birth: now, lifetime: 1.1))
    }

    func spawnConfetti(at point: CGPoint, colors: [Color], count: Int = 26) {
        let now = Date.timeIntervalSinceReferenceDate
        for _ in 0..<count {
            particles.append(Particle(
                kind: .confetti, position: point,
                velocity: CGVector(dx: Double.random(in: -140...140), dy: Double.random(in: -220 ... -60)),
                rotation: Double.random(in: 0..<(2 * .pi)), spin: Double.random(in: -6...6),
                color: colors.randomElement() ?? .white,
                size: CGFloat.random(in: 4...7), birth: now, lifetime: Double.random(in: 1.0...1.8)))
        }
    }

    func spawnSparkles(at point: CGPoint, color: Color, count: Int = 10) {
        let now = Date.timeIntervalSinceReferenceDate
        for _ in 0..<count {
            let angle = Double.random(in: 0..<(2 * .pi))
            let speed = Double.random(in: 25...80)
            particles.append(Particle(
                kind: .sparkle, position: point,
                velocity: CGVector(dx: cos(angle) * speed, dy: sin(angle) * speed),
                rotation: 0, spin: 0, color: color,
                size: CGFloat.random(in: 2...4), birth: now, lifetime: 0.8))
        }
    }

    /// Advance simulation; called from the overlay's TimelineView each frame.
    func step(now: TimeInterval) {
        let dt = lastStep == 0 ? 1.0 / 60 : min(now - lastStep, 1.0 / 20)
        lastStep = now
        let gravity: Double = 210
        particles = particles.compactMap { p in
            guard p.age(at: now) < 1 else { return nil }
            var p = p
            p.position.x += p.velocity.dx * dt
            p.position.y += p.velocity.dy * dt
            if case .confetti = p.kind {
                p.velocity.dy += gravity * dt
                p.rotation += p.spin * dt
            }
            return p
        }
    }
}

/// Full-window Canvas that renders the shared field. Hit-testing disabled.
struct ParticleOverlay: View {
    @EnvironmentObject var field: ParticleField

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { ctx, _ in
                let now = timeline.date.timeIntervalSinceReferenceDate
                field.step(now: now)
                for p in field.particles {
                    let fade = 1 - p.age(at: now)
                    switch p.kind {
                    case .cashPop(let text):
                        let resolved = ctx.resolve(
                            Text(text)
                                .font(.system(size: p.size, weight: .heavy, design: .rounded))
                                .foregroundColor(p.color))
                        ctx.opacity = fade
                        ctx.draw(resolved, at: p.position)
                        ctx.opacity = 1
                    case .confetti:
                        var c = ctx
                        c.opacity = fade
                        c.translateBy(x: p.position.x, y: p.position.y)
                        c.rotate(by: .radians(p.rotation))
                        c.fill(Path(CGRect(x: -p.size / 2, y: -p.size / 4, width: p.size, height: p.size / 2)),
                               with: .color(p.color))
                    case .sparkle:
                        var c = ctx
                        c.opacity = fade
                        c.addFilter(.blur(radius: 0.5))
                        c.fill(Path(ellipseIn: CGRect(x: p.position.x - p.size / 2, y: p.position.y - p.size / 2,
                                                      width: p.size, height: p.size)),
                               with: .color(p.color))
                    }
                }
            }
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Card frame reporting (so payouts can spawn particles at the right card)

struct CardFramesKey: PreferenceKey {
    static var defaultValue: [Int: CGRect] = [:]
    static func reduce(value: inout [Int: CGRect], nextValue: () -> [Int: CGRect]) {
        value.merge(nextValue()) { _, new in new }
    }
}

extension View {
    /// Report this view's frame (in the named "game" space) as business card `index`.
    func reportCardFrame(_ index: Int) -> some View {
        background(GeometryReader { geo in
            Color.clear.preference(key: CardFramesKey.self,
                                   value: [index: geo.frame(in: .named("game"))])
        })
    }
}
