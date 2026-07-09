import SwiftUI

/// Rolling money counter: SwiftUI interpolates `value` through Animatable,
/// so the text re-renders every frame of the ease instead of jumping.
struct AnimatedMoney: View, Animatable {
    var value: Double

    var animatableData: Double {
        get { value }
        set { value = newValue }
    }

    var body: some View {
        Text(money(value))
            .monospacedDigit()
            .lineLimit(1)
            .minimumScaleFactor(0.5)
    }
}

extension View {
    /// Attach next to the value that drives an AnimatedMoney to make it roll.
    func rolls(with value: Double) -> some View {
        animation(.easeOut(duration: 0.35), value: value)
    }
}
