import Foundation

/// "$4.00" → "$1.24M" → "$180B" style abbreviation.
func money(_ value: Double) -> String {
    let units: [(Double, String)] = [
        (1e18, "Qi"), (1e15, "Qa"), (1e12, "T"), (1e9, "B"), (1e6, "M"), (1e3, "K"),
    ]
    for (scale, suffix) in units where abs(value) >= scale {
        return "$\(sigFigs(value / scale))\(suffix)"
    }
    return String(format: "$%.2f", value)
}

private func sigFigs(_ v: Double) -> String {
    if v >= 100 { return String(format: "%.0f", v) }
    if v >= 10 { return String(format: "%.1f", v) }
    return String(format: "%.2f", v)
}

/// Compact follower-style count for units owned: 27 → "2.7K followers" flavor.
func followerCount(_ units: Int) -> String {
    let followers = Double(units) * 400 // each fake post buys ~400 fake followers
    if followers >= 1e6 { return String(format: "%.1fM", followers / 1e6) }
    if followers >= 1e3 { return String(format: "%.1fK", followers / 1e3) }
    return String(format: "%.0f", followers)
}
