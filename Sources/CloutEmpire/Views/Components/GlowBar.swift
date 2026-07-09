import SwiftUI

/// Capsule progress bar with gradient fill, glow bloom, and a top shine line.
struct GlowBar: View {
    var progress: Double // 0...1
    var color: Color
    var height: CGFloat = 7

    var body: some View {
        GeometryReader { geo in
            let width = max(0, min(1, progress)) * geo.size.width
            ZStack(alignment: .leading) {
                Capsule().fill(Color.white.opacity(0.07))
                if width > height {
                    Capsule()
                        .fill(LinearGradient(colors: [color.opacity(0.85), color],
                                             startPoint: .leading, endPoint: .trailing))
                        .frame(width: width)
                        .overlay(alignment: .top) {
                            // shine line
                            Capsule()
                                .fill(Color.white.opacity(0.35))
                                .frame(width: max(0, width - 6), height: 1.5)
                                .offset(y: 1.5)
                        }
                        .glow(color, radius: 4)
                }
            }
        }
        .frame(height: height)
        .animation(.linear(duration: 0.1), value: progress)
    }
}
