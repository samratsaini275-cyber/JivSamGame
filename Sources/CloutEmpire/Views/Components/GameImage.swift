import SwiftUI
import ImageIO

/// Bundled game asset from `Resources/Images/`.
struct GameImage: View {
    let name: String
    var size: CGFloat = 44
    var dimmed: Bool = false

    var body: some View {
        Group {
            if let cgImage = Self.loadCGImage(named: name) {
                Image(decorative: cgImage, scale: 2, orientation: .up)
                    .resizable()
                    .interpolation(.high)
                    .aspectRatio(contentMode: .fit)
            } else {
                Image(systemName: "photo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .foregroundStyle(Theme.cloutPink.opacity(0.5))
            }
        }
        .frame(width: size, height: size)
        .saturation(dimmed ? 0 : 1)
        .opacity(dimmed ? 0.45 : 1)
    }

    private static func loadCGImage(named name: String) -> CGImage? {
        guard let url = GameBundle.pngURL(named: name),
              let source = CGImageSourceCreateWithURL(url as CFURL, nil) else {
            return nil
        }
        return CGImageSourceCreateImageAtIndex(source, 0, nil)
    }
}

/// Framed production icon tile.
struct GameIconTile: View {
    let name: String
    var size: CGFloat = 50
    var dimmed: Bool = false
    var tint: Color = .white

    var body: some View {
        GameImage(name: name, size: size * 0.70, dimmed: dimmed)
            .frame(width: size, height: size)
            .background(
                RoundedRectangle(cornerRadius: min(14, size * 0.22), style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                dimmed ? Theme.surfaceRaised : tint.opacity(0.42),
                                Theme.arcadePurple.opacity(dimmed ? 0.12 : 0.36),
                                Theme.ink.opacity(0.78),
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: min(14, size * 0.22), style: .continuous)
                    .strokeBorder(dimmed ? .white.opacity(0.12) : tint.opacity(0.82), lineWidth: 2.5)
            )
            .overlay(alignment: .topLeading) {
                Circle()
                    .fill(.white.opacity(dimmed ? 0.05 : 0.20))
                    .frame(width: size * 0.36, height: size * 0.36)
                    .offset(x: size * 0.10, y: size * 0.08)
            }
            .shadow(color: dimmed ? .clear : tint.opacity(0.36), radius: 14, y: 5)
            .shadow(color: .black.opacity(0.45), radius: 10, y: 7)
    }
}
