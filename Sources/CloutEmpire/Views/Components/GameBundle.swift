import Foundation

/// Resolves the SPM resource bundle for game PNG assets.
enum GameBundle {
    static let assets: Bundle = {
        let candidates: [Bundle] = {
            var list: [Bundle] = [Bundle.module]
            if let exe = Bundle.main.executableURL {
                let adjacent = exe
                    .deletingLastPathComponent()
                    .appendingPathComponent("CloutEmpire_CloutEmpire.bundle")
                if let bundle = Bundle(path: adjacent.path) {
                    list.append(bundle)
                }
            }
            return list
        }()

        for bundle in candidates where bundle.hasAsset(named: "hustle_0") {
            return bundle
        }
        return Bundle.module
    }()

    static func pngURL(named name: String) -> URL? {
        for bundle in [assets, Bundle.module] {
            if let url = bundle.pngURL(named: name) {
                return url
            }
        }
        return nil
    }
}

private extension Bundle {
    func hasAsset(named name: String) -> Bool {
        pngURL(named: name) != nil
    }

    func pngURL(named name: String) -> URL? {
        if let url = url(forResource: name, withExtension: "png") {
            return url
        }
        if let url = url(forResource: "Images/\(name)", withExtension: "png") {
            return url
        }
        return nil
    }
}
