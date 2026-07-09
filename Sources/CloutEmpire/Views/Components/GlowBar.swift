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
                Capsule().fill(Color.black.opacity(0.35))
                if width > 2 {
                    Capsule()
                        .fill(LinearGradient(colors: [color, color.opacity(0.75)], startPoint: .leading, endPoint: .trailing))
                        .frame(width: width)
                        .overlay(alignment: .topLeading) {
                            Capsule()
                                .fill(Color.white.opacity(0.35))
                                .frame(width: max(0, width - 6), height: height * 0.35)
                                .offset(x: 3, y: 1)
                        }
                }
            }
        }
        .frame(height: height)
        .animation(.easeOut(duration: 0.1), value: progress)
    }
}
