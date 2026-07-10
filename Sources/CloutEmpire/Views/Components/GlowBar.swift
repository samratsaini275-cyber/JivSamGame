import SwiftUI

struct GlowBar: View {
    var progress: Double
    var color: Color
    var height: CGFloat = 7

    var body: some View {
        GeometryReader { geo in
            let clamped = max(0, min(1, progress))
            let width = clamped * geo.size.width
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: min(7, height * 0.5), style: .continuous)
                    .fill(Color.black.opacity(0.58))
                    .overlay(RoundedRectangle(cornerRadius: min(7, height * 0.5), style: .continuous).strokeBorder(.white.opacity(0.12), lineWidth: 1))
                if width > 2 {
                    RoundedRectangle(cornerRadius: min(7, height * 0.5), style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    color.opacity(0.95),
                                    color,
                                    color.opacity(0.70),
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: width)
                        .overlay(alignment: .topLeading) {
                            RoundedRectangle(cornerRadius: min(5, height * 0.35), style: .continuous)
                                .fill(Color.white.opacity(0.24))
                                .frame(width: max(0, width - 6), height: height * 0.35)
                                .offset(x: 3, y: 1)
                        }
                        .overlay {
                            DiagonalStripeOverlay()
                                .clipShape(RoundedRectangle(cornerRadius: min(7, height * 0.5), style: .continuous))
                                .opacity(0.30)
                        }
                        .shadow(color: color.opacity(0.55), radius: 7, y: 0)
                }
            }
        }
        .frame(height: height)
        .animation(.easeOut(duration: 0.1), value: progress)
    }
}

private struct DiagonalStripeOverlay: View {
    var body: some View {
        Canvas { context, size in
            var path = Path()
            var x: CGFloat = -size.height
            while x < size.width + size.height {
                path.move(to: CGPoint(x: x, y: size.height))
                path.addLine(to: CGPoint(x: x + size.height, y: 0))
                x += 18
            }
            context.stroke(path, with: .color(.white), lineWidth: 5)
        }
    }
}
