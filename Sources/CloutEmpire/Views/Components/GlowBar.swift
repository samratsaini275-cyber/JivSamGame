import SwiftUI

/// Progress bar that reads as progress: visible fill, bright leading edge,
/// and a slow shimmer along the fill while it's live.
struct GlowBar: View {
    var progress: Double
    var color: Color
    var height: CGFloat = 7

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { geo in
            let clamped = max(0, min(1, progress))
            let width = clamped * geo.size.width
            let radius = min(height * 0.5, 7)
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(Theme.ink.opacity(0.6))
                    .overlay(
                        RoundedRectangle(cornerRadius: radius, style: .continuous)
                            .strokeBorder(.white.opacity(0.08), lineWidth: 1)
                    )
                if width > 2 {
                    RoundedRectangle(cornerRadius: radius, style: .continuous)
                        .fill(
                            LinearGradient(colors: [color.opacity(0.65), color],
                                           startPoint: .leading, endPoint: .trailing)
                        )
                        .frame(width: width)
                        .overlay {
                            if !reduceMotion, clamped < 1 {
                                ShimmerSweep(period: 1.4, tint: .white)
                                    .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
                            }
                        }
                        // Bright leading edge.
                        .overlay(alignment: .trailing) {
                            Capsule()
                                .fill(Color.white.opacity(0.85))
                                .frame(width: 2, height: max(2, height - 2))
                                .padding(.trailing, 1)
                                .opacity(clamped < 1 ? 1 : 0)
                        }
                        .shadow(color: color.opacity(0.5), radius: 4, y: 0)
                }
            }
        }
        .frame(height: height)
        .animation(.easeOut(duration: 0.1), value: progress)
    }
}
