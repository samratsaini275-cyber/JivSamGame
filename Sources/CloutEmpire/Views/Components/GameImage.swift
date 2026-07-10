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

/// Soft squircle icon tile — a gentle tinted well, no frame.
struct GameIconTile: View {
    let name: String
    var size: CGFloat = 50
    var dimmed: Bool = false
    var tint: Color = .white

    var body: some View {
        GameImage(name: name, size: size * 0.74, dimmed: dimmed)
            .frame(width: size, height: size)
            .background(
                RoundedRectangle(cornerRadius: size * 0.30, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                tint.opacity(dimmed ? 0.08 : 0.24),
                                Theme.ink.opacity(0.50),
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            )
            .shadow(color: .black.opacity(0.30), radius: 8, y: 5)
    }
}
