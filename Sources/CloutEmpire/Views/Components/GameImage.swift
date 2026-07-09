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
        GameImage(name: name, size: size * 0.62, dimmed: dimmed)
            .frame(width: size, height: size)
            .background(
                RoundedRectangle(cornerRadius: min(8, size * 0.16), style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                dimmed ? Theme.surfaceRaised : tint.opacity(0.22),
                                Theme.ink.opacity(0.65),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: min(8, size * 0.16), style: .continuous)
                    .strokeBorder(dimmed ? .white.opacity(0.08) : tint.opacity(0.38), lineWidth: 1)
            )
            .overlay(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: min(8, size * 0.16), style: .continuous)
                    .stroke(.white.opacity(0.10), lineWidth: 1)
                    .padding(1)
            }
            .shadow(color: dimmed ? .clear : tint.opacity(0.18), radius: 10, y: 4)
    }
}
