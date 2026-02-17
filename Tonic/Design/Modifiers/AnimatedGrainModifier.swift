import SwiftUI

struct AnimatedGrainModifier: ViewModifier {
    let isActive: Bool
    var intensity: CGFloat = 0.06

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var shouldAnimate: Bool {
        isActive && !reduceMotion
    }

    func body(content: Content) -> some View {
        if shouldAnimate {
            TimelineView(.periodic(from: .now, by: 1.0 / 15.0)) { timeline in
                let elapsed = timeline.date.timeIntervalSinceReferenceDate
                content
                    .colorEffect(
                        ShaderLibrary.animatedGrainEffect(
                            .float(Float(intensity)),
                            .float(Float(elapsed))
                        )
                    )
            }
        } else {
            content
        }
    }
}

extension View {
    func animatedGrain(isActive: Bool, intensity: CGFloat = 0.06) -> some View {
        modifier(AnimatedGrainModifier(isActive: isActive, intensity: intensity))
    }
}
